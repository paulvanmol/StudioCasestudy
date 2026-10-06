/* Same graphs without custom steps - quick regression test after load_sample_data.sas */
ods graphics on;
proc lifetest data=cgdata.adtte plots=survival(atrisk(outside)=0 to 720 by 90 test) notable;
  time aval*cnsr(1); strata trt01p / test=logrank; run;
proc sgplot data=cgdata.adlb_edish;
  scatter x=altuln y=biliuln / group=trt01p;
  refline 3 / axis=x; refline 2 / axis=y;
  xaxis type=log; yaxis type=log; run;
