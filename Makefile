break_rates.csv \
break_rates_over_time.png \
breaks_vs_transgression_rates.png \
: .EXTRA_PREREQS = HB_Database_Predraft.r
break_rates.csv \
break_rates_over_time.png \
breaks_vs_transgression_rates.png \
&: HB_Database_Predraft.csv
	Rscript HB_Database_Predraft.r

.DELETE_ON_ERROR:
