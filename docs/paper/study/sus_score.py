"""Compute SUS scores from a CSV of real responses.

CSV format (header required), one row per participant, items 1-5 scored 1..5:

    participant,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10

Usage:  python sus_score.py responses.csv
"""
import csv
import statistics
import sys


def sus(row):
    total = 0
    for i in range(1, 11):
        v = int(row[f'q{i}'])
        if not 1 <= v <= 5:
            raise ValueError(f'q{i} must be 1..5, got {v}')
        total += (v - 1) if i % 2 == 1 else (5 - v)
    return total * 2.5


def main(path):
    with open(path, newline='', encoding='utf8') as f:
        scores = [sus(r) for r in csv.DictReader(f)]
    n = len(scores)
    if n == 0:
        sys.exit('no rows')
    mean = statistics.mean(scores)
    sd = statistics.stdev(scores) if n > 1 else 0.0
    print(f'n={n}  mean SUS={mean:.1f}  SD={sd:.1f}  min={min(scores)}  max={max(scores)}')
    print('Common reading: >=68 is above average (Sauro & Lewis benchmark).')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
