"""Summarise coverage/lcov.info (line coverage) per top-level lib/ folder."""
import collections
import sys

path = sys.argv[1] if len(sys.argv) > 1 else 'coverage/lcov.info'
tot, hit = collections.Counter(), collections.Counter()
cur = None
for raw in open(path, encoding='utf8'):
    line = raw.strip()
    if line.startswith('SF:'):
        cur = line[3:].replace(chr(92), '/')
    elif line.startswith('DA:'):
        count = int(line[3:].split(',')[1])
        parts = cur.split('/')
        top = parts[parts.index('lib') + 1] if 'lib' in parts else cur
        tot[top] += 1
        hit[top] += count > 0
total, covered = sum(tot.values()), sum(hit.values())
print(f'TOTAL {covered}/{total} = {100 * covered / total:.1f}%')
for k in sorted(tot):
    print(f'{k:12s} {hit[k]:5d}/{tot[k]:5d} = {100 * hit[k] / tot[k]:5.1f}%')
