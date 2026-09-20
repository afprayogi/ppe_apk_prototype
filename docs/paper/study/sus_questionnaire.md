# System Usability Scale (SUS) — GearGuard

Score each statement 1 (strongly disagree) … 5 (strongly agree).
Source: J. Brooke, "SUS: A 'quick and dirty' usability scale," 1996.

| # | English | Bahasa Indonesia |
|---|---|---|
| 1 | I think that I would like to use this system frequently. | Saya rasa saya akan sering menggunakan aplikasi ini. |
| 2 | I found the system unnecessarily complex. | Saya menemukan aplikasi ini terlalu rumit tanpa perlu. |
| 3 | I thought the system was easy to use. | Saya rasa aplikasi ini mudah digunakan. |
| 4 | I think that I would need the support of a technical person to be able to use this system. | Saya rasa saya membutuhkan bantuan orang teknis untuk dapat menggunakan aplikasi ini. |
| 5 | I found the various functions in this system were well integrated. | Saya menemukan fungsi-fungsi dalam aplikasi ini terintegrasi dengan baik. |
| 6 | I thought there was too much inconsistency in this system. | Saya rasa terlalu banyak ketidakkonsistenan dalam aplikasi ini. |
| 7 | I would imagine that most people would learn to use this system very quickly. | Saya membayangkan kebanyakan orang akan belajar menggunakan aplikasi ini dengan sangat cepat. |
| 8 | I found the system very cumbersome to use. | Saya menemukan aplikasi ini sangat merepotkan untuk digunakan. |
| 9 | I felt very confident using the system. | Saya merasa sangat percaya diri menggunakan aplikasi ini. |
| 10 | I needed to learn a lot of things before I could get going with this system. | Saya perlu mempelajari banyak hal sebelum dapat mulai menggunakan aplikasi ini. |

## Scoring
Odd items: score − 1. Even items: 5 − score. Sum × 2.5 → 0–100.
Run `python sus_score.py responses.csv` (see that file).

# Study protocol (fill in and run before reporting anything)

- **Participants:** n = ___ (supervisors / K3 officers / students acting as supervisors). Record role and experience. Informed consent; no personal data beyond role.
- **Build:** GearGuard production build; state clearly whether the detector is simulated or the real YOLO model.
- **Tasks (think-aloud optional):**
  1. Scan a worker and save the result.
  2. Find who has a PPE violation today.
  3. Add a new employee and scan them.
  4. Export a PDF report for the archive.
- **Measures per task:** success (0/1), time in seconds, errors/wrong taps.
- **After tasks:** SUS (above), one open question: "What was most confusing?"
- **Baseline (optional):** the same task list on a paper checklist.
- **Ethics:** obtain approval or an exemption statement from your institution.
