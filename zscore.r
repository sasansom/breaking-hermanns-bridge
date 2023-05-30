library("tidyverse")

x <- read_csv("sedes/joined.all.csv", col_types = cols(book_n = col_character())) %>%
	mutate(z = replace_na(z, 0.0))

# What fraction of word instances have a z-score of -2.0 or lower.
sum(x$z < -2.0) / length(x$z)

x %>% filter(sedes == 8.5) %>% summarize(sum(z < 0.0) / n())

options(width = 160)
print(x %>% filter(sedes == 8.5 & z > 0.0), n = 100)

summary((x %>% filter(sedes == 8.5))$z)

p <- ggplot(x, aes(z)) +
	geom_histogram(bins = 50) +
	facet_grid(rows = vars(sedes), scales = "free_y")
ggsave("zscore_by_sedes.png", p, width = 6, height = 10)
