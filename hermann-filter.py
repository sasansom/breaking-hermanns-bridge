#!/usr/bin/env python3

# Usage:
#   filter-hermann.py sedes/corpus/*.csv
#
# Filters the input to include only the rows with a word at sedes 8.5, and the
# rows of the preceding sedes.

import csv
import getopt
import sys
import unicodedata

def usage(file = sys.stdout):
    print(f"""\
Usage: {sys.argv[0]} INPUT.CSV...

Filters the input to include only the rows with a word at sedes 8.5, and
the rows of the preceding sedes.
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
    before_row = None
    for row in r:
        try:
            sedes_begin = float(row["sedes"])
        except ValueError:
            print(f"missing sedes: {','.join(row.values())!r}", file = sys.stderr)
            continue
        sedes_end = sedes_begin + metrical_length(row["metrical_shape"])
        if sedes_end == 8.5:
            # Word before the caesura.
            before_row = row  # Will output this line.
        elif sedes_begin == 8.5:
            # Word after the caesura.
            if before_row is not None:
                w.writerow(before_row)
                w.writerow(row)

opts, args = getopt.gnu_getopt(sys.argv[1:], "h", ("help",))
for o, _ in opts:
    if o in ("-h", "--help"):
        usage()
        sys.exit(0)

r = input_dictreader(args)
w = csv.DictWriter(sys.stdout, fieldnames = r.fieldnames, lineterminator = "\n")
w.writeheader()
process(r, w)
