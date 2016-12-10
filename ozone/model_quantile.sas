/*
Script for fitting regression model 
Last update:		March.20.2016 
March.20.2016	Code cleaned
March.01.2016 	Code Verified
*/

* Initializing data and lib location;
** Data in lib is cleaned by script data_cleaning.sas;

%let dirname=C:\Users\ziwei\Dropbox\AsthmaOzone\mycode;

libname no2 "&dirname\lib\no2\";
libname ozone "&dirname\lib\ozone\";
libname model "&dirname\lib\model\";
%let no2_dirname=&dirname\data\no2\;
%let o3_dirname=&dirname\ozone_aqi\;
%let output_dirname=&dirname\output\;



/* Quantile Regression model */;

** Data pre-treatment;
** Month of interests: 3,9,10,11;
** Variable of interests: bp(barometric pressure), sr(solar radiation) ,ws(wind speed);
data data_lag;
	set model.data;
	where (month in (3,9,10,11));
	avg_bp_lag = lag1(avg_bp);
	avg_sr_lag = lag1(avg_sr);
	avg_ws_lag = lag1(avg_ws);
	weekday=weekday(date);  *extract weeday info from sas format date;
	if weekday(date)=6 or weekday(date)=7 then workday=0;
	else workday=1; *Generalize weekdays to workdays, for comparison;
	run;

/* Model Fitting; */
** Quantile is decided by a scanning method (from 5th to 95th) see;
proc quantreg data=data_lag ci=resampling outest=model_no2;
	class weekday;
	model no2_daily_mean = beforeno2 weekday avg_ws/quantile= 0.85;
	output out=out_no2 p=p_no2;
run;

proc quantselect data=data_lag;
	class workday;
	class weekday;
	model no2_daily_mean = beforeno2 avg_ws weekday
		/quantile=0.85
		selection=NONE;
	run;

/* back transform if box-cox transformation is applied
data out_no2;
	set out_no2;
	p_no2=p_no2**2;
	run;
/*

/*
proc robustreg data=data_lag;
	class weekday;
	model no2_daily_mean = beforeno2 avg_ws weekday;
	output out=out_no2 p=p_no2;
	run;
*/

proc quantreg data=data_lag ci=resampling outest=model_ozone;
	model ozone3 = beforeno2 beforeo3 avg_ws/quantile=0.65;
	output out=out_ozone p=p_ozone;
run;


proc quantselect data=data_lag;
	class workday;
	class weekday;
	model ozone3 = beforeno2 beforeo3 avg_ws
		/quantile=0.65
		selection=NONE;
	run;


/*
proc robustreg data=data_lag;
	class weekday;
	model ozone3 = beforeo3 avg_ws weekday;
	output out=out_ozone p=p_ozone;
	run;
*/
* Adjust results;



/*
proc reg data=data_lag;
	*class weekday;
	model Ozone_mean = beforeo3 beforeno2 avg_ws;
	output out=out_ozone p=p_ozone;
	run;
*/

data model.quantile_output;
	merge out_no2 out_ozone;
	by date;
	if p_no2 > 18 and p_ozone > 43 then hrd_predict=1;
		else hrd_predict=0;
	run;
	
/* Script for output;
proc export data=model.quantile_output outfile="&output_dirname.output.csv";
run;
*/ 

/* basic summary */
data model.quantile_summary;
	set model.quantile_output;
	if maxAQI>100 then highAQI=1;
		else highAQI=0;
	run;
data model.quantile_summary;
	set model.quantile_summary;
	length predict $15;
	if hrd_predict=1 and hrd=1 then predict = "CorrectHRD";
	if hrd_predict=0 and hrd=1 then predict = "False Negative";
	if hrd_predict=1 and hrd=0 then predict = "False Positive";
	if hrd_predict=0 and hrd=0 then predict = "CorrectLRD";

	if hrd_predict=1 and hrd=1 then marker = "H";
	if hrd_predict=0 and hrd=1 then marker = "N";
	if hrd_predict=1 and hrd=0 then marker = "P";
	if hrd_predict=0 and hrd=0 then marker = "L";
	run;
	
proc freq data=model.quantile_summary;
table predict/nopercent nocum; 
run;

** Create color coded false positive and false negative plot;
 ods graphics / reset attrpriority=none;

proc sgplot data=model.quantile_summary dattrmap=myattrmap;
	styleattrs	datacontrastcolors=(green red black blue)
				datasymbols=(Circle CircleFilled starfilled CircleFilled);
	refline 18 / axis=X;
	refline 43 / axis=Y;
	title 'Actual';
	scatter x=no2_daily_mean y=ozone3 /group=predict markerattrs=(size=5);
	yaxis label="Ozone 3 day accumulated (Actual)";
	xaxis label="NO2 day mean (Actual)";
	run;


proc sgplot data=model.quantile_summary;
	styleattrs	datacontrastcolors=(green red black blue)
				datasymbols=(Circle CircleFilled starfilled CircleFilled);
	refline 18 / axis=X;
	refline 43 / axis=Y;
	title 'Prediction';
	scatter x=p_no2 y=p_ozone /group=predict markerattrs=(size=5);
	yaxis label="Ozone 3 day accumulated (Predicted)";
	xaxis label="NO2 day mean (Predicted)";
	run;
	

/*	
proc timeseries data=model.data plots=all;
	var avg_ws;
	run;
*/	


