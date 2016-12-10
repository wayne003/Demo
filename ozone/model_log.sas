/* Script for fitting regression model */
/* Latest update: Dec.11.2015 *

/* Initializing data and lib location */
/* modification for Windows Operating System
libname no2 'C:\Users\ziwei\Dropbox\AsthmaOzone\mycode\lib\no2';
libname ozone 'C:\Users\ziwei\Dropbox\AsthmaOzone\mycode\lib\ozone';
libname model 'C:\Users\ziwei\Dropbox\AsthmaOzone\mycode\lib\model';
%let no2_dirname=C:\Users\ziwei\Dropbox\AsthmaOzone\mycode\data\no2\;
%let o3_dirname=C:\Users\ziwei\Dropbox\AsthmaOzone\mycode\data\ozone_aqi\;
%let output_dirname=C:\Users\ziwei\Dropbox\AsthmaOzone\mycode\output\;
*/

/* Following Initializing is for Linux Operating System */


libname no2 '/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/lib/no2';
libname ozone '/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/lib/ozone';
libname model '/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/lib/model';
%let no2_dirname=/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/data/no2/;
%let o3_dirname=/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/data/ozone_aqi/;
%let output_dirname=/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/output/;


**logistic model test;

data data_lag;
	set model.data;
	where (month in (3,9,10,11));
	avg_bp_lag = lag1(avg_bp);
	avg_sr_lag = lag1(avg_sr);
	avg_ws_lag = lag1(avg_ws);
	weekday = weekday(date);
	if weekday(date)=6 or weekday(date)=7 then workday=0;
	else workday=1;;
	run;
	
proc logistic data=data_lag outmodel=model.logistic outest=model.logistic_est alpha=0.90;
	class weekday /PARAM=REF;
	model hrd (EVENT='1') = beforeno2 beforeo3 avg_ws avg_bp_lag weekday;*/Link=Cloglog;
	output out=out_logistic p=prob_hrd L=l_prob_hrd U=u_prob_hrd;
run;

/* If prediction is needed using the following code;

proc logistic inmodel=model.logistic;
	hrd_predict data= out=;
	run;
	
*/

data model.logistic_output;
	set out_logistic;
	if prob_hrd>0.20 then hrd_predict=1;
		else hrd_predict=0;
	run;
	

data model.logistic_summary;
	set model.logistic_output;
	length predict $15;
	if hrd_predict=1 and hrd=1 then predict = "CorrectHRD";
	if hrd_predict=0 and hrd=1 then predict = "False Negative";
	if hrd_predict=1 and hrd=0 then predict = "False Positive";
	if hrd_predict=0 and hrd=0 then predict = "CorrectLRD";

	run;
	
proc freq data=model.logistic_summary;
	table predict/nopercent nocum; 
run;

data logistic_summary;
	set model.logistic_summary;
	if predict = "False Positive" then prd=1;
	if predict = "CorrectHRD" then prd=0;
	if predict = "False Negative" then prd=-1;
run;
	
proc sgplot data=model.logistic_summary;
	where (predict in ('CorrectHRD','False Negative','False Positive'));
	vbar predict;
	run;


%macro massiveplot(month=,year=);
%do year=2004 %to 2013;
	
	%do month=3 %to 11;
	
	proc sgplot data=model.logistic_output;
		where year=&year and month=&month;
		title "Year=&year and Month=&month";
		format date date.;
		needle x=date y=hrd /lineattrs=(thickness=7 color=cxB9CFE7);
		refline 0.2 /AXIS=Y label="Probability Cut Off";
		scatter x=date y=prob_hrd / yerrorlower=l_prob_hrd yerrorupper=u_prob_hrd markerattrs=(size=5 color=black);
		series	x=date y=prob_hrd;
		band x=date lower=l_prob_hrd upper=u_prob_hrd/ fillattrs=(color=grey);
		
		scatter x=date y=ozone_mean / Y2AXIS MARKERATTRS=(COLOR=RED);
		scatter x=date y=no2_day_mean /Y2AXIS;
		REFLINE 43 /AXIS=Y2 label="Ozone Cut Off" lineattrs=(color=RED);
		REFLINE 18/AXIS=Y2 label="NO2 Cut Off" lineattrs=(color=GREEN);
		
		Xaxis type=discrete label="Date";
		Yaxis label="Probability";
		Y2axis label="Concentration";
		run;
		
	%end;
	
%end;
%mend massiveplot;

* Be careful when running this step, can take a lot time to compute, 10s for my comupter;
* %massiveplot;
	
	