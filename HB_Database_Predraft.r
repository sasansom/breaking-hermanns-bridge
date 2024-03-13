library("tidyverse")
library("cowplot")

WIDTH <- 6 # in

WORKS <- tribble(
	~work,         ~date, ~era,          ~work_name,
	"Argon.",       -350, "hellenistic", "Argonautica",
	"Callim.Hymn",  -250, "hellenistic", "Callimachus’ Hymns",
	"Dion.",         450, "imperial",    "Nonnus’ Dionysiaca",
	"Hom.Hymn",     -600, "archaic",     "Homeric Hymns",
	"Il.",          -750, "archaic",     "Iliad",
	"Od.",          -750, "archaic",     "Odyssey",
	"Phaen.",       -250, "hellenistic", "Aratus’ Phaenomena",
	"Q.S.",          350, "imperial",    "Quintus of Smyrna’s Fall of Troy",
	"Sh.",          -550, "archaic",     "Shield",
	"Theoc.",       -250, "hellenistic", "Theocritus’ Idylls",
	"Theog.",       -750, "archaic",     "Theogony",
	"W.D.",         -750, "archaic",     "Works and Days",
)

# TODO: fix off-by-one in BCE dates.
PERIODS <- tribble(
	~start, ~end, ~name,
	  -800, -500, "Archaic",     # https://en.wikipedia.org/wiki/Classical_antiquity#Archaic_period_(c._8th_to_c._6th_centuries_BC)
	  -323, -146, "Hellenistic", # https://en.wikipedia.org/wiki/Classical_antiquity#Hellenistic_period_(323%E2%80%93146_BC)
	  -100,  500, "Imperial",    # https://en.wikipedia.org/wiki/Classical_antiquity#Hellenistic_period_(323%E2%80%93146_BC)
)

FONT_FAMILY <- "Times"
theme_set(
        theme_minimal(
                base_family = FONT_FAMILY,
                base_size = 10
        )
)
update_geom_defaults("text", aes(family = FONT_FAMILY))

# Read sedes/joined.all.csv just to get the total number of lines per work.
num_lines <- read_csv("sedes/joined.all.csv",
	col_types = cols_only(
		work = col_factor(),
		book_n = col_character(),
		line_n = col_character(),
		word_n = col_integer()
	)
) %>%
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
		.groups = "drop"
	) %>% mutate(
		# Set book_n to NA for works that don't have separate books.
		book_n = case_when(work %in% c("Sh.", "Theog.", "W.D.", "Phaen.") ~ NA_character_, TRUE ~ book_n),
		book_n = as.numeric(book_n)
	)

num_lines_by_book <- count(num_lines, work, book_n, name = "num_lines")
num_lines <- count(num_lines, work, name = "num_lines")

# Read input and tidy.
data <- read_csv(
	"HB_Database_Predraft.csv",
	col_types = cols(
		work = col_factor(),
		book_n = col_character(),
		line_n = col_character()
	)
) %>%
	mutate(
		across(c(breaks_hb_schein, is_speech), ~ recode(.x, "Yes" = TRUE, "No" = FALSE)),
		enclitic = recode(enclitic, "Enclitic" = TRUE, `Non-enclitic` = FALSE),
		# Set book_n to NA for works that don't have separate books.
		# https://github.com/sasansom/sedes/issues/82
		book_n = case_when(work %in% c("Sh.", "Theog.", "W.D.", "Phaen.") ~ NA_character_, TRUE ~ book_n),
		book_n = as.numeric(book_n)
	)

# Sanity check that some columns that are supposed to be constant within a line
# are actually constant.
inconsistent <- data %>%
	group_by(work, book_n, line_n) %>%
	summarize(across(c(caesura_word_n, breaks_hb_schein, speaker, is_speech), ~ length(unique(.x))), .groups = "drop") %>%
	filter(caesura_word_n != 1 | breaks_hb_schein != 1 | speaker != 1 | is_speech != 1)
if (nrow(inconsistent) != 0) {
	print(inconsistent)
	stop()
}

break_rates <- data %>%
	# Keep one representative row per line of verse.
	filter(word_n == caesura_word_n) %>%

	# Count up breaks per work.
	group_by(work) %>%
	summarize(
		num_breaks = sum(breaks_hb_schein),
		num_caesurae = n(),
		.groups = "drop"
	) %>%

	# Join with tables of per-work metadata.
	(function(x) full_join(num_lines, x, by = c("work")))() %>%
	# Substitute 0 breaks/caesurae for works not represented in data.
	mutate(across(c(num_breaks, num_caesurae), ~ replace_na(.x, 0))) %>%
	left_join(WORKS, by = c("work")) %>%

	# Sort in decreasing order by break rate, then by ascending by date,
	# then ascending by work name.
	arrange(desc(num_breaks / num_lines), date, work_name)

break_rate_overall <- (break_rates %>%
	summarize(num_breaks = sum(num_breaks), num_lines = sum(num_lines)) %>%
	mutate(rate = num_breaks / num_lines))$rate[[1]]
print(c("break rate overall", break_rate_overall))

# Output development table of break rates and caesura rates.
break_rates %>%
	bind_rows(break_rates %>%
		summarize(
			across(c(num_breaks, num_caesurae, num_lines), sum),
			work = "total"
		)
	) %>%
	transmute(
		`work` = work,
		`L` = num_lines,
		`C` = num_caesurae,
		`B` = num_breaks,
		`C/L%` = sprintf("%.3f%%", 100 * num_caesurae / num_lines),
		`B/C%` = sprintf("%.3f%%", 100 * num_breaks / num_caesurae),
		`B/L%` = sprintf("%.3f%%", 100 * num_breaks / num_lines),
		binom_p_lt = pbinom(num_breaks, num_lines, break_rate_overall),
	)

break_rates_by_book <- data %>%
	# Keep one representative row per line of verse.
	filter(word_n == caesura_word_n) %>%

	# Count up breaks per work.
	group_by(work, book_n) %>%
	summarize(
		num_breaks = sum(breaks_hb_schein),
		num_caesurae = n(),
		.groups = "drop"
	) %>%

	# Join with tables of per-book metadata.
	(function(x) full_join(num_lines_by_book, x, by = c("work", "book_n")))() %>%
	# Substitute 0 breaks/caesurae for books not represented in data.
	mutate(across(c(num_breaks, num_caesurae), ~ replace_na(.x, 0))) %>%
	left_join(WORKS, by = c("work")) %>%

	# Sort in decreasing order by break rate, then by ascending by date,
	# then ascending by work name.
	arrange(desc(num_breaks / num_lines), date, work_name)

cat("lines without and with enclitic:")
table((data %>%
	filter(breaks_hb_schein) %>%
	group_by(work, book_n, line_n) %>%
	summarize(enclitic = any(enclitic), .groups = "drop")
)$enclitic)
cat("breaks/quasi-breaks in speech/not-speech:\n")
table(data %>%
	filter(word_n == caesura_word_n) %>%
	select(breaks_hb_schein, is_speech))

# Output publication table of speaker frequency.
WORK_NAME_ABBREV <- c(
	"Argon." = "Argon.",
	"Callim.Hymn" = "Callim.\u00a0Hymn",
	"Dion." = "Dion.",
	"Hom.Hymn" = "Hom.\u00a0Hymn",
	"Il." = "Il.",
	"Od." = "Od.",
	"Phaen." = "Phaen.",
	"Q.S." = "Q.S.",
	"Sh." = "Sh.",
	"Theoc." = "Theoc.",
	"Theog." = "Theog.",
	"W.D." = "Op."
)
speaker_freq <- data %>%
	filter(word_n == caesura_word_n & breaks_hb_schein) %>%
	group_by(speaker) %>% mutate(n = n()) %>% ungroup() %>%
	select(n, speaker, work, book_n, line_n) %>%
	arrange(desc(n), speaker, work, book_n, line_n)
speaker_freq %>%
	# Split apart the speaker and whom they are quoting. Does not handle
	# more than one level of quoting.
	mutate(
		temp = str_split_fixed(speaker, ">", 2),
		speaker = na_if(temp[,1], ""),
		quoting = na_if(temp[,2], ""),
		temp = NULL
	) %>%
	arrange(work, as.integer(book_n), as.integer(gsub("^(\\d*).*", "\\1", line_n))) %>%
	group_by(speaker, work) %>%
	summarize(
		n = n(),
		verses = str_c(sprintf("%s%s%s",
			ifelse(is.na(book_n), "", sprintf("%s.", book_n)),
			line_n,
			ifelse(is.na(quoting), "", sprintf("\u00a0(quoting %s)", quoting))), collapse = ", "),
		.groups = "drop"
	) %>%
	group_by(speaker) %>%
	summarize(
		n = sum(n),
		verses = str_c(sprintf("%s\u00a0%s", WORK_NAME_ABBREV[as.character(work)], verses), collapse = "; "),
		.groups = "drop"
	) %>%
	arrange(desc(n), speaker) %>%
	filter(speaker != "narrator") %>%
	mutate(speaker = recode(speaker, "Aias (son of Telamon)" = "Telamonian Ajax")) %>%
	transmute(
		`#` = n,
		`Speaker` = speaker,
		`Breaks` = verses
	) %>%
	write_csv("speaker_frequency.csv", na = "")

# Scatterplot of breaks per caesura and caesurae per line.
p <- ggplot(break_rates,
	aes(
		x = num_breaks / num_caesurae,
		y = num_caesurae / num_lines,
		label = work
	)
) +

	geom_point(alpha = 0.8) +
	geom_text(hjust = 0, nudge_x = 0.001) +

	scale_x_continuous(
		labels = scales::label_percent(accuracy = 1.0),
		breaks = seq(0, max(with(break_rates, num_breaks / num_caesurae)), 0.02)
	) +
	scale_y_continuous(
		labels = scales::label_percent(accuracy = 1.0),
		breaks = seq(0, max(with(break_rates, num_caesurae / num_lines)), 0.02)
	) +
	coord_fixed(
		# Make room for labels at the top and right.
		xlim = c(0, max(with(break_rates, num_breaks / num_caesurae)) + 0.015),
		ylim = c(0, max(with(break_rates, num_caesurae / num_lines)) + 0.002),
		expand = FALSE,
		clip = "off"
	) +
	labs(
		x = "rate of breaks per caesura",
		y = "rate of caesurae per line"
	)
ggsave("breaks_vs_caesurae_rates.png", p, width = WIDTH, height = 3.5)

# Plot of breaks per line over time.
p <- ggplot(break_rates,
	aes(
		x = date,
		y = num_breaks / num_lines,
		label = work
	)
) +

	geom_rect(
		data = PERIODS,
		inherit.aes = FALSE,
		aes(
			xmin = start,
			xmax = end,
			ymin = 0.0045,
			ymax = 0.0050
		),
		alpha = 0.2
	) +
	geom_text(
		data = PERIODS,
		inherit.aes = FALSE,
		aes(
			x = (start + end) / 2,
			y = (0.0045 + 0.0050) / 2,
			label = name
		),
		size = 3
	) +

	geom_point(alpha = 0.8) +
	geom_text(hjust = 0, nudge_x = 10) +

	scale_x_continuous(labels = scales::label_number(accuracy = 1)) +
	scale_y_continuous(labels = scales::label_percent(accuracy = 0.1)) +
	coord_cartesian(
		xlim = with(break_rates, c(min(date) - 50, max(date) + 75)),
		# ylim = c(0, max(with(break_rates, num_breaks / num_lines))),
		expand = FALSE,
		clip = "off"
	)+
	labs(
		x = "year",
		y = "rate of breaks per line"
	)
ggsave("break_rates_over_time.png", p, width = WIDTH, height = 3)

# Output publication table of breaks per work.
break_rates %>%
	bind_rows(break_rates %>%
		summarize(
			across(c(num_breaks, num_caesurae, num_lines), sum),
			work_name = "total"
		)
	) %>%
	transmute(
		`Work` = work_name,
		`Lines` = scales::comma(num_lines, accuracy = 1),
		`Caesurae` = scales::comma(num_caesurae, accuracy = 1),
		`Breaks` = scales::comma(num_breaks, accuracy = 1),
		`Breaks/Line` = ifelse(num_breaks == 0,
			sprintf("\u00a0%.g%%", 100 * num_breaks / num_lines),
			sprintf("\u00a0%.2f%%", 100 * num_breaks / num_lines)
		),
		`_` = ifelse(num_breaks == 0,
			"",
			sprintf("(1\u00a0per\u00a0%s)", scales::comma(num_lines / num_breaks, accuracy = 1))
		),
	) %>%

	write_csv("break_rates.csv") %>% print()

