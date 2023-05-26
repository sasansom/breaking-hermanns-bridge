all: \
	hermann-filtered.csv \
	break_rates.csv \
	break_rates_over_time.png \
	breaks_vs_transgression_rates.png \
	line_metrical_shape.csv
.PHONY: all

hermann-filtered.csv: .EXTRA_PREREQS = hermann-filter.py
hermann-filtered.csv: sedes/joined.all.csv
	./hermann-filter.py "$<" > "$@"

break_rates.csv \
break_rates_over_time.png \
breaks_vs_transgression_rates.png \
: .EXTRA_PREREQS = HB_Database_Predraft.r
break_rates.csv \
break_rates_over_time.png \
breaks_vs_transgression_rates.png \
&: HB_Database_Predraft.csv
	Rscript HB_Database_Predraft.r

line_metrical_shape.csv: .EXTRA_PREREQS = line_metrical_shape.r
line_metrical_shape.csv: sedes/corpus/*.csv
	Rscript line_metrical_shape.r $^ > "$@"

.DELETE_ON_ERROR:
