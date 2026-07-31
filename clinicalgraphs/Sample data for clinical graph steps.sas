/*============================================================================*
 * Sample data generators for the three clinical-graph Custom Steps:         *
 *   1. Clinical Waterfall Graph                                             *
 *   2. Clinical Profile Graph with Discrete Axes                            *
 *   3. Clinical Grouped Bar Chart                                           *
 *                                                                            *
 * Run this whole program once; it creates three WORK tables. Each section   *
 * below lists the exact custom-step role each column is meant to fill.      *
 *============================================================================*/


/*----------------------------------------------------------------------------
 1. WORK.WATERFALL_DATA  ->  Clinical Waterfall Graph
    cidvar    = SUBJID    (char, subject ID)
    changevar = PCHG      (num,  % change from baseline in tumor size)
    groupvar  = BESTRESP  (char, single-letter response code: C R S P N)
                (matches the CR/PR/SD/PD/NE inset built into the step)
    labelvar  = TRT       (char, optional data label - treatment arm)
----------------------------------------------------------------------------*/
data waterfall_data;
    length subjid $8 trt $12 bestresp $1;
    call streaminit(20260731);
    do i = 1 to 45;
        subjid = cats('SUBJ-', put(i, z3.));
        trt = ifc(ranuni(0) < 0.5, 'Drug A', 'Placebo');

        /* skew change-from-baseline so the waterfall has a realistic shape */
        pchg = round(rand('Normal', -15, 35), 0.1);
        if pchg < -100 then pchg = -100;
        if pchg > 60 then pchg = 60;

        /* derive a RECIST-style best response from the change value */
        if pchg = -100 then bestresp = 'C';           /* CR */
        else if pchg <= -30 then bestresp = 'R';       /* PR */
        else if pchg < 20 then bestresp = 'S';         /* SD */
        else if pchg >= 20 then bestresp = 'P';        /* PD */
        if ranuni(0) < 0.05 then bestresp = 'N';        /* NE, a few missing evals */

        output;
    end;
    drop i;
run;

proc sort data=waterfall_data;
    by descending pchg;
run;


/*----------------------------------------------------------------------------
 2. WORK.PROFILE_DATA  ->  Clinical Profile Graph with Discrete Axes
    groupvar  = TRTGRP   (char, treatment group)
    dayvar    = VISIT    (char, discrete visit label, in visit order)
    medianvar = MEDIAN   (num,  median lipid value)
    lclvar    = LCL      (num,  lower 95% confidence limit)
    uclvar    = UCL      (num,  upper 95% confidence limit)
----------------------------------------------------------------------------*/
data profile_data;
    length trtgrp $12 visit $10;
    call streaminit(20260731);
    array visits[5] $10 _temporary_ ('Day 0' 'Day 30' 'Day 60' 'Day 90' 'Day 120');
    array trts[3] $12 _temporary_ ('Placebo' 'Drug 100mg' 'Drug 200mg');
    array trend[3] _temporary_ (0 -8 -18);   /* overall LDL drift by treatment */

    do t = 1 to 3;
        trtgrp = trts[t];
        do v = 1 to 5;
            visit = visits[v];
            median = round(130 + trend[t]*(v-1)/4 + rand('Normal', 0, 3), 0.1);
            lcl = round(median - (8 + rand('Uniform', 0, 3)), 0.1);
            ucl = round(median + (8 + rand('Uniform', 0, 3)), 0.1);
            output;
        end;
    end;
    drop t v;
run;


/*----------------------------------------------------------------------------
 3. WORK.INJECTION_DATA  ->  Clinical Grouped Bar Chart
    timevar  = VISIT     (char, discrete time/visit label)
    respvar  = INCIDENCE (num,  % incidence of the reaction)
    groupvar = COHORT    (char, dosing cohort)
----------------------------------------------------------------------------*/
data injection_data;
    length cohort $12 visit $10;
    call streaminit(20260731);
    array visits[4] $10 _temporary_ ('Day 1' 'Day 3' 'Day 7' 'Day 14');
    array cohorts[3] $12 _temporary_ ('Placebo' 'Low Dose' 'High Dose');
    array basefreq[3] _temporary_ (5 22 38);   /* starting incidence by cohort */

    do c = 1 to 3;
        cohort = cohorts[c];
        do v = 1 to 4;
            visit = visits[v];
            /* incidence tapers off over time, higher for higher dose */
            incidence = round(max(0, basefreq[c] - (v-1)*basefreq[c]/5 + rand('Normal', 0, 2)), 0.1);
            output;
        end;
    end;
    drop c v;
run;


/* quick visual check - optional */
proc print data=waterfall_data(obs=10); run;
proc print data=profile_data; run;
proc print data=injection_data; run;
