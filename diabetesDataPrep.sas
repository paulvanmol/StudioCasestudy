/* Import Diabetes.csv and create work.DiabetesTemp */
proc import file="/home/student/quick-start/Diabetes.csv" 
            dbms=csv 
            out=work.DiabetesTemp
            replace;
run;

/* Create Work.DiabetesFinal  */
data work.DiabetesFinal;
    set work.diabetestemp;
    Gender=upcase(gender);
    if Class="N" then Diagnosis="Non-Diabetic";
        else if Class="Y" then Diagnosis="Diabetic";
        else if Class="P" then Diagnosis="Pre-Diabetic";
    if 0 <= BMI <=18.4 then BMI_Range="Underweight";
        else if 18.5 <= BMI <=24.9 then BMI_Range ="Normal";
        else if 25 <= BMI <=29.9 then BMI_Range ="Overweight";
        else if 30 <= BMI <=50 then BMI_Range ="Obese";
    label gendeer="Gender"
          Age="Age"
          Urea="Urea"
          Cr = "Creatinine"
          HbA1c = "Glycated Hemoglobin"
          Chol = "Cholesterol"
          TG = "Triglycerides"
          HDL = "High-Density Lipoprotein"
          LDL = "Low-Density Lipoprotein"
          VLDL = "Very Low-Density Lipoprotein"
          BMI = "Body Mass Index"
          BMI_Range = "BMI Range"
          Class = "Diabetes Code"
          Diagnosis = "Diabetes Diagnosis";
run;


/* Generate frequency counts for Diagnosis  */ 
proc freq data=DiabetesFinal;
    tables Gender class Diagnosis / plots=freqplot;
run;
cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");

proc casutil;
    droptable casdata="DiabetesFinal" incaslib="casuser" quiet;
    load data=work.DiabetesFinal outcaslib="casuser" casout="DiabetesFinal" promote;
    list tables incaslib="casuser";
run;