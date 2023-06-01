library("tidyverse")

WORKS <- tribble(
	~work,         ~work_name,
	"Argon.",      "Argonautica",
	"Callim.Hymn", "Callimachus’ Hymns",
	"Dion.",       "Nonnus’ Dionysiaca",
	"Hom.Hymn",    "Homeric Hymns",
	"Il.",         "Iliad",
	"Od.",         "Odyssey",
	"Phaen.",      "Aratus’ Phaenomena",
	"Q.S.",        "Quintus of Smyrna’s Fall of Troy",
	"Sh.",         "Shield",
	"Theoc.",      "Theocritus’ Idylls",
	"Theog.",      "Theogony",
	"W.D.",        "Works and Days",
	"total",       "Total"
)

data <- read_csv("sedes/joined.all.speaker.csv",
	col_types = cols_only(
		work = col_factor(),
		book_n = col_character(),
		line_n = col_character(),
		word_n = col_integer(),
		is_speech = col_factor()
	)
) %>%
	mutate(across(c(is_speech), ~ recode(.x, "Yes" = TRUE, "No" = FALSE))) %>%

	# Add an index to the original lines, in order to restore original
	# ordering after summarization. This also disambiguates cases of
	# duplicate line numbers: we consider it a line break whenever word_n
	# does not increase--otherwise all the words in the lines with repeated
	# line numbers would be considered part of the same line.
	mutate(idx = cumsum(replace_na(
		!(work == lag(work) & book_n == lag(book_n) & line_n == lag(line_n) & word_n > lag(word_n)),
	TRUE))) %>%

	group_by(idx) %>%
	summarize(
		across(c(work, book_n, line_n), first),
		is_speech = any(is_speech),
		.groups = "drop"
	) %>%
	count(work, is_speech) %>%
	pivot_wider(id_cols = work, names_from = is_speech, values_from = n)

# Manually fill in total for the two works that are not covered by DICES.
# Stephen Sansom writes:
#
#	All speech in Aratus is narrator speech.
#	Here are the details of speech for the Shield:
#	Character Speech	Narrator Speech
#	------------------	---------------
#	Heracles	46
#	Iolaos		12
#	Athena		15
#	Total		73	407
#
# The total for Sh. is 480, which is different from the 479 that we compute
# ourselves. We'll keep the character speech lines the same, and subtract 1
# from the narrator speech.
data <- data %>%
	filter(!(work %in% c("Phaen.", "Sh."))) %>%
	bind_rows(tribble(
		~work, ~`NA`, ~`TRUE`, ~`FALSE`,
		"Phaen.",  0,       0,     1155,
		"Sh.",     0,      73,      406
	))

data <- data %>%
	arrange(desc(`TRUE` / mapply(sum, `FALSE`, `TRUE`, `NA`, na.rm = TRUE)))

data <- data %>%
	bind_rows(data %>%
		summarize(
			across(c(`NA`, `FALSE`, `TRUE`), sum, na.rm = TRUE),
			work = "total"
		)
	) %>%
	mutate(percent_speech = sprintf("%4.1f%%", 100 * `TRUE` / mapply(sum, `FALSE`, `TRUE`, `NA`, na.rm = TRUE))) %>%
	mutate(`NA` = NULL) %>%
	print() %>%
	left_join(WORKS, by = c("work")) %>%
	transmute(
		`Work` = work_name,
		`Character Speech` = scales::comma(`TRUE`, accuracy = 1),
		`character %` = sprintf("%.1f%%", 100 * `TRUE` / (`FALSE` + `TRUE`)),
		`Narrator` = scales::comma(`FALSE`, accuracy = 1),
		`narrator %` = sprintf("%.1f%%", 100 * `FALSE` / (`FALSE` + `TRUE`))
	) %>%
	write_csv("speech_ratio.csv")
