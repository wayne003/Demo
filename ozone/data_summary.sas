/* Script for data summary */
/* Latest update: Dec.11.2015 */

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

data data_summary;
	set model.data;
	where (month in (3,9,10,11));
	** Calculate 3 day accumulated ozone;
	ozone3 = mean(ozone_mean,lag1(ozone_mean),lag2(ozone_mean));
	run;

* identify highrisk day;

data highrisk;
	set data_summary;
	if no2_day_mean>18 and ozone3>43 then rw_hrd=1;
		else rw_hrd=0;
	run;
	
proc print data=highrisk;
	sum rw_hrd;
	run;
proc sort data=highrisk;
	by month;
	run;

proc summary data=highrisk sum print;
	var rw_hrd;
	by month;
	run;
		
proc print data=data_summary;
	where (no2_day_mean>18 and Ozone3>43);
	title 'Days with Concentration Ozone>43 and NO2>18';
	sum hrd;
	run;

proc print data=data_summary;
	where (maxAQI>100 and no2_day_mean>18 and ozone3>43);
	title 'AQI>100 & Days with Concentration Ozone>43 and NO2>18';
	sum hrd;
	run;
	

* Plot data with AQI value color coded;

** Create AQI Quality Category, according to EPA guideline;
data data_summary_AQI;
	set data_summary;
	if maxAQI<51 then AirQuality=1;
	else if maxAQI<101 then AirQuality=2;
	else if maxAQI<151 then AirQuality=3;
	else if maxAQI<201 then AirQuality=4;
	else if maxAQI<301 then AirQuality=5;
	else if maxAQI>300 then AirQuality=6;
	run;

** Sort out data, for color tagging;
proc sort data=data_summary_AQI;
	by AirQuality;
run;


** Create format for plot legend;
proc format;
	value AirQualityFmt
	1='Good'
	2='Moderate'
	3='Unhealthy for Sensitive Group'
	4='Unhealthy'
	5='Very Unhealthy'
	6='Hazardous'
	;
run;

** Create Scatter Plot, color code according to EPA guideline for AQI;

proc sgplot data=data_summary_AQI;
	styleattrs	datacontrastcolors=(cx00ff00 cxffff00 cxff0000 cx99004c cx7e0023)
				datasymbols=(CircleFilled);
	refline 18 / axis=X;
	refline 43 / axis=Y;
	format AirQuality AirQualityFmt.;
	title 'Scatter Plot with AQI';
	scatter x=no2_day_mean y=ozone3 /group=AirQuality;
	run;


