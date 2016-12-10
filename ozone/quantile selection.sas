/* Code for quantile search */
/* Run initializing code in model_quantile.sas prior to this code */
/* Reference:http://www2.sas.com/proceedings/sugi30/213-30.pdf */

%macro quantiles(NQuant, Quantiles);
	%do i=1 %to &NQuant;
		proc quantreg data=data_lag;
			class weekday;
			model no2_daily_mean = beforeno2 weekday avg_ws/ quantile=%scan(&Quantiles,&i,",");
			output out=out_no2&i p=p_no2&i;
		run;

		proc quantreg data=data_lag;
			class weekday;
			model  ozone3 = beforeno2 beforeo3 avg_ws/ quantile=%scan(&Quantiles,&i,",");
			output out=out_ozone&i p=p_ozone&i;
		run;
		
		data quantile_output&i;
			merge out_no2&i out_ozone&i;
			by date;
			if p_no2&i > 18 and p_ozone&i > 43 then hrd_predict=1;
				else hrd_predict=0;
		run;
				
		data quantile_summary&i;
			set quantile_output&i;
			length predict $15;
			if hrd_predict=1 and hrd=1 then predict = "CorrectHRD";
			if hrd_predict=0 and hrd=1 then predict = "False Negative";
			if hrd_predict=1 and hrd=0 then predict = "False Positive";
			if hrd_predict=0 and hrd=0 then predict = "CorrectLRD";
		run;
		
		proc freq data=quantile_summary&i;
			table predict/nopercent nocum out=q_sum&i; 
		run;
		
		/*identifiler*/
		data q_sum&i;
			set q_sum&i;
			Quantile=%scan(&Quantiles,&i,",");
			run;
		
		/*Transpose*/
		proc transpose data=q_sum&i
						out=q_sum_t&i;
		run;
	%end;
	
	data q_sum_all;
		set 
		%do i=1 %to &NQuant;
		q_sum&i
		%end;
		
		;

%mend;

%let quantiles = %str(0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9);
%quantiles(9,&quantiles);

proc sgplot data=q_sum_all;
	where (predict in ("False Negative", "False Positive"));
	series x=Quantile y=Count /group=predict;
	yaxis label="Days";
	xaxis label="Quantile";
	run;
