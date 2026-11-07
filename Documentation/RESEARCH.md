# Spaced repetition research and scheduling policy

Reviewed on November 4, 2026. The references include eight research papers or reviews and two primary algorithm descriptions. The research review used available abstracts and full text where accessible. The algorithm descriptions document implementation choices and provide no independent experimental validation.

## Sources

| Source | Application in this project |
| --- | --- |
| [Cepeda et al., 2006 — Distributed practice in verbal recall tasks](https://pubmed.ncbi.nlm.nih.gov/16719566/) | The meta-analysis supports distributing practice over time. Suitable spacing depends on the intended retention period. |
| [Cepeda et al., 2008 — Spacing Effects in Learning](https://doi.org/10.1111/j.1467-9280.2008.02209.x) | Both very short and very long intervals can underperform suitable spacing. Reviews follow due dates, with familiar cards returning when scheduled. |
| [Roediger & Karpicke, 2006 — Test-enhanced learning](https://pubmed.ncbi.nlm.nih.gov/16507066/) | Retrieval practice supports delayed retention. Learners enter an answer before seeing the correct forms. |
| [Karpicke & Roediger, 2008 — The Critical Importance of Retrieval for Learning](https://doi.org/10.1126/science.1152408) | Retrieval continues after the first successful answer through scheduled follow-up reviews. |
| [Dunlosky et al., 2013 — Improving Students’ Learning With Effective Learning Techniques](https://doi.org/10.1177/1529100612453266) | Practice testing and distributed practice have broad support. The reference table supplements active retrieval. |
| [Rawson & Dunlosky, 2011 — Optimizing schedules of retrieval practice](https://pubmed.ncbi.nlm.nih.gov/21707204/) | Relearning across spaced sessions supports long-term retention. Successes must occur on separate dates. The app uses its own review protocol. |
| [Kornell, 2009 — Optimising learning using flashcards](https://doi.org/10.1002/acp.1537) | Distributed flashcard practice outperformed massed practice. Short sessions are combined with scheduled retrieval. |
| [Pashler et al., 2005 — When does feedback facilitate learning of words?](https://pubmed.ncbi.nlm.nih.gov/15641900/) | Corrective feedback after an error can help learning. Forms and examples appear after checking, and assistance is tracked separately from later independent retrieval. |
| [Woźniak — Original SM-2 description](https://www.super-memory.com/english/ol/sm2.htm) | The scheduling baseline uses intervals of 1 and 6 days, then multiplies by an ease factor starting at 2.5, with a lower bound of 1.3. Failure resets the success streak. |
| [Anki — What spaced repetition algorithm does Anki use?](https://faqs.ankiweb.net/what-spaced-repetition-algorithm.html) | The documentation distinguishes modified SM-2 from FSRS. This app implements its own SM-2 adaptation, with fixed scheduling rules and no personalized model fitting. |

## Scheduling policy

The app implements a local SM-2 adaptation. Schedules are reconstructed from immutable answer history, so JSON exports carry the evidence needed to rebuild them. Each card covers an entire verb, including two principal parts and the auxiliary required by its context. This makes the retrieval unit larger than a minimal SM-2 item.

- An exact independent answer receives quality `q = 5`. Correct fields with at most one typo in each principal part receive `q = 4`. Any wrong or empty form, or an incorrect auxiliary, receives `q = 1`.
- Successful reviews use intervals of 1 day, 6 days, then `ceil(previous interval × previous ease factor)`. The ease factor follows the SM-2 formula with a minimum of 1.3. The app caps intervals at 365 days.
- Failure resets the success streak to zero and sets the next interval to 1 day. Explicit mistake practice is available immediately. Attempts following a revealed answer are marked as assisted.
- Only the first independent answer for a verb on a Berlin calendar day is eligible to affect scheduling. Assisted answers are excluded. An early success preserves the current streak and due date. An eligible early failure resets the streak.
- Ordinary sessions contain up to 10 cards, ordered by due mistakes, other due reviews with earlier dates first, then new verbs. Future cards and forms shown today are excluded from ordinary sessions. Sessions can be shorter than 10 cards. Explicit mistake practice permits early reviews.
- Calendar calculations use `Europe/Berlin` calendar days, including daylight-saving transitions.

## Progress stages

The stages are product heuristics for displaying practice history.

- 0% means there is no current streak of independent successes. A failed card is labelled Repeat.
- 25% means one success, 50% means two, and 75% means at least three, labelled Close to consolidation.
- 100%, labelled Consolidated, requires at least four consecutive successes, an exact final answer and an actual gap of at least 14 calendar days before that answer. Otherwise, the card stays at 75%.
- Overall progress averages the stages of all 60 verbs. Consolidated cards retain their next review date. These percentages describe practice stages and cannot establish recall probability, a CEFR level or permanent retention.

The four-success threshold, 14-day gap, displayed percentages, quality values, 365-day cap and early-review rules are application policy. The sources support retrieval practice and spacing in general. Their findings do not establish that these particular parameters are optimal for an individual learner. Personalized scheduling or FSRS could be evaluated after enough real review data becomes available.

## Compatibility with the web trainer

The original web trainer prioritizes mistakes, unchecked verbs and remaining verbs without due dates. The native app uses the schedule above for ordinary sessions. The package retains the older queue function for compatibility checks, and form grading matches the web version. The native app keeps its progress history separate from the web trainer and lesson databases.
