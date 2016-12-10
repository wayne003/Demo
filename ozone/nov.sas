		libname no2 '/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/lib/no2';
libname ozone '/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/lib/ozone';
libname model '/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/lib/model';
libname predict '/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/lib/predict';

*sep oct;
data predict.no2_raw;
	infile "/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/data/2015/2015 No2 Data Extraction.csv" dlm=',' firstobs=2;
	input date yymmdd8. Time $ C1 C8 C15 C26 C35 C45 C53 C78 C84 C403 C408 C411 C416 C603 C617 C618 C619 C620 C1015 C1016 C1034 C1052 C1066;
	/*
	array C (23) C1 C8 C15 C26 C35 C45 C53 C78 C84 C403 C408 C411 C416 C603 C617 C618 C619 C620 C1015 C1016 C1034 C1052 C1066;
	
	DO i=1 to 23;
		if C(i)<0 then C(i)=0;
	END;
	*/
run;

data predict.no2;
	set predict.no2_raw;
	keep date Time C1 C8 C15 C26 C35 C45 C53 C84 C403 C408 C416 C603 C617;
	run;


* Date calculation;
data predict.no2;
	set predict.no2;
	Year = year(date);
	Month = month(date);
	Day = day(date);
	weekday = weekday(date);
	run;
	
data predict.no2;
	set predict.no2;
	where (month in (3,9,10,11));
	run;
	
data predict.no2;
	set predict.no2;
	hour = input(time,time5.);
	run;
	

proc means data=predict.no2 mean noprint ;
	var C1 C8 C15 C26 C35 C45 C53 C84 C403 C408 C416 C603 C617;
	class date;
	output out=predict.no2mean(drop=_type_ _freq_) mean=;
run;

data predict.no2_daily_mean;
	set predict.no2mean;
	if date=. then delete;
	no2_daily_mean = mean (of C:);
	run;
	
data predict.no2_daily_mean;
	set predict.no2_daily_mean;
	keep date no2_daily_mean;
	run;



*9PM-2AM NO2;
*lag all data 3 position to get right time interval;
*21 22 23 0 1 2 -> 0 1 2 3 4 5;


data predict.no2_9am2pm;
	set predict.no2;
	* Calculate average for 9pm to 2am;
	*hr: 21 22 23 0 1 2 -> 0 1 2 3 4 5;
	array no2_C (13) C1 C8 C15 C26 C35 C45 C53 C84 C403 C408 C416 C603 C617;
	DO i=1 to 13;
		if month ~= 11 then
			no2_C(i)= lag4(no2_C(i)); * 9-2+DST adjusting, DST end at Nov, lag one more;
		else
			no2_C(i)= lag3(no2_C(i));
	END;
	*Different DST start date is not considered. Start from March 1st for every year;
run;


proc means data=predict.no2_9am2pm(where=(hour in (0,1,2,3,4,5))) mean noprint;
	var C1 C8 C15 C26 C35 C45 C53 C84 C403 C408 C416 C603 C617;
	class date;
	output out=predict.no2_before(drop=_type_ _freq_) mean=beforeno2;
run;

* merge 9-2 and day mean data;

data predict.no2_data;
	merge predict.no2_before predict.no2_daily_mean;
	by date;
	if date=. then delete;
	run;


** Ozone;
data predict.ozone_raw;
	infile "/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/data/2015/2015 Ozone Data Extraction.csv" dlm=',' firstobs=2;
	input date yymmdd8. Time $ C1 C8 C15 C26 C35 C45 C53 C78 C84 C403 C405 C406 C408 C409 C410 C411 C416 C551 C552 C553 C554 C556 C557 C558 C559 C560 C561 C562 C563 C570 C571 C572 C603 C617 C618 C619 C620 C695 C696 C697 C698 C699 C1015 C1016 C1017 C1034;
	time = input(time,time10.);
	run;

data predict.ozone;
	set predict.ozone_raw;
	keep date Time C1 C8 C15 C26 C35 C45 C53 C81 C84 C403 C405 C406 C408 C409 C410 C411 C416 C551 C552 C553 C554 C555 C556 C557 C558 C559 C560 C561 C562 C570 C570 C571 C572 C603 C695 C696;
	run;
	
data predict.ozone;
	set predict.ozone;
	Year = year(date);
	Month = month(date);
	Day = day(date);
	weekday = weekday(date);
	run;
	


* 8hr Maximum programmed by: Laura Campos;
************************************************;
ods graphics off;

proc sort data = predict.ozone;
by  Date Time;
run;

proc transpose data = predict.ozone
out = hour_trans
prefix = con;
by Date Time;
run;
data hour1;
set hour_trans;
mon = _NAME_;
con = con1;
keep Date Time mon con;
run;

%macro eighthourmax(indata=, mon=);
*sort and get average;
data sub_&mon;
set &indata;
where mon = "&mon";
run;
*sort and get moving average;
proc sort data = sub_&mon;
	 by Date Time;
 run;
proc expand  data = sub_&mon out = ave_&mon  method = None;
	 CONVERT con = ave_&mon / TRANSFORM = ( MOVAVE 8 );
	 by Date;
 run;
 *choose the max;
proc means data = ave_&mon n max noprint;
	 class Date;
	 var ave_&mon;
	 output out = max_8hr_&mon (drop = _type_ _freq_) 
	 n = n_obs
	 max = max_&mon ;
run;
*get rid of first row;
data  max_8hr_&mon;
set max_8hr_&mon;
where n_obs < 26;
run;
*get two lags;
data max_8hr_lag_&mon;
set max_8hr_&mon;
max_8hr_L1 = lag1(max_&mon);
max_8hr_L2 = lag2(max_&mon);
max_8hr_lagmean_&mon = mean(max_&mon,max_8hr_L1,max_8hr_L2);
run; 
*shorten for later merging;
data O3_&mon;
set max_8hr_lag_&mon;
keep Date max_8hr_lagmean_&mon;
run;
%mend eighthourmax;

%eighthourmax(indata = hour1, mon = C1);
%eighthourmax(indata = hour1, mon = C8);
%eighthourmax(indata = hour1, mon = C15);
%eighthourmax(indata = hour1, mon = C26);
%eighthourmax(indata = hour1, mon = C35);
%eighthourmax(indata = hour1, mon = C45);
%eighthourmax(indata = hour1, mon = C53);
%eighthourmax(indata = hour1, mon = C81);
%eighthourmax(indata = hour1, mon = C84);
%eighthourmax(indata = hour1, mon = C403);
%eighthourmax(indata = hour1, mon = C405);
%eighthourmax(indata = hour1, mon = C406);
%eighthourmax(indata = hour1, mon = C408);
%eighthourmax(indata = hour1, mon = C409);
%eighthourmax(indata = hour1, mon = C410);
%eighthourmax(indata = hour1, mon = C411);
%eighthourmax(indata = hour1, mon = C416);
%eighthourmax(indata = hour1, mon = C551);
%eighthourmax(indata = hour1, mon = C552);
%eighthourmax(indata = hour1, mon = C553);
%eighthourmax(indata = hour1, mon = C554);
%eighthourmax(indata = hour1, mon = C555);
%eighthourmax(indata = hour1, mon = C556);
%eighthourmax(indata = hour1, mon = C557);
%eighthourmax(indata = hour1, mon = C558);
%eighthourmax(indata = hour1, mon = C559);
%eighthourmax(indata = hour1, mon = C560);
%eighthourmax(indata = hour1, mon = C561);
%eighthourmax(indata = hour1, mon = C562);
%eighthourmax(indata = hour1, mon = C570);
%eighthourmax(indata = hour1, mon = C571);
%eighthourmax(indata = hour1, mon = C572);
%eighthourmax(indata = hour1, mon = C603);
%eighthourmax(indata = hour1, mon = C695);
%eighthourmax(indata = hour1, mon = C696);

*mergin only 8hr max (no lags);

*THIS;
%macro sort (data=);
proc sort data = &data;
by Date;
run;
%mend sort;

%sort(data = max_8hr_C1);
%sort(data = max_8hr_C8);
%sort(data = max_8hr_C15);
%sort(data = max_8hr_C26);
%sort(data = max_8hr_C35);
%sort(data = max_8hr_C45);
%sort(data = max_8hr_C53);
%sort(data = max_8hr_C81);
%sort(data = max_8hr_C84);
%sort(data = max_8hr_C403);
%sort(data = max_8hr_C405);
%sort(data = max_8hr_C406);
%sort(data = max_8hr_C408);
%sort(data = max_8hr_C409);
%sort(data = max_8hr_C410);
%sort(data = max_8hr_C411);
%sort(data = max_8hr_C416);
%sort(data = max_8hr_C551);
%sort(data = max_8hr_C552);
%sort(data = max_8hr_C553);
%sort(data = max_8hr_C554);
%sort(data = max_8hr_C555);
%sort(data = max_8hr_C556);
%sort(data = max_8hr_C557);
%sort(data = max_8hr_C558);
%sort(data = max_8hr_C559);
%sort(data = max_8hr_C560);
%sort(data = max_8hr_C561);
%sort(data = max_8hr_C562);
%sort(data = max_8hr_C570);
%sort(data = max_8hr_C571);
%sort(data = max_8hr_C572);
%sort(data = max_8hr_C603);
%sort(data = max_8hr_C695);
%sort(data = max_8hr_C696);

data O3_8hrmax_only;
merge 
max_8hr_C1
max_8hr_C8
max_8hr_C15
max_8hr_C26
max_8hr_C35
max_8hr_C45
max_8hr_C53
max_8hr_C81
max_8hr_C84
max_8hr_C403
max_8hr_C405
max_8hr_C406
max_8hr_C408
max_8hr_C409
max_8hr_C410
max_8hr_C411
max_8hr_C416
max_8hr_C551
max_8hr_C552
max_8hr_C553
max_8hr_C554
max_8hr_C555
max_8hr_C556
max_8hr_C557
max_8hr_C558
max_8hr_C559
max_8hr_C560
max_8hr_C561
max_8hr_C562
max_8hr_C570
max_8hr_C571
max_8hr_C572
max_8hr_C603
max_8hr_C695
max_8hr_C696
;
by Date;
run;

*merge with lags only;
*merge files;
*sort and merge;
%macro sort (data=);
proc sort data = &data;
by Date;
run;
%mend sort;

%sort(data=O3_C1);
%sort(data=O3_C8);
%sort(data=O3_C26);
%sort(data=O3_C35);
%sort(data=O3_C45);
%sort(data=O3_C53);
%sort(data=O3_C81);
%sort(data=O3_C84);
%sort(data=O3_C403);
%sort(data=O3_C405);
%sort(data=O3_C406);
%sort(data=O3_C408);
%sort(data=O3_C409);
%sort(data=O3_C410);
%sort(data=O3_C411);
%sort(data=O3_C416);
%sort(data=O3_C551);
%sort(data=O3_C552);
%sort(data=O3_C553);
%sort(data=O3_C554);
%sort(data=O3_C555);
%sort(data=O3_C557);
%sort(data=O3_C558);
%sort(data=O3_C559);
%sort(data=O3_C560);
%sort(data=O3_C561);
%sort(data=O3_C562);
%sort(data=O3_C570);
%sort(data=O3_C571);
%sort(data=O3_C572);
%sort(data=O3_C603);
%sort(data=O3_C695);
%sort(data=O3_C696);

*merge data WITH LAGS;
data O3_8hrmax_daily_all;
merge 
O3_C1
O3_C8
O3_C26
O3_C35
O3_C45
O3_C53
O3_C81
O3_C84
O3_C403
O3_C405
O3_C406
O3_C408
O3_C409
O3_C410
O3_C411
O3_C416
O3_C551
O3_C552
O3_C553
O3_C554
O3_C555
O3_C557
O3_C558
O3_C559
O3_C560
O3_C561
O3_C562
O3_C570
O3_C571
O3_C572
O3_C603
O3_C603
O3_C695
O3_C696
;
by Date;
run;

ods graphics on;


***********************************************;



* Extract ozone 3 day average;
data predict.ozone_3_day;
	set O3_8hrmax_daily_all;
	ozone_3DayAve = mean(of max:);
	run;
data predict.ozone_3_day;
	set predict.ozone_3_day;
	keep date ozone_3DayAve;
	run;
	
* Extract and calculate day mean;
data predict.ozone_daily;
	set o3_8hrmax_only;
	ozone_daily = mean(of max:);
	run;
data predict.ozone_daily;
	set predict.ozone_daily;
	keep date ozone_daily;
	run;
	
data predict.ozone_data;
	merge predict.ozone_3_day predict.ozone_daily;
	by date;
	run;
	
	
* Get Time information and calculate the lag;
data predict.ozone_data;
	set predict.ozone_data;
	Year = year(date);
	Month = month(date);
	Day = day(date);
	weekday = weekday(date);
	beforeo3 = lag1(ozone_daily);
	run;
	
data predict.ozone_data;
	set predict.ozone_data;
	where (month in (3,9,10,11));
run;
	
* combine ozone data

** Merge data;

data predict.predict_data;
	merge predict.ozone_data predict.no2_data;
	by date;
	if date=. then delete;
	run;

** Import wind speed;

data predict.ws_raw;
	infile "/media/sf_myfolders/Dropbox/AsthmaOzone/mycode/data/2015/2015 Windspeed Data Extraction.csv" dlm=',' firstobs=2;
	input date yymmdd8. Time $ C1 C8 C11 C15 C26 C35 C45 C53 C78 C84 C96 C145 C148 C167 C169 C243 C403 C404 C409 C410 C416 C556 C559 C560 C603 C615 C615 C616 C616 C617 C618 C619 C620 C621 C621 C671 C671 C673 C673 C683 C683 C1012 C1015 C1016 C1017 C1020 C1022 C1029 C1034 C1036 C1049 C1052 C1066 C5005 C5006 C5012; 
RUN;


data predict.ws;
	set predict.ws_raw;
	average=mean(of C:);
	hour=hour(time);
run;

