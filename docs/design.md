# Design

The document will evolve with implementation and does not block unrelated coding.

## System architecture: major classes/modules, their responsibilities and interactions

### classes

- CLI
    - owns the main-menu loop, shared runner, and save-file path
    - prompts for a non-blank question and creates each Session
    - renders Review history sorted by `saved_at`, newest first
    - lists saved IDs for Load and starts a restored Session after selection

- Session
    - displays the active reading and handles its command loop
    - holds the active question and interpretation
    - requests one updated interpretation after every successful draw
    - clears active reading state and returns to the main menu after Shuffle
    - delegates saving to ReadingStore and restores the saved question, cards, and interpretation
    - handles user commands

- ReadingStore
    - appends reading snapshots to `readings.json`
    - assigns integer IDs and ISO 8601 save times
    - checks existing history before replacing it with a complete updated file
    - reports storage errors to Session, which keeps the active reading available
    - retrieves a saved snapshot by ID without changing the history file

- Deck
    - handles "shuffling" the deck
    - draws a random card when requested by the user
    - tracks which cards have been drawn and in what order
    - ensures that the same card is not drawn twice at the same time
    - finds a drawn card by name for `view <card>` and `describe <card>`
    - restores ordered card names to deck objects, excluding them from future draws

- Card
    - holds the card ID, name, description, and terminal illustration from `cards.json`
    - joins the selected card's illustration lines for terminal output

- QwenRunner
    - formats the question and all currently drawn cards in draw order
    - verifies the loaded model, then sends one interpretation request
    - returns the interpretation or a clear runner error

### dataflow diagram
```text
==================================================================================
         +────────────────────────────────────────────────────────────────────────+
         │                         USER TERMINAL                                  │
         +────────────────────────────────────────────────────────────────────────+
                                                                           ^   │
+─────────────────────────+              draw card                         │   │
│          DECK           │<───────────────────────────────────────────+   │   │
│  - draws cards          │─────────────────────────────────────────+  │   │   │
│  - tracks drawn cards   │              show spread                │  │   │   │
│  - handles shuffle      │                                         │  │   │   │
+─────────────────────────+                                         │  │   │   │
            ^                                                       v  │   │   v
            │               +─────────────────────+         +─────────────────────+
            │               │    ReadingStore     │         │        SESSION      │
            │               │  (readings.json)    │<────────│  - holds user state │
+─────────────────────────+ +─────────────────────+  save   │ - queries runner    │
│           CARD          │                                 │  - renders the UI   │
│ - id, name, description │                                 │                     │
+─────────────────────────+                                 +─────────────────────+
           ^                                                          ^  │
           │                                                          │  │
+─────────────────────────+                                 interpret │  │ query
│        cards.json       │                                           │  │
+─────────────────────────+                                           │  v
                                                        +─────────────────────────+
                                                        │       QWEN RUNNER       │
                                                        │ - takes question and   │
                                                        │   ordered cards        │
                                                        +─────────────────────────+
==================================================================================
```

The View path is `view <card>` -> `Session` -> `Deck.find_drawn_card` ->
`Card.ascii_art` -> terminal. The illustration is stored with the card in
`cards.json`; no image download or model call occurs when viewing it.
Describe follows `describe <card>` -> `Session` -> `Deck.find_drawn_card` ->
`Card.description` -> terminal. It also uses only cards drawn in the active reading.

The CLI owns the main menu, runner, and save path. Load follows this path:

```text
User -> CLI -> ReadingStore.readings -> display saved IDs and prompt
           -> ReadingStore.load(ID) -> saved snapshot from readings.json
           -> Session.from_reading -> Deck.restore(ordered card names)
           -> Session.display_reading -> Session.run -> draw / view / save / shuffle
```

Load matches the saved ID rather than its position in history. The restored deck
uses the original card objects, including descriptions and art, so subsequent
draws exclude those cards and the three-card limit still applies. The saved
interpretation is displayed without a model request; the next successful draw
requests an updated interpretation using the entire ordered spread.

