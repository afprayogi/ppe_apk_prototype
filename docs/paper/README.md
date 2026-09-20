# Paper draft

`main.tex` is an IEEE-conference-format manuscript (`IEEEtran`) describing
GearGuard's compliance model, architecture and implementation.

```sh
pdflatex main && bibtex main && pdflatex main && pdflatex main
```

Or upload the folder to Overleaf.

## Read this before submitting

The draft is **honest scaffolding, not a finished paper.** Sections marked in
red as `TODO` are missing on purpose:

| Missing | Why it matters |
| --- | --- |
| **Real detector + benchmark** (precision / recall / mAP, latency on named devices) | The app currently ships a *simulated* detector, so no accuracy can be claimed. IEEE venues and SINTA 1–2 journals expect measured results. |
| **Usability study** (task success/time, SUS, n, protocol, ethics statement) | This is the evidence for the interaction-design contribution. |
| **Related work** | Needs a proper, current survey of PPE detection and safety apps; only three verified-format references are included. |
| **Author / affiliation / funding** | Placeholders. |

Also check the current requirements of your target venue (page limit,
template, English vs. Indonesian, plagiarism-similarity limit, whether a
software/system paper is in scope) — SINTA ranks change, so confirm the
journal's current listing on sinta.kemdiktisaintek.go.id.

Every number that *is* in the draft (32 files, ~4.9k lines, 7 tests, analyzer
status) was measured from this repository.