proc means data=predict.ws mean noprint;
	var average;
	class date;
	output out=predict.ws_daily(drop=_type_ _freq_) mean=avg_ws;
	run;


proc sort data=predict.ws_daily;
	by date;
	run;
	
	

** Mark for HRD;
* identify highrisk day;

data predict.predict_data;
	set predict.predict_data;
	if no2_daily_mean>=18 and ozone_3DayAve>=43 then hrd=1;
		else hrd=0;
	run;
	
proc print data=predict.predict_data;
	sum hrd;
	run;
	


** Merge Everything;
data predict.model_data;
	merge predict.predict_data predict.ws_daily;
	by date;
	if date=. then delete;
	if weekday(date)=6 or weekday(date)=7 then workday=0;
	else workday=1;
	run;
	
** Predict new data;
data predict.model_output;
	set predict.model_data;
	if weekday = 1 then wk=-1.2774;
	if weekday = 2 then wk=2.8616;
	if weekday = 3 then wk=3.2757;
	if weekday = 4 then wk=2.6789;
	if weekday = 5 then wk=3.0495;
	if weekday = 6 then wk=2.6194;
	if weekday = 7 then wk=0;
	
	p_no2 = 13.5003+0.2873*beforeno2-0.9548*avg_ws+wk;
	p_ozone =9.8968+0.0326*beforeno2+0.8146*beforeo3-0.2318*avg_ws;
	
	if p_no2 >=18 and p_ozone>=43 then p_hrd=1;
		else p_hrd=0;
	run;

proc print data=predict.model_output;
	where (month in (9,10,11));
run;

** Residual Plot;

data quantile_plot;
	set predict.model_output;
	residual_no2 = p_no2-no2_daily_mean;
	residual_ozone = p_ozone-ozone_3DayAve;
	residual_no2_squared = residual_no2**2;
	residual_ozone_squared = residual_ozone**2;
	run;

proc means data=quantile_plot mean noprint ;
	var residual_no2 residual_ozone;
	output out=residual_mean (drop=_type_ _freq_) mean=mean_residual_no2 mean_residual_ozone;
run;

data quantile_plot;
	merge residual_mean quantile_plot;
	run;	
proc sgplot data=quantile_plot;
	scatter x=ozone_3DayAve y=residual_ozone/markerattrs=(size=8);
	xaxis label="Ozone 3 day accumulated (Actual)";
	lineparm x=0 y=mean_residual_ozone slope=0 / legendlabel="Mean Residual";
	title "Residual Plot";

	run;
	
proc sgplot data=quantile_plot;
	scatter x=ozone_3DayAve y=residual_no2/markerattrs=(size=8);
	xaxis label="NO2 (Actual)";
	lineparm x=0 y=mean_residual_no2 slope=0 / legendlabel="Mean Residual";
	title "Residual Plot";
	run;
	
*Performance Assessment;
* ploting;
data predict.model_output_sum;
	set predict.model_output;
	where (month in (3,9,10,11));
	length predict $15;
	if p_hrd=1 and hrd=1 then predict = "CorrectHRD";
	if p_hrd=0 and hrd=1 then predict = "False Negative";
	if p_hrd=1 and hrd=0 then predict = "False Positive";
	if p_hrd=0 and hrd=0 then predict = "CorrectLRD";

	run;
	
ods graphics / reset attrpriority=none;

proc sgplot data=predict.model_output_sum;
	styleattrs	datacontrastcolors=(green red blue black)
				datasymbols=(Circle CircleFilled CircleFilled circle);
	refline 18 / axis=X;
	refline 43 / axis=Y;
	title 'Actual';
	scatter x=no2_daily_mean y=ozone_3DayAve /group=predict markerattrs=(size=5);
	yaxis label="Ozone 3 day accumulated (Actual)";
	xaxis label="NO2 day mean (Actual)";
	run;

proc sgplot data=predict.model_output_sum;
	styleattrs	datacontrastcolors=(green red blue)
				datasymbols=(Circle CircleFilled CircleFilled);
	refline 18 / axis=X;
	refline 43 / axis=Y;
	title 'Predicted';
	scatter x=p_no2 y=p_ozone /group=predict markerattrs=(size=5);
	yaxis label="Predicted Ozone 3 day accumulated";
	xaxis label="Predicted NO2 day mean";
	run;

*End of plots;
data summary;
	set predict.model_output;
	length predict $15;
	if p_hrd=1 and hrd=1 then predict = "CorrectHRD";
	if p_hrd=0 and hrd=1 then predict = "False Negative";
	if p_hrd=1 and hrd=0 then predict = "False Positive";
	if p_hrd=0 and hrd=0 then predict = "CorrectLRD";

	run;

data export;
	set predict.model_output;
	where (month in (9,10,11));
	run;
	
proc freq data=summary;
table predict/nopercent nocum; 
run;
	