/*
* Plot for prediction assessment;
proc means data=model.quantile_output p75;
	var no2_daily_mean ozone3;
	output out=quantile_con p75(no2_daily_mean)=q3_no2_daily_mean
							p75(ozone3)=q3_ozone3;
	run;
data quantile_con;
	set quantile_con;
	rep=1;
	run;
data model.quantile_output;
	set model.quantile_output;
	rep=1;
	run;
data residual_analysis;	
	merge model.quantile_output quantile_con;
	by rep;
	run;

data residual_analysis;
	set residual_analysis;
	d_no2 = ( p_no2 - no2_daily_mean ) / (no2_daily_mean**2) ;
	d_ozone = ( p_ozone - ozone3 ) / (ozone3**2);
	
	SR_no2 = ( p_no2- q3_no2_daily_mean )**2;
	SR_ozone = ( p_ozone- q3_ozone3 )**2;
	SE_no2 = p_no2-no2_daily_mean;
	SE_ozone = p_ozone-ozone3;
	
	run;
	
proc means data=residual_analysis sum noprint;
	var SR_no2 SR_ozone SE_no2 SE_ozone;
	output out=residual_analysis_R_squared	sum(SR_no2)=SSR_no2
											sum(SR_ozone)=SSR_ozone
											sum(SE_no2)=SSE_no2
											sum(SE_ozone)=SSE_ozone;
	run;

data residual_analysis_R_squared;
	set residual_analysis_R_squared;
	R_adjusted_no2 = 1-(SSR_no2/_FREQ_) / ( (SSE_no2+SSR_no2)/_FREQ_ );
	R_adjusted_ozone = 1-(SSR_ozone/_FREQ_) / ( (SSE_ozone+SSR_ozone)/_FREQ_ );
	run;
proc print data=residual_analysis_R_squared;
	var R_adjusted_no2 R_adjusted_ozone _FREQ_;
run;


proc means data=residual_analysis_sum sum;
	var residual_no2 residual_ozone residual_no2_squared residual_ozone_squared;
	output out=residual_analysis sum=;
	run;
	
data quantile_plot;
	merge residual_mean quantile_plot;
	run;	
proc sgplot data=quantile_plot;
	scatter x=ozone3 y=residual_ozone_squared /markerattrs=(size=5);
	xaxis label="Ozone 3 day accumulated (Actual)";
	lineparm x=0 y=mean_residual_ozone slope=0 / legendlabel="Mean Residual";
	title "Residual Plot";

	run;





proc sgplot data=quantile_plot;
	scatter x=no2_daily_mean y=residual_no2_squared /markerattrs=(size=5);
	xaxis label="NO2 day mean (Actual)";
	lineparm x=0 y=mean_residual_no2 slope=0 / legendlabel="Mean Residual" ;
	title "Residual Plot";
	run;

	
proc sgplot data=quantile_plot;
	where d_no2<10 and d_no2>-10;
	scatter x=d_no2 y=d_ozone / markerattrs=(size=5);
	xaxis label="(predicted no2 - actual no2) / (actual no2)^2";
	yaxis label="(predicted O3 - actual O3) / (actual O3)^2";
	title "Residual Plot";
	run;





	

/* Variable Selection */
/* Automatic */
/*
proc glmselect data=data_lag plots=all;
	class weekday;
	model no2_daily_mean = beforeno2 beforeo3 avg_sr_lag avg_ws avg_ws_lag avg_bp_lag weekday/ selection=forward;
	run;
	
proc glmselect data=data_lag plots=all;
	class weekday;
	model ozone3 = beforeno2 beforeo3 avg_sr_lag avg_ws avg_ws_lag avg_bp_lag weekday / selection=forward;
	run;
	
** Mannual for no2 ;
%macro modelsel(Var);

	ods exclude all;
	proc quantreg data=data_lag ci=resampling outest=model_no2 ;
		class weekday;
		model no2_daily_mean = &Var/quantile= 0.75;
		output out=out_no2_sel p=p_no2;
	run;

	data quantile_output_sel;
		merge out_no2_sel out_ozone;
		by date;
		if p_no2 > 18 and p_ozone > 43 then hrd_predict=1;
			else hrd_predict=0;
	run;
	
	data quantile_output_sel;
		set quantile_output_sel;
		length predict $15;
		if hrd_predict=1 and hrd=1 then predict = "CorrectHRD";
		if hrd_predict=0 and hrd=1 then predict = "False Negative";
		if hrd_predict=1 and hrd=0 then predict = "False Positive";
		if hrd_predict=0 and hrd=0 then predict = "CorrectLRD";
	run;
	
	ods exclude none;
	proc freq data=quantile_output_sel ;
		table predict/nopercent nocum out=select;
		title "&Var";
	run;

%mend;

%modelsel(beforeno2);
%modelsel(beforeno2 weekday);
%modelsel(beforeno2 weekday avg_ws);
%modelsel(beforeno2 weekday avg_ws avg_sr_lag);
%modelsel(beforeno2 weekday avg_ws avg_sr_lag avg_ws_lag);
%modelsel(beforeno2 weekday avg_ws avg_sr_lag avg_ws_lag beforeo3);
%modelsel(beforeno2 weekday avg_ws avg_sr_lag avg_ws_lag beforeo3 avg_bp_lag);

proc transreg data=data_lag;
	model BoxCox(no2_daily_mean) = identity(beforeno2 weekday avg_ws avg_sr_lag);
	run;


*/