Load never rewrites history. Saving a continued session appends a new snapshot
with a new ID and save time; the original timestamp remains with its snapshot.
Missing history, invalid IDs, and read failures return to the menu. A blank
selection cancels; end-of-input exits. Before creating a Session, restoration
rejects unknown or duplicate cards, a blank question, or a spread outside one
to three cards so unusable data cannot become an active reading.

### local Qwen runner contract

The user starts the required server in a separate terminal with this exact
command:

```bash
llama serve -hf ggml-org/Qwen3.5-0.8B-GGUF
```

After every successful draw, `Session` calls `QwenRunner` exactly once with the
question and a snapshot of all cards drawn so far. A blank-question attempt or
rejected fourth draw does not call the runner. The runner first checks
`http://127.0.0.1:8080/v1/models` and rejects a server that did not load
`ggml-org/Qwen3.5-0.8B-GGUF`. It then sends one non-streaming JSON request to
`http://127.0.0.1:8080/v1/chat/completions`. The request contains the user's
question and a numbered list of the currently drawn cards, including their
names and descriptions, in draw order. The runner returns
`choices[0].message.content`; `Session` stores and displays it as the current
spread's interpretation.
Thinking output is disabled so the token budget is used for the displayed
interpretation rather than hidden `reasoning_content`.

A connection error, non-success HTTP response, invalid JSON response, or blank
interpretation is a runner failure. `Session` clears the prior interpretation,
displays the error, and keeps the reading active without retrying the same draw
or crashing. A later successful draw starts one new interpretation request.

### save file

The implemented save flow separates session commands from file I/O:

```text
User -> CLI -> Session --question, ordered card names, interpretation--> ReadingStore
                  |                                                        |
                  +--> Deck.drawn_cards --> Card.name                       v
                                                                     readings.json
```

#### format
```json
{
  "readings": [
    {
      "ID": 1,
      "saved_at": "2026-09-13T12:00:00Z",
      "question": "What should I focus on?",
      "cards": ["The Tower", "Three of Wands", "The World"],
      "interpretation": ""
    }
  ]
}
```

- `ID` is an integer starting at 1. New saves use the highest existing ID plus 1.
- `saved_at` is the UTC save time as an ISO 8601 string.
- Review sorts validated `saved_at` timestamps in descending order, so the most
  recently saved reading appears first even if the JSON array is not ordered.
- `question` and `interpretation` are strings. An unavailable interpretation is `""`.
- `cards` contains card names as strings, in draw order.
- The default file is `readings.json` in the directory where the app is launched.
  `CLI` and `Session` accept `save_path:` for an alternate destination, including tests.
- Each save appends a snapshot to the existing `readings` array, including after a restart.
  A missing file starts a new history; an existing `{"readings": []}` is also valid.
- The updated JSON is written to a temporary file in the same directory, flushed,
  and renamed over the destination only when complete.
- A successful save returns to the main menu. A failed save preserves the active
  question, cards, and interpretation so the user can continue or retry.

#### sad paths
- save fails: notify the user without crashing, then allow more commands
- save without a question or any drawn cards: reject the save without creating a file
- existing save file is blank, malformed, or has invalid field types or duplicate IDs:
  report a save error and leave the file unchanged
- load missing file: notify the user without crashing, then allow more commands
- blank file or load missing save: notify the user without crashing, then allow more commands

## User interface design: mock-ups, expected interactions/workflows

The mock-ups show the intended full workflow. In-session exit is not
implemented in the current checkout; see the README for commands the grader
can run now.

### example UI: main menu
```
==================================================================================
========================================================================
                     TAROT CLI v1.0
========================================================================
Welcome.

Available Commands:
  [new]     Start a new session
  [review]  Review past sessions
  [help]    Show usage guidance
  [exit]    Close the application

> review
[!] No saved sessions found. Please start a new session first.

> help
Usage Guidance:
  - Type 'new' to set an intention and begin drawing up to 3 cards.
  - Type 'describe [card_name]' during a session to read its description.
  - Type 'shuffle' during a session to clear the current state.

>
==================================================================================
```

