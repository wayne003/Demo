/* Script for data cleaning and importing */
/* Latest update: Dec.11.2015 */



%let dirname=C:\Users\ziwei\Dropbox\AsthmaOzone\mycode;

libname no2 "&dirname\lib\no2\";
libname ozone "&dirname\lib\ozone\";
libname model "&dirname\lib\model\";
%let no2_dirname=&dirname\data\no2\;
%let o3_dirname=&dirname\data\ozone_aqi\;
%let output_dirname=&dirname\output\;


** Import the CSV file.;
** Mannual import with variable predefined to avoid automatic changing of the variable type;
	
%macro bulkimport_no2(year=);
%do year=2004 %to 2013;
data no2.con_&year;
	infile "&no2_dirname&year..csv" dlm=',' firstobs=2;
	input date yymmdd8. Time $ C1 C8 C15 C26 C34 C35 C45 C53 C78 C84 C403 C408 C411 C416 C603 C617 C618 C619 C620 C1015 C1016 C1034;
	time=input(time,time12.);
%end;


data no2.con_2012;
	infile "&no2_dirname.2012.csv" dlm=',' firstobs=2;
	input date yymmdd8. Time $ C1 C8 C15 C26 C35 C45 C53 C84 C403 C408 C416 C603 C617;
	time=input(time,time12.);
	*delete 0 value;
	/*
	array no2_C (13) C1 C8 C15 C26 C35 C45 C53 C84 C403 C408 C416 C603 C617;
	DO i=1 to 13;
		if no2_C(i)=0 then no2_C(i)=.;
	END;
	*/
	run;


* Reduce dataset, select only monitor stations that we interested;

%do year=2004 %to 2013;

data no2.con_&year;
	set no2.con_&year;
	keep date Time C1 C8 C15 C35 C45 C53 C84 C403 C408 C416 C603;
	*delete 0 value;
	/*
	array no2_C (11) C1 C8 C15 C35 C45 C53 C84 C403 C408 C416 C603;
	DO i=1 to 11;
		if no2_C(i)=0 then no2_C(i)=.;
	END;
	*/
	run;
%end;

* special procedure for 2012 year no2 data;


%mend bulkimport_no2;
%bulkimport_no2;

* merge all no2 data for each year into one single set;
	

%macro no2_merge(year=);
data no2.data;
	set 
	%do year=2004 %to 2013;
	no2.con_&year
	%end;

	;
%mend no2_merge;
%no2_merge;

data no2.data;
	set no2.data;
	hour = hour(Time);
	year = year(date);
	month = month(date);
	day = day(date);
	run;
	

*calculate no2 day mean, for model building;

proc means data=no2.data mean noprint ;
	var C1 C8 C15 C35 C45 C53 C84 C403 C408 C416 C603;
	class date;
	output out=no2.daily_mean(drop=_type_ _freq_) mean=;
run;

data no2.daily_mean;
	set no2.daily_mean;
	if date=. then delete;
	average = mean (of C:);
	run;
	
data no2.daily_mean;
	set no2.daily_mean;
	keep date average;
	rename average = no2_daily_mean;
	run;

*9PM-2AM NO2;
*lag all data 3 position to get right time interval;
*21 22 23 0 1 2 -> 0 1 2 3 4 5;

data no2.pm9am2;
	set no2.data;
	* Calculate average for 9pm to 2am;
	*hr: 21 22 23 0 1 2 -> 0 1 2 3 4 5;
	array no2_C (11) C1 C8 C15 C35 C45 C53 C84 C403 C408 C416 C603;
	DO i=1 to 11;
		if month ~= 11 then
			no2_C(i)= lag4(no2_C(i)); * 9-2+DST adjusting, DST end at Nov, lag one more;
		else
			no2_C(i)= lag3(no2_C(i));
	END;
	*Different DST start date is not considered. Start from March 1st for every year;
run;


proc means data=no2.pm9am2(where=(hour in (0,1,2,3,4,5))) mean noprint;
	var C1 C8 C15 C35 C45 C53 C84 C403 C408 C416 C603;
	class date;
	output out=no2.before(drop=_type_ _freq_) mean=beforeno2;
run;

* cleannning result dataset;
data no2.before;
	set no2.before;
	if date=. then delete;
run;


* Calculation for ozone;

* import;
%macro bulkimport(year=);
%do year=2004 %to 2013;
PROC IMPORT DATAFILE="&o3_dirname&year..csv"
		    OUT=ozone.con_&year
		    DBMS=CSV
		    REPLACE;
RUN;
%end;

%mend bulkimport;

%bulkimport;



* Macro for calculating maximum AQI Value for each day;
* AQI calculation is programmed in excel and exported to csv file;
* AQI value for each monitor is named as AQI_C#;

%macro ozone_calculate(year=);
%do year=2004 %to 2013;
data ozone.con_&year;
	set ozone.con_&year;
	meanCon = mean(OF max:);
	maxAQI = max(OF AQI:);
	date=input(put(date,8.),yymmdd8.);
	run;
%end;
%mend ozone_calculate;

%ozone_calculate;

* merge all year into one;

%macro ozone_merge(year=);
data ozone.data;
	set 
	%do year=2004 %to 2013;
	ozone.con_&year (keep=date year month day meanCon maxAQI)
	%end;
	;
	
%mend ozone_merge;
%ozone_merge;

* reduce the size,keep month that is interested in the study;
data ozone.data;
	set ozone.data;
	beforeo3 = lag1(meanCon);
run;



* Import wind speed data for model building;

proc import datafile="&o3_dirname.no2_met_variables.csv"
	out = model.no2_met_variables
	dbms=csv
	replace;
	run;

data model.no2_met_variables;
	set model.no2_met_variables;
	Date=mdy(Month,Day,Year);
	keep date avg_ws avg_bp avg_sr hrd;
	run;
data model.no2_met_variables;
	set model.no2_met_variables;
	rename hrd=hrd_old;
	run;

* merge data;
*merge ozone lag with no3 9pm-2am data;

data model.data;
	merge ozone.data no2.before;
	by date;
	if year=. and month=. and day=. then delete;
	rename meanCon = Ozone_mean;
	run;
* merge wind speed;
data model.data;
	merge model.data model.no2_met_variables;
	by date;
	if year=. and month=. and day=. then delete;
	ozone3 = mean(ozone_mean,lag1(ozone_mean),lag2(ozone_mean));
	run;

	
*merge original no2 data;
data model.data;
	merge model.data no2.daily_mean;
	by date;
	if year=. and month=. and day=. then delete;
	run;


* replace the old hrd value(2);

data model.data;
	set model.data;
	if no2_daily_mean>18 and ozone3>43 then hrd=1;
		else hrd=0;
	run;

*End of data importing and cleaning;



	
*/

