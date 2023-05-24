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
	# Add index to restore original ordering after summarization.
	mutate(idx = 1:n()) %>%

	# Concatenate the metrical_shape column for all words in each line, in order.
	# XXX: concatenates lines with duplicate line numbers.
	group_by(work, book_n, line_n) %>%
	summarize(
		across(c(idx, scanned, line_text), first),
		line_metrical_shape = paste0(metrical_shape, collapse = ""),
		.groups = "drop"
	) %>%

	# Restore original ordering.
	arrange(idx) %>%
	mutate(idx = NULL) %>%

	# Put columns in a nice order.
	select(work, book_n, line_n, scanned, line_metrical_shape, line_text) %>%

	# Output to CSV.
	format_csv() %>% cat()