### example UI: starting a new session and drawing cards
```
==================================================================================
> new
Enter your intention or question for this session:
> Will my upcoming software launch go smoothly?

[Session Initialized]
------------------------------------------------------------------------
Current Spread:
------------------------------------------------------------------------

Available Commands: [draw], [view <drawn card>], [describe <drawn card>], [save], [shuffle], [help], [exit]

> draw

Drawing card...
------------------------------------------------------------------------
Current Spread: [ The Tower ]
------------------------------------------------------------------------
INTERPRETATION:
The Tower points to disruption around your launch. Prepare for sudden changes
and use them to identify foundations that need to be rebuilt.

Available Commands: [draw], [view <drawn card>], [describe <drawn card>], [save], [shuffle], [help], [exit]

> view The Tower
The Tower
.-------------------.
|        XVI     /__|
|    <*^       /__´ |
|   <^ ( (   /_´   .|
|     (_)) /´    .  |
|      |     )  .  .|
|  .   |    (_). .  |
| .    |  (  |      |
|.     | (_) |      |
| . \/ |     |      |
|.  /  |     |\/    |
| -/\  |     | \    |
| O    |     | /\-  |
|  .   |     |   O  |
|     /\  /\ |      |
|    /\/\/\/\/\     |
|   /\/\/\/\/\/\    |
|-------------------|
|     The Tower     |
`-------------------´

> draw

Drawing card...
------------------------------------------------------------------------
Current Spread: [ The Tower ] -> [ Three of Wands ]
------------------------------------------------------------------------
INTERPRETATION:
The Tower's disruption is followed by the Three of Wands, suggesting that
careful planning and a wider view can turn early launch problems into progress.

Available Commands: [draw], [view <drawn card>], [describe <drawn card>], [save], [shuffle], [help], [exit]

> describe The Tower
The Tower
A tall stone tower is struck by a jagged bolt of lightning from a dark, stormy
sky. Flames burst from the upper windows and roof as two figures fall headlong
from the structure. A crown is toppled from the top of the tower. The background
is black and chaotic, filled with falling debris and fire.
==================================================================================
```

### example UI: third card interpretation
```
==================================================================================
> draw

Drawing card...
------------------------------------------------------------------------
Current Spread: [ The Tower ] -> [ Three of Wands ] -> [ The World ]
------------------------------------------------------------------------
INTERPRETATION:
Your journey begins with sudden, sharp technical disruptions (The Tower).
However, by looking outward and executing a structured expansion plan
(Three of Wands), your software project will achieve global success and
complete fulfillment (The World). The launch will be chaotic at first,
but an absolute victory in the end.
------------------------------------------------------------------------

Available Commands: [draw], [view <drawn card>], [describe <drawn card>], [save], [shuffle], [help], [exit]

> draw
[!] You have drawn the maximum limit of 3 cards.

Available Commands: [view <drawn card>], [describe <drawn card>], [save], [shuffle], [help], [exit]

> save
Session successfully saved to disk. Returning to Main Menu...

========================================================================
                     TAROT CLI v1.0
========================================================================
Welcome.

Available Commands:
  [new]     Start a new session
  [review]  Review past sessions
  [load]    Load a past session
  [help]    Show usage guidance
  [exit]    Close the application

>
==================================================================================
```

### example UI: mid-session Shuffle
```
=> new
Enter your intention or question for this session:
> Should I relocate to a new city?

[Session Initialized]
------------------------------------------------------------------------
Current Spread:
------------------------------------------------------------------------

Available Commands: [draw], [view <drawn card>], [describe <drawn card>], [save], [shuffle], [help], [exit]

> draw

Drawing card...
------------------------------------------------------------------------
Current Spread: [ Six of Swords ]
------------------------------------------------------------------------
INTERPRETATION:
The Six of Swords suggests that relocating may help you leave a difficult
situation and move toward calmer conditions.

> shuffle
Session cleared. All cards are available again. Returning to Main Menu...

========================================================================
                     TAROT CLI v1.0
========================================================================
Welcome.

Available Commands:
  [new]     Start a new session
  [review]  Review past sessions
  [load]    Load a past session
  [help]    Show usage guidance
  [exit]    Close the application

