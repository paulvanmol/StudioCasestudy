#!/usr/bin/env python3
"""
encode-changer.py - Convert SAS programs to UTF-8 with reliable encoding detection.

Detection order (deterministic, most reliable first):
  1. Empty file                      -> copied as-is
  2. BOM (UTF-8 / UTF-16)            -> certain
  3. Pure ASCII                      -> already valid UTF-8, copied as-is
  4. Strict UTF-8 decode succeeds    -> UTF-8 (also repairs double-encoded "Ã©" mojibake)
  5. Mixed UTF-8 + legacy lines      -> decoded line by line
  6. Legacy single-byte candidates   -> scored on plausible text, best wins
  chardet is only used as a reported second opinion, never as the decision maker.

Files are decoded STRICTLY (no errors="replace"), line endings are preserved, and
anything uncertain is flagged REVIEW in the audit CSV.
"""
import argparse
import codecs
import csv
import shutil
import unicodedata
from pathlib import Path

try:
    import chardet  # optional second opinion
except ImportError:
    chardet = None

DEFAULT_SOURCE = "/home/student/StudioCasestudy/changeencoding/old"
DEFAULT_OUTPUT = "/home/student/StudioCasestudy/changeencoding/new"

# Legacy encodings to try, in order of preference (first wins a tie).
# cp1252 = SAS WLATIN1, iso-8859-15 = LATIN9, cp1250 = WLATIN2 (Central Europe).
DEFAULT_LEGACY = ["cp1252", "iso-8859-15", "cp1250"]

SAS_NAMES = {
    "ascii": "us-ascii", "utf-8": "utf-8", "utf-8-sig": "utf-8 (BOM)",
    "utf-16": "utf-16", "cp1252": "wlatin1", "iso-8859-1": "latin1",
    "iso-8859-15": "latin9", "cp1250": "wlatin2", "mixed": "mixed",
}

# Non-ASCII punctuation that genuinely occurs in SAS code/comments
GOOD_PUNCT = set("€£°±µ§«»‘’“”–—…•·×÷²³¼½¾¿¡")
REVIEW_MARGIN = 0.15   # relative score gap below which we ask for a human check


def score_text(text):
    """Higher = more plausible human text. Penalises control chars and odd symbols."""
    score = 0.0
    for i, ch in enumerate(text):
        if ord(ch) < 128:
            continue
        cat = unicodedata.category(ch)
        if cat.startswith("L"):
            prev_ = text[i - 1] if i > 0 else " "
            next_ = text[i + 1] if i + 1 < len(text) else " "
            # accented letters normally sit inside words
            score += 2 if (prev_.isalpha() or next_.isalpha()) else 0.5
            # uppercase accented letter between lowercase letters is suspicious
            if ch.isupper() and prev_.islower():
                score -= 2
        elif ch in GOOD_PUNCT:
            score += 1
        elif cat in ("Cc", "Cf", "Co", "Cn"):
            score -= 5
        else:
            score -= 1
    return score


def fix_mojibake(text):
    """Repair UTF-8 that was decoded as cp1252 and saved again (Ã© -> é)."""
    if not any(m in text for m in ("Ã", "Â", "â€")):
        return text, False
    try:
        repaired = text.encode("cp1252").decode("utf-8")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return text, False
    return (repaired, True) if score_text(repaired) > score_text(text) else (text, False)


def decode_legacy(raw, candidates):
    """Return (text, encoding, note) for the best-scoring legacy encoding."""
    results = []
    for enc in candidates:
        try:
            text = raw.decode(enc)  # strict
        except UnicodeDecodeError:
            continue
        results.append((score_text(text), enc, text))
    if not results:  # latin-1 can decode any byte, last resort
        return raw.decode("iso-8859-1"), "iso-8859-1", "REVIEW: no candidate decoded strictly"
    # stable sort keeps preference order on ties
    results.sort(key=lambda r: r[0], reverse=True)
    best = results[0]
    note = ""
    if len(results) > 1 and results[1][2] != best[2]:
        gap = best[0] - results[1][0]
        if gap <= abs(best[0]) * REVIEW_MARGIN:
            note = f"REVIEW: close call vs {results[1][1]}"
    return best[2], best[1], note


def decode_mixed(raw, candidates):
    """Decode line by line: UTF-8 where valid, otherwise best legacy encoding."""
    out, legacy_lines = [], 0
    for line in raw.splitlines(keepends=True):
        try:
            out.append(line.decode("utf-8"))
        except UnicodeDecodeError:
            text, _, _ = decode_legacy(line, candidates)
            out.append(text)
            legacy_lines += 1
    return "".join(out), legacy_lines


