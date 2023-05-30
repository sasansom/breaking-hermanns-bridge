all: \
	hermann-filtered.speaker.csv \
	break_rates.csv \
	break_rates_over_time.png \
	breaks_vs_caesurae_rates.png \
	speaker_frequency.csv \
	line_metrical_shape.csv
.PHONY: all

hermann-filtered.csv: .EXTRA_PREREQS = hermann-filter.py
hermann-filtered.csv: sedes/joined.all.csv
	./hermann-filter.py "$<" > "$@"
.INTERMEDIATE: hermann-filtered.csv

hermann-filtered.speaker.csv: .EXTRA_PREREQS = add-dices-speeches.py
hermann-filtered.speaker.csv: hermann-filtered.csv dices/data/1_0/speeches_*
	./add-dices-speeches.py dices/data/1_0 "$<" > "$@"

break_rates.csv \
break_rates_over_time.png \
breaks_vs_caesurae_rates.png \
speaker_frequency.csv \
: .EXTRA_PREREQS = HB_Database_Predraft.r
break_rates.csv \
break_rates_over_time.png \
breaks_vs_caesurae_rates.png \
speaker_frequency.csv \
&: HB_Database_Predraft.csv
	Rscript HB_Database_Predraft.r

line_metrical_shape.csv: .EXTRA_PREREQS = line_metrical_shape.r
line_metrical_shape.csv: sedes/corpus/*.csv
	Rscript line_metrical_shape.r $^ > "$@"

.DELETE_ON_ERROR:
