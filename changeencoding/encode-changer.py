import os
import csv
import shutil
from pathlib import Path

try:
    import chardet
except ImportError:
    print("Install dependency: pip install chardet")
    raise


SOURCE_DIR = r"C:\encoding\old"
OUTPUT_DIR = r"C:\encoding\new"
AUDIT_FILE = os.path.join(OUTPUT_DIR, "conversion_audit.csv")


def detect_encoding(file_path):
    with open(file_path, "rb") as f:
        raw = f.read()

    result = chardet.detect(raw)

    return (
        result.get("encoding", "unknown"),
        result.get("confidence", 0)
    )


def convert_to_utf8(src_file, dst_file):
    encoding, confidence = detect_encoding(src_file)

    try:
        with open(src_file, "r", encoding=encoding, errors="replace") as f:
            content = f.read()

        with open(dst_file, "w", encoding="utf-8") as f:
            f.write(content)

        status = "SUCCESS"

    except Exception as ex:
        status = f"FAILED: {ex}"

    return encoding, confidence, status


def main():

    Path(OUTPUT_DIR).mkdir(parents=True, exist_ok=True)

    with open(AUDIT_FILE, "w", newline="", encoding="utf-8") as audit:

        writer = csv.writer(audit)

        writer.writerow([
            "File",
            "DetectedEncoding",
            "Confidence",
            "Status"
        ])

        for root, dirs, files in os.walk(SOURCE_DIR):

            for filename in files:

                if not filename.lower().endswith(".sas"):
                    continue

                src_file = os.path.join(root, filename)

                relative = os.path.relpath(src_file, SOURCE_DIR)

                dst_file = os.path.join(
                    OUTPUT_DIR,
                    relative
                )

                Path(os.path.dirname(dst_file)).mkdir(
                    parents=True,
                    exist_ok=True
                )

                enc, conf, status = convert_to_utf8(
                    src_file,
                    dst_file
                )

                writer.writerow([
                    relative,
                    enc,
                    round(conf, 3),
                    status
                ])

                print(
                    f"{relative} | "
                    f"{enc} ({conf:.2f}) | "
                    f"{status}"
                )


if __name__ == "__main__":
    main()