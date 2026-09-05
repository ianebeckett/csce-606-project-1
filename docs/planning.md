# planning sessions

5 Sep 2026

## AI Plan
Using local Qwen for interpretation instead of OpenAI API to avoid external dependencies during grading.

## Definition of Done
- Features are fully implemented and tested.
- Code is reviewed by a peer and merged.
- CI passes (GitHub Actions test suite runs green).
- No technical debt is left unaddressed in that PR.

2 Sep 2026

## ideas
- Q&A: ask the user to submit a question/purpose before they draw. Save the
question and use it
- deck shuffle
- save timesteamp
- use an LLM API
- save session

## work completed
- updated project proposal features with broader scope and improved end-to-end tests
- Added features to proposal: Shuffle, Q&A integrated with LLM chat API, etc.
- Save timestamp when saving session
- split work into small PRs

## notes
- integration with chat API requires internet
- discussed need to create cooperation and planning documents
- use one JSON file and keep code simple
- wait for approval before coding

## proposal
- Team: Han-Ju Chen, Ian Beckett
- App: tarot-cli
- Description: A terminal tarot deck for drawing cards and saving readings.
- User: Programmers and computer enthusiasts interested in tarot.
- Core: Draw, Shuffle, Save, Review
- Stretch: Describe \<card\>, View \<card\>
- Classes: Main/Game, Deck, Card (?)

## tests
- Draw: card is valid; deck has one fewer card.
- Shuffle: all cards return and the deck shuffles.
- Save: file exists; card order is preserved.
- Review: all saved sessions appear.
- Describe: correct description appears.
- View: correct ASCII art appears.
- Timestamp: save time is written.
- Q&A: ask a question and display an LLM interpretation.
- E2E: question -> draw 3 -> view -> describe -> interpret -> save -> review.
- E2E: save -> restart -> review still shows the session.

## PRs
- PR 1: docs and approval
- PR 2: CLI and tests
- PR 3: Draw and Shuffle
- PR 4: Question and Timestamp
- PR 5: Save and Load
- PR 6: Review
- PR 7: Frequency
- PR 8: LLM Q&A
- PR 9: E2E, coverage, README
- PR 10: Describe (stretch)
- PR 11: View (stretch)

## implementation
- Main/Game, Deck, Reading, ReadingStore
- save to `readings.json`
- use `OPENAI_API_KEY`
- use fake time, random, files, and API in tests
