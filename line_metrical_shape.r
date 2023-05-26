# Extracts full lines from SEDES corpus CSV files and concatenates their
# metrical_shape columns.
#
# Usage:
#   Rscript line_metrical_shape.r sedes/corpus/*.csv > line_metrical_shape.csv

library("tidyverse")

bind_rows(lapply(
        commandArgs(trailingOnly = TRUE),
        read_csv,
        na = character(),
        col_types = cols(
		book_n = col_character(),
		line_n = col_character()
	)
)) %>%
	# Add an index to the original lines, in order to restore original
	# ordering after summarization. This also disambiguates cases of
	# duplicate line numbers: we consider it a line break whenever word_n
	# does not increase--otherwise all the words in the lines with repeated
	# line numbers would be considered part of one big line.
	mutate(idx = cumsum(replace_na(
		!(work == lag(work) & book_n == lag(book_n) & line_n == lag(line_n) & word_n > lag(word_n)),
	TRUE))) %>%

	# Concatenate the metrical_shape column for all words in each line, in order.
	group_by(work, book_n, line_n, idx) %>%
	summarize(
		across(c(scanned, line_text), first),
		line_metrical_shape = paste0(metrical_shape, collapse = ""),
		.groups = "drop"
	) %>%

	# Restore original ordering.
	arrange(idx) %>%

	# Put columns in a nice order.
	select(work, book_n, line_n, scanned, line_metrical_shape, line_text) %>%

	# Output to CSV.
	format_csv() %>% cat()
