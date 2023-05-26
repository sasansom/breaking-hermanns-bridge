#!/usr/bin/env python3

# Usage:
#   ./add-dices-speeches.py dices/data/1_0 hermann-filtered.csv > hermann-filtered.speaker.csv
#
# Adds is_speech and speaker columns to a SEDES-like corpus CSV file from a
# DICES speech database.

import getopt
import os
import re
import sys

import pandas as pd

def usage(file = sys.stdout):
    print(f"""\
Usage: {sys.argv[0]} DICES_SPEECHES/ INPUT.CSV...

Adds is_speech and speaker columns to a SEDES-like corpus CSV file from
a DICES speech database.
""", end="", file=file)

class LineNumberFormatError(Exception):
    pass

def parse_line_n(line_n):
    m = re.match(r'^(\d+)(.*)$', line_n, flags=re.ASCII)
    if not m:
        raise LineNumberFormatError(f"bad line number format: {line_n!r}")
    n, appendix = m.groups()
    n = int(n)
    return (n, appendix)

def sedes_key(row):
    try:
        book_n = int(row["book_n"])
    except ValueError:
        book_n = ""
    return (
        SEDES_WORK_ID_TO_DICES_WORK_ID[row["work"]],
        book_n,
        parse_line_n(row["line_n"]),
    )

SEDES_WORK_ID_TO_DICES_WORK_ID = {
    "Il.": 1,
    "Od.": 2,
    "Theog.": 15,
    "W.D.": 29,
    "Argon.": 3,
    "Dion.": 11,
    "Q.S.": 12,
    "Theoc.": 14,
    "Hom.Hymn": 24,
    "Callim.Hymn": 25,
}

opts, args = getopt.gnu_getopt(sys.argv[1:], "h", ("help",))
for o, _ in opts:
    if o in ("-h", "--help"):
        usage()
        sys.exit(0)
dices_path, input_path = args

dices_speeches = []
for filename in (
    "speeches_00_Iliad",
    "speeches_01_Odyssey",
    "speeches_02_Theogony",
    "speeches_03_Works_and_Days",
    "speeches_04_Apollonius",
    "speeches_12_Nonnus",
    "speeches_13_Quintus",
    "speeches_17_Theocritus,_Idylls",
    "speeches_24_Homeric_Hymns",
    "speeches_25_Callimachean_Hymns",
):
    for _, row in pd.read_csv(os.path.join(dices_path, filename), sep = '\t', na_filter = False).iterrows():
        try:
            begin = (
                row["work_id"],
                row["from_book"],
                parse_line_n(str(row["from_line"])),
            )
        except LineNumberFormatError:
            print(f"warning: ignoring from_line {row['from_line']!r} in {filename}", file = sys.stderr)
            continue
        end = (
            row["work_id"],
            row["to_book"],
            parse_line_n(str(row["to_line"])),
        )
        dices_speeches.append((begin, end, row["speaker"]))
dices_speeches.sort(key = lambda x: (x[0], x[1]))

def dices_lookup(row):
    try:
        k = sedes_key(row)
    except KeyError:
        return None
    speaker = []
    for begin, end, dices_speaker in dices_speeches:
        if begin <= k <= end:
            speaker.append(dices_speaker)
    if not speaker:
        speaker = ["narrator"]
    return ">".join(speaker)

data = pd.read_csv(input_path, na_filter = False, dtype = str)
data["speaker"] = data.apply(lambda row: dices_lookup(row), axis = 1)
data["is_speech"] = data["speaker"].map(lambda s: "No" if s == "narrator" else "Yes", na_action = "ignore")
data.to_csv(sys.stdout, index = False)