def detect_and_decode(raw, candidates):
    """Return (text, encoding, method, note). text=None means copy unchanged."""
    if not raw:
        return None, "empty", "empty", ""
    if raw.startswith(codecs.BOM_UTF8):
        return raw[3:].decode("utf-8"), "utf-8-sig", "bom", ""
    if raw.startswith((codecs.BOM_UTF16_LE, codecs.BOM_UTF16_BE)):
        return raw.decode("utf-16"), "utf-16", "bom", ""
    if raw.isascii():
        return None, "ascii", "ascii", ""
    try:
        text = raw.decode("utf-8")
        text, repaired = fix_mojibake(text)
        if repaired:
            return text, "utf-8", "utf8-strict", "FIXED: double-encoded UTF-8 repaired"
        return None, "utf-8", "utf8-strict", ""
    except UnicodeDecodeError:
        pass
    # does it contain at least some valid multi-byte UTF-8? then probably mixed
    utf8_lines = sum(1 for l in raw.splitlines()
                     if not l.isascii() and _is_utf8(l))
    if utf8_lines:
        text, legacy_lines = decode_mixed(raw, candidates)
        return text, "mixed", "line-by-line", (
            f"REVIEW: {utf8_lines} UTF-8 + {legacy_lines} legacy lines")
    text, enc, note = decode_legacy(raw, candidates)
    return text, enc, "legacy-scored", note


def _is_utf8(b):
    try:
        b.decode("utf-8")
        return True
    except UnicodeDecodeError:
        return False


def chardet_opinion(raw):
    if chardet is None or not raw:
        return "", ""
    r = chardet.detect(raw)
    return r.get("encoding") or "", round(r.get("confidence") or 0, 2)


def non_ascii_sample(text, limit=60):
    """First line containing non-ASCII characters, for quick visual review."""
    for n, line in enumerate(text.splitlines(), 1):
        if not line.isascii():
            return f"L{n}: {line.strip()[:limit]}"
    return ""


def process(src, dst, args):
    raw = src.read_bytes()
    forced = args.override.get(src.name)
    if forced:
        text, enc, method, note = raw.decode(forced), forced, "override", ""
    else:
        text, enc, method, note = detect_and_decode(raw, args.legacy)

    if not args.dry_run:
        dst.parent.mkdir(parents=True, exist_ok=True)
        if text is None:
            shutil.copy2(src, dst)               # already UTF-8/ASCII: byte-identical
        else:
            # newline="" preserves original CRLF/LF line endings
            with open(dst, "w", encoding="utf-8", newline="") as f:
                f.write(text)
            # verification: output must be valid UTF-8 and round-trip
            assert dst.read_bytes().decode("utf-8") == text

    action = "UNCHANGED" if text is None else "CONVERTED"
    status = note.split(":")[0] if note else "OK"
    sample = non_ascii_sample(text if text is not None else raw.decode("utf-8", "replace"))
    cd_enc, cd_conf = chardet_opinion(raw)
    return [enc, SAS_NAMES.get(enc, enc), method, action, status, note, cd_enc, cd_conf, sample]


def parse_args():
    p = argparse.ArgumentParser(description="Convert SAS programs to UTF-8.")
    p.add_argument("--source", default=DEFAULT_SOURCE)
    p.add_argument("--output", default=DEFAULT_OUTPUT)
    p.add_argument("--ext", nargs="+", default=[".sas"],
                   help="File extensions to process, e.g. --ext .sas .csv")
    p.add_argument("--legacy", nargs="+", default=DEFAULT_LEGACY,
                   help="Legacy encodings to try, in order of preference")
    p.add_argument("--override", nargs="*", default=[], metavar="FILE=ENC",
                   help="Force an encoding, e.g. --override adsl.sas=cp1250")
    p.add_argument("--dry-run", action="store_true", help="Only write the audit report")
    a = p.parse_args()
    a.override = dict(o.split("=", 1) for o in a.override)
    a.ext = {e.lower() if e.startswith(".") else "." + e.lower() for e in a.ext}
    return a


def main():
    args = parse_args()
    source, output = Path(args.source), Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    audit_file = output / "conversion_audit.csv"
    counts = {}

    with open(audit_file, "w", newline="", encoding="utf-8") as audit:
        w = csv.writer(audit)
        w.writerow(["File", "DetectedEncoding", "SASEncoding", "Method", "Action",
                    "Status", "Note", "ChardetGuess", "ChardetConfidence", "NonAsciiSample"])
        for src in sorted(source.rglob("*")):
            if not src.is_file() or src.suffix.lower() not in args.ext:
                continue
            rel = src.relative_to(source)
            try:
                row = process(src, output / rel, args)
            except Exception as ex:
                row = ["", "", "", "FAILED", "FAILED", str(ex), "", "", ""]
            w.writerow([rel.as_posix()] + row)
            counts[row[4]] = counts.get(row[4], 0) + 1
            print(f"{row[4]:7} {row[3]:9} {row[0]:11} {rel}  {row[5]}")

    print(f"\nSummary: {counts}\nAudit:   {audit_file}")
    if counts.get("REVIEW") or counts.get("FAILED"):
        print("Check the REVIEW/FAILED rows; use --override FILE=ENC where needed.")


if __name__ == "__main__":
    main()
