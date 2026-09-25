# backlog

## To Do

### Planning and Design

### Pair Programming
- Perform two (2) more pair programming sessions with alternating roles (3-4 of 4 required). Document in docs/pairing_log.md. Session 3 is complete; Session 4 remains.

### Essential Features - Implementation

### Final Deliverables
- finalize docs/design.md

## In Progress
- Add and test upright meanings for all 78 cards (#23)
- Implement `describe <card>` by drawn card name and update documentation (#23)

## Done
- View card ASCII art (#24, PR #72)
- write tests for load session
- implement load session, allowing tests to inject other filepaths
- implement save session with timestamp (#15)
- implement test coverage reports (#25, PR #58)
- add integration tests for ReadingStore and QwenRunner, reaching 100% and 94% line coverage,
  respectively, in the isolated integration suite
- repair runner forwarding after the Save/Qwen merge and isolate save tests from the model server
- implement save session with timestamp (#15, #16), including empty-reading rejection
  and recoverable save errors
- write unit and CLI acceptance tests for saving, ordered cards, failed saves, and restart persistence
- write tests for deck
- write tests for card draw
- Clarify the readings.json schema
- write database/JSON schema for session
- Add Architecture diagram or brief module explanation in docs/design.md (currently minimal)
- design UI for session
- implement usage statement
- write tests for usage statement
- implement deck
- implement card draw
- implement and test Shuffle (#14)
- Write the local Qwen runner API contract (#18; merged in PR #56)
- Write fake-runner tests for per-draw Q&A timing, cumulative inputs, output, and failure (#18; CI passed in PR #56)
- Implement Q&A with the required local Qwen model (#18; merged in PR #56)
- Document how to start the required local Qwen server (#18; merged in PR #56)
- Define features and scope for project approval (Completed - see PR #33)
- align user stories and acceptance criteria in docs/user_stories.md
- Setup GitHub Actions for running tests
- perform one (1) planning session and document in docs/planning.md
- plan scope to get project approval
- populate the backlog (this document)
- propose some initial features with appropriate scope
- decide on a project idea
- create docs
- create repository
- Perform first (1 of 4) pair programming session with alternating roles and document in docs/pairing_log.md
- Perform one (1) additional pair programming session with alternating roles (2 of 4 required). Document in docs/pairing_log.md
- perform and document end project retrospective (#42)
- Add CLI foundation and tests (PR #3)
- Add GitHub Actions for CI (PR #4)
- Remove redundant comments per code review (PR #5)
- Align user stories with approved scope (PR #33)
- Add story points to each story or feature