# Output table of breaks per era.
cat("\nBreak rates by era:")
summarize_era <- function(eras) {
	tibble(
		era = stringi::stri_join(eras, collapse="|"),
		break_rates %>% filter(era %in% eras) %>%
			summarize(across(c(num_breaks, num_caesurae, num_lines), sum)),
	)
}
bind_rows(
	summarize_era(c("archaic")),
	summarize_era(c("hellenistic")),
	summarize_era(c("hellenistic", "archaic")),
	summarize_era(c("imperial")),
	summarize_era(c("imperial", "hellenistic", "archaic")),
) %>% mutate(
	lines_per_break = sprintf("%.f", num_lines / num_breaks),
) %>% print() %>% write_csv("break_rates_by_era.csv")

# Output publication table of breaks per book.
break_rates_by_book %>%
	mutate(
		binom_p_ge = pbinom(num_breaks - 1, num_lines, p = break_rate_overall, lower.tail = FALSE),
	) %>%
	arrange(binom_p_ge, date, work_name) %>%
	transmute(
		`Work` = work,
		`Book/poem` = book_n,
		`Lines` = scales::comma(num_lines, accuracy = 1),
		`Breaks` = scales::comma(num_breaks, accuracy = 1),
		`Breaks/Line` = ifelse(num_breaks == 0,
			sprintf("%.g%%", 100 * num_breaks / num_lines),
			sprintf("%.2f%%", 100 * num_breaks / num_lines)
		),
		`Chance of at least this many breaks, assuming random distribution` = sprintf("%.2g%%", 100 * binom_p_ge),
	) %>%
	write_csv("break_rates_by_book.csv", na = "") %>% print(n = 100)

# Dot plot of number of breaks per book in selected works.
cluster_graphs <- list()
cluster_specs <- list(
	list(
		work = "Il.",
		books = 1:24,
		book_names = c("Book 1", as.character(2:24)),
		label = expression(italic("Iliad")),
		w = 8
	),
	list(
		work = "Od.",
		books = 1:24,
		book_names = c("Book 1", as.character(2:24)),
		label = expression(italic("Odyssey")),
		w = 8
	),
	list(
		work = "Hom.Hymn",
		books = 1:33,
		book_names = sprintf("%s %2d", c(
			"To Dionysus",
			"To Demeter",
			"To Apollo",
			"To Hermes",
			"To Aphrodite",
			"To Aphrodite",
			"To Dionysus",
			"To Ares",
			"To Artemis",
			"To Aphrodite",
			"To Athena",
			"To Hera",
			"To Demeter",
			"To the mother of the gods",
			"To Heracles",
			"To Asclepius",
			"To the Dioscuri",
			"To Hermes",
			"To Pan",
			"To Hephaestus",
			"To Apollo",
			"To Poseidon",
			"To Zeus",
			"To Hestia",
			"To the Muses and Apollo",
			"To Dionysus",
			"To Artemis",
			"To Athena",
			"To Hestia",
			"To Gaia, mother of all",
			"To Helios",
			"To Selene",
			"To the Dioscuri"
		), 1:33),
		label = expression(italic("Hom. Hymns")),
		w = 16
	),
	list(
		work = "Theoc.",
		books = c(1:7, 9:27), # Omit Idyll 8, which is elegaic.
		book_names = c("Idyll 1", as.character(2:7), as.character(9:27)),
		label = expression(italic("Theoc.")),
		w = 6
	),
	list(
		work = "Q.S.",
		books = 1:14,
		book_names = c("Book 1", as.character(2:14)),
		label = expression(italic("Q.S.")),
		w = 6
	)
)
for (g in cluster_specs) {
	cluster <- data %>%
		filter(work == g$work) %>%
		filter(word_n == caesura_word_n & breaks_hb_schein) %>%
		mutate(book_n = factor(book_n, g$books))
	cluster_graphs[[length(cluster_graphs) + 1]] <- ggplot(cluster) +
		geom_dotplot(aes(book_n), method = "histodot", binwidth = 1, dotsize = 0.8, drop = FALSE) +
		scale_x_discrete(
			limits = rev(factor(1:33)),
			breaks = rev(levels(cluster$book_n)),
			labels = rev(g$book_names)
		) +
		scale_y_continuous(NULL, breaks = NULL, expand = expansion(0, 0.05)) +
		coord_flip() +
		labs(x = NULL, y = NULL, title = g$label)
}
ggsave("clusters.png",
	plot_grid(
		plotlist = cluster_graphs,
		nrow = 1, align = "h",
		rel_widths = unlist(lapply(cluster_specs, function(g) g$w))
	),
	width = 6, height = 4
)