>
==================================================================================
```

### expected workflows
- User starts the application.
- User is greeted and prompted to load, review, or start a new session.
- If the user reviews a session, they will be shown the question, timestamp, cards drawn,
and the latest available interpretation for that session.
- If there is no session to load/review but the user attempts to load/review,
they will be shown a fallback message.
- During a session, the user may Shuffle to return every card to the deck, clear the active
question and interpretation, and return to the main menu. A new non-blank question is required
before the next draw.
- At any time, user can use the help command to get usage guidance
- The user may not review a session while they are currently in a session. They must
  Shuffle before they can review other sessions.
- When user starts a new session, they are prompted to submit an intention/question.
- After submitting their intention/question and drawing at least one card, the user may
  save the session. This follows stories #15 and #16; the earlier workflow allowed saving
  before drawing, which conflicted with the explicit empty-reading rejection criterion.
- When user has submitted their intention/question, they may start drawing cards.
- When user draws a card, they are shown the names of the cards they've drawn, in
order of earliest to latest, from left to right. The local Qwen runner is called
once with the question and all cards drawn so far, and the updated interpretation
is displayed.
- If user has drawn at least one card, they may request to see the description or art of any of the
drawn cards.
- After a draw, `view <card>` accepts the drawn card's name and prints its
  illustration. A missing, unknown, or undrawn selection reports an error and
  leaves the current reading active.
- After a draw, `describe <card>` accepts the drawn card's name and prints its
  description. Missing, unknown, undrawn, and numeric selections report an
  error without ending the reading.
- When the user draws their third card, the updated interpretation takes the question,
all three cards, and their order into context.
- If user has already drawn three cards, they will not be allowed to draw another card.
They will have the option to save, after which they will be brought back to the main menu.

## design decisions or tradeoffs

### design decision 1

#### motivation

We needed to decide where to store data about cards

#### solution 1

held in Deck

##### pros:
- keeps card data in memory and avoids separate disk I/O
- everything is done in source files, no need for extra asset files

##### cons:
- Violates single responsibility principle: Deck becomes both a database and state handler
- loading a big object full of static data when doing initialization every time is inefficient
- messy code structure: we would have over 70 rows of just static card data in Deck class

#### solution 2

stored in JSON file(s)

##### pros:
- the cards can easily be edited or added to directly without touching application source. (if there's a bug)

##### cons:
- more reads from disk
- need to write exception handling for cases with missing or corrupted cards.json

#### decision

We decided to go with solution 2:

- Cleaner implementation: `Deck` handles deck state instead of storing card definitions.
- Better maintainability: card data can change without editing application source.

#### test plan

an end-to-end test

### design decision 2

#### motivation

We needed to decide whether the status of which cards were drawn and how to
draw a random card would be tracked by the Deck or Session class.

#### solution 1

Session tracks state

##### pros:
- State management is easier.
Deck stays stateless since it just used to deliver cards to the Session, so we don't need to do one to one mapping for Deck and Session.
- We wouldn't need to use a getter method e.g. `d = Deck, d.getDrawnCards` to save,
making saving and loading simpler
- If deck were stateless, that would decouple the lifecycles of the Session and Deck
objects, potentially allowing us to extend the application by having multiple decks in
a sesssion.

##### cons:
- Violates single responsibility principle: Session will become a god object
- Harder to test features in isolation

#### solution 2

Deck tracks state

##### pros:
- Separation of concerns: Session handles workflow and LLM interaction, while deck handles
  drawing and shuffling cards
- lazy evaluation of cards allows us to only track drawn cards
- smaller class is easier for testing

##### cons:
- Session has to interact with `Deck` in order to save/load session or shuffle the deck

#### decision

We decided to go with solution 2. Since the user isn't concerned with the cards that
haven't been drawn, we don't need to do anything with them. By ensuring that cards are
drawn randomly and that each drawn card is unique, we can keep the program lightweight,
testable, and more extensible. Drawing a random card from the pool is mathematically
identical to shuffling the deck and drawing the top card. We should be able to handle
 the communication between Deck and Session by having methods in deck that can export and
import states to/from Session.

#### test plan

an end-to-end test

### design decision 3

#### motivation

To give the project a wider scope, we decided to add LLM integration that acts
as a fortune teller or tarot card interpreter for the user. This allows the user
to read the interpretations directly instead of studying the meanings of the
cards and how they relate to the question or intention they have in mind.

#### solution 1

Use a third-party API, such as OpenAI, to interpret the reading.

##### pros:
- Potentially more accurate because the available models may have more
  parameters.

##### cons:
- More expensive.
- Requires an internet connection.

#### solution 2

Use a free local LLM, such as a model from the Qwen family, to interpret the
reading.

##### pros:
- Less expensive.
- Can run without an internet connection after setup.

##### cons:
- May be less accurate because the model may have fewer parameters.

#### decision

We decided on solution 2 because it is easier to test without depending on a
paid external service, and the grader does not need to pay to evaluate the
project. The required runner is `QwenRunner`, which calls the OpenAI-compatible
HTTP endpoint started by
`llama serve -hf ggml-org/Qwen3.5-0.8B-GGUF`. `Session` injects the runner and
calls it once after every successful draw so model I/O remains separate from
reading state and command handling.

#### test plan

Automated tests inject a fake runner to verify one call per successful draw,
cumulative ordered inputs, terminal output, and failure handling. Separate unit
tests use fake HTTP responses to verify the request and response contract. They
do not start the model, test model feasibility, or evaluate answer quality.

### design decision 4

#### motivation

We need to decide whether to store tarot cards in one JSON file or in separate files.

#### solution 1

Store cards JSON in one file

##### pros:
- It's simpler to write application code to get an object from a JSON list than it is to
  dynamically build a filepath string and check for a file, handle errors, etc.
- easier to edit all cards at once --e.g. adding a field-- since
cards are all in one file.
- lower I/O overhead

##### cons:
- lots of text to look at in one file

#### solution 2

Store cards JSON in individual files

##### pros:
- more granular commit history when editing specific cards
- smaller amount of text to look at while editing

##### cons:
- drawing cards would involve dynamically building filepath strings. Overcomplicated.
- higher I/O overhead
- lots of small files

#### decision

We chose one JSON file because it avoids per-card paths and file checks.

#### test plan

an end-to-end test

### design decision 5

#### motivation

Returning users usually want to see their latest reading first. We had always
intended that behavior, but had not written it down explicitly until implementing
the Review feature.

#### solution 1

Display records in the order they appear in `readings.json`.

##### pros:
- preserves the file's original order

##### cons:
- does not guarantee that the newest timestamp appears first if records are reordered

#### solution 2

Sort valid records by their ISO 8601 `saved_at` timestamp in descending order before display.

##### pros:
- directly guarantees the most recent reading appears first
- keeps file storage order independent from presentation order

##### cons:
- requires timestamps to be valid ISO 8601 values

#### decision

Use solution 2. `ReadingStore` rejects timestamps that cannot be parsed, and the
CLI sorts valid timestamps newest first while leaving the stored JSON order unchanged.

#### test plan

The acceptance suite supplies readings whose file order differs from timestamp order
and verifies that Review displays the newer reading first. Unit coverage verifies that
an invalid timestamp is rejected as malformed history.

### View card art

Each card's terminal illustration is stored with its ID, name, and description
in the existing `cards.json`. This follows the one-file card-data decision and
lets `view <card>` work offline without another runtime dependency. The tradeoff
is a larger data file and a UTF-8 terminal requirement. `Deck` owns the drawn
cards, so `Session` looks up only the cards in the active reading before printing
an illustration. The art source and license are recorded in the README.

Card IDs remain internal identifiers for possible future decks or translated
names. `view <card>` accepts a drawn card's displayed name, ignoring letter case.
Numeric card IDs are not accepted: the interface does not present them before
selection, and their values do not identify a card meaningfully to the user.
The terminal output starts with the card name and does not show a numeric ID.

### Describe card description

`describe <card>` prints the existing `Card.description` for a drawn card
selected by name. The same description remains available to `QwenRunner`.
Describe does not accept the card's internal ID or request a new model
interpretation.
