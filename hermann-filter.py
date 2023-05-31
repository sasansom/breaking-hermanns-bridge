#!/usr/bin/env python3

# Usage:
#   filter-hermann.py sedes/corpus/*.csv
#
# Filters the input to include only the rows with a word at sedes 8.5, and the
# rows of the words at the preceding sedes. Adds a caesura_word_n column
# containing the word_n of the first word at the caesura in the line.

import csv
import getopt
import sys
import unicodedata

def usage(file = sys.stdout):
    print(f"""\
Usage: {sys.argv[0]} INPUT.CSV...

Filters the input to include only the rows with a word at sedes 8.5, and
the rows of the words at the preceding sedes. Adds a caesura_word_n
column containing the word_n of the first word at the caesura in the
line.
""", end="", file=file)

def normalize(s):
    return unicodedata.normalize("NFD", s)

# Acts like a csv.DictReader over multiple files consecutively. Asserts that the
# fieldnames of all files are identical.
class MultiDictReader:
    def __init__(self, filenames):
        self.filenames = filenames
        self.first_file = open(self.filenames[0])
        self.first_reader = csv.DictReader(self.first_file)
        self.fieldnames = self.first_reader.fieldnames

    def __iter__(self):
        try:
            for row in self.first_reader:
                yield row
        finally:
            self.first_file.close()
        for filename in self.filenames[1:]:
            with open(filename) as f:
                reader = csv.DictReader(f)
                assert reader.fieldnames == self.fieldnames, (self.filenames[0], reader.fieldnames, filename, self.fieldnames)
                for row in reader:
                    yield row

def input_dictreader(args):
    if len(args) == 0:
        return sys.stdin
    else:
        return MultiDictReader(args)

def metrical_length(metrical_shape):
    return sum({"⏑": 0.5, "–": 1.0}[c] for c in metrical_shape)

def process(r, w):
    prev_loc = None
    pre_buffer = []
    caesura_word_n = None
    for row in r:
        try:
            sedes_begin = float(row["sedes"])
        except ValueError:
            print(f"missing sedes: {','.join(row.values())!r}", file = sys.stderr)
            continue
        length = metrical_length(row["metrical_shape"])

        # Whenever we advance to a new line, output any previous buffer of words
        # that end at sedes 8.5.
        loc = (row["work"], row["book_n"], row["line_n"])
        if prev_loc is None or prev_loc != loc:
            prev_loc = loc
            caesura_word_n = None
            # We don't actually expect pre_buffer to ever be non-empty here,
            # because it would usually have been output and emptied by the code
            # below that handles words that are at 8.5. But it could occur if a
            # line were fragmentary and ended exactly at 8.5.
            w.writerows(dict(r, **{"caesura_word_n": caesura_word_n}) for r in pre_buffer)
            pre_buffer.clear()

        # Check if the current word begins at 8.5 before checking if it ends at
        # 8.5. This only matters with words whose metrical length is zero, like
        # "δ’". Prioritizing the "begin" check means that such words will be
        # considered to come after the caesura. It would also be a valid
        # interpretation to put them before the caesura, but such cases are most
        # commonly elision that should attach to the word to the right.
        if sedes_begin == 8.5:
            # If this is the first word at 8.5 in this line, mark its word_n as
            # the caesura_word_n, and output the buffer of words that end at
            # 8.5.
            if caesura_word_n is None:
                caesura_word_n = row["word_n"]
                w.writerows(dict(r, **{"caesura_word_n": caesura_word_n}) for r in pre_buffer)
                pre_buffer.clear()
            w.writerow(dict(row, **{"caesura_word_n": caesura_word_n}))
        elif sedes_begin + length == 8.5 or length == 0:
            # A word at the sedes immediately before the caesura. We will output
            # a row for this word, but we don't yet know what its caesura_word_n
            # should be. Buffer it until we either see a word at 8.5, or enter a
            # different line.
            pre_buffer.append(row)
        else:
            pre_buffer.clear()
    caesura_word_n = None
    w.writerows(dict(r, **{"caesura_word_n": caesura_word_n}) for r in pre_buffer)
    pre_buffer.clear()

opts, args = getopt.gnu_getopt(sys.argv[1:], "h", ("help",))
for o, _ in opts:
    if o in ("-h", "--help"):
        usage()
        sys.exit(0)

r = input_dictreader(args)
w = csv.DictWriter(sys.stdout, fieldnames = r.fieldnames + ["caesura_word_n"], lineterminator = "\n")
w.writeheader()
process(r, w)
