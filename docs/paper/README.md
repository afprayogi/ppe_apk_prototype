# Paper — Ahmad Fauzan Prayogi (sole author)

| File | What it is |
| --- | --- |
| [`GearGuard-paper-en.pdf`](GearGuard-paper-en.pdf) | English paper (4 pages, IEEE-style two column) |
| [`GearGuard-paper-id.pdf`](GearGuard-paper-id.pdf) | Versi Bahasa Indonesia |
| `main.tex` + `refs.bib` | IEEEtran LaTeX source (`pdflatex → bibtex → pdflatex ×2`, or Overleaf) |
| `build/*.html` | Source of the two PDFs |
| `study/` | SUS questionnaire (EN/ID), protocol and `sus_score.py` for a real user study |
| [`../eval`](../eval) | Raw results: `results.json`, `summary.md`, `experiments.json`, `experiments.md` |
| [`../../tool/eval`](../../tool/eval) | Scripts that produced every number (`eval_yolo_tflite.py`, `experiments.py`, `coverage_summary.py`) |

## What the paper contains (all measured, 2026-09-20)

1. Compliance model (Eqs. 1–3), layered architecture, `PpeDetector` interface.
2. Detector smoke test: expected class found in **11/11** photos, ~80 ms/frame (desktop CPU).
3. Threshold sweep, robustness to 10 perturbations, 15 negative images, latency vs threads.
4. Software verification: **38 tests, 75.1 % line coverage**, 20 accessibility checks (three initially failed → fixed).
5. Related work with **7 references, all 2021 or newer**.

Honest findings the paper reports rather than hides: recall drops to 5/11 with a 25 % occlusion patch,
and plain orange/pink patches trigger a false *Vest*.

## What the paper does *not* claim

- **No accuracy / mAP.** The 11 photos have weak (file-name) labels and no boxes, and may overlap the model's training data.
- **No usability result.** No user study has been run; the paper says so (Section VI-G) and points to `study/`.
- **No phone latency.**

## Still yours to fill

| Item | Note |
| --- | --- |
| Affiliation and email | Red placeholders in the author block. |
| AI-use disclosure | Author statement discloses generative-AI assistance; confirm wording against the venue's policy. |
| Venue fit | Check template, page limit, language, similarity limit and, for SINTA, the journal's *current* accreditation. |

To turn this into a stronger submission: (1) run the SUS study with ≥10 supervisors/K3 staff,
(2) evaluate the model on an independent labelled test set with negatives and report mAP,
(3) measure latency on named phones. Each is a one-line swap in the tables — the scripts and protocol are ready.
