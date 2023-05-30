library("tidyverse")

x <- read_csv("sedes/joined.all.csv", col_types = cols(book_n = col_character())) %>%
	mutate(z = replace_na(z, 0.0))
# What fraction of word instances have a z-score of -2.0 or lower.
sum(x$z < -2.0) / length(x$z)
