# Compares the list of transgressions reported by Alejandro Abritta 2018 "Sobre
# las violaciones de la ley de Hermann en Homero" with the caesurae in
# HB_Database_Predraft.csv.

library("tidyverse")
library("readxl")

# The lists of line numbers are stored in a rectangular area in the
# spreadsheet, with no column names, and with the book number being the row
# number. So, the line numbers for book 1 appear in row 1, with cells beyond
# the final line number in the book being blank. This function reads data in
# this format and converts it to resemble the format of
# HB_Database_Predraft.csv, with one row per transgression and book_n, line_n
# columns.
read_rectangular <- function(sheet, range) {
	read_xlsx("abritta2018/lista-de-violaciones-completa.xlsx", sheet = sheet, range = range, col_names = FALSE) %>%
		mutate(book_n = 1:n()) %>%
		pivot_longer(starts_with("..."), values_to = "line_n", values_drop_na = TRUE) %>% mutate(name = NULL) %>%
		mutate(across(c(book_n, line_n), as.character))
}

abritta <- bind_rows(
	read_rectangular("Lista completa Iliada", "A1:BC24") %>% mutate(work = "Il."),
	read_rectangular("Lista completa Odisea", "A1:AS24") %>% mutate(work = "Od.")
)

ours <- read_csv(
	"HB_Database_Predraft.csv",
	col_types = cols(
		work = col_character(),
		book_n = col_character(),
		line_n = col_character()
	)
) %>%
	mutate(
		across(c(breaks_hb_schein, is_speech), ~ recode(.x, "Yes" = TRUE, "No" = FALSE)),
		enclitic = recode(enclitic, "Enclitic" = TRUE, `Non-enclitic` = FALSE)
	) %>%
	# Keep one representative row per line of verse.
	filter(word_n == caesura_word_n) %>%
	filter(work %in% c("Il.", "Od."))

cat("\nPresent in ours but absent in Abritta:\n")
print(anti_join(ours, abritta), n = 100)
cat("\nPresent in Abritta but absent in ours:\n")
print(anti_join(abritta, ours), n = 100)
