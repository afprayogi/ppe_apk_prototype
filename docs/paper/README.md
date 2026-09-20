# Paper draft — Ahmad Fauzan Prayogi (sole author)

| File | What it is |
| --- | --- |
| [`GearGuard-paper-en.pdf`](GearGuard-paper-en.pdf) | English draft (3 pages, IEEE-style two column) |
| [`GearGuard-paper-id.pdf`](GearGuard-paper-id.pdf) | Draf Bahasa Indonesia |
| `main.tex` + `refs.bib` | IEEEtran LaTeX source (`pdflatex → bibtex → pdflatex ×2`, or Overleaf) |
| `build/*.html` | Source of the two PDFs above |
| `study/` | SUS questionnaire (EN/ID), study protocol and `sus_score.py` for your real responses |

## What is filled in (real, checked)

- Author name; single-author statement and generative-AI disclosure.
- Compliance model, architecture, implementation numbers (32 files, ~4.9k lines, 7 tests, analyzer status) — all measured from this repo.
- Facts about your earlier prototype, taken from its repository: YOLOv8-format model, TFLite/ONNX (~18 MB), six classes, 640×640 input, confidence 0.25, NMS IoU 0.45, 11 validation photos.
- **Related work with six references, all 2021 or newer** (5-year window), each checked against its publisher/repository page: Wang et al. 2021 (*Sensors*), Karlsson et al. 2022 (arXiv), YOLOv7 (CVPR 2023), Ultralytics YOLOv8 (2023), Ordrick et al. 2025 (*JISI*), Hyzy et al. 2022 (*JMIR mHealth*).

## What is still open (marked in red in the PDFs)

| Item | Why it is not filled |
| --- | --- |
| Affiliation, email, funding | Only you know them. |
| **Detector benchmark** (precision / recall / mAP, latency) | Needs the trained model, a labelled test set and a device. The 11 validation photos in your old repo have no ground-truth labels, so they can support a qualitative check but not mAP. The app in this repo still ships a simulated detector, so no accuracy is claimed. |
| **Usability study (SUS, task times)** | Needs real participants. Use `study/sus_questionnaire.md` and `study/sus_score.py`. Inventing numbers is not an option for a paper. |

Also confirm your target venue's page limit, template, language, similarity
limit, AI-disclosure policy and — for SINTA — the journal's current
accreditation on sinta.kemdiktisaintek.go.id.
