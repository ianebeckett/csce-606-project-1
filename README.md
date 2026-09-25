# tarot-cli

A terminal tarot app for drawing cards and receiving local Qwen interpretations.

## installation/setup instructions

Before starting `tarot-cli`, install Ruby 4.0.1, `llama.cpp`, and the project
dependencies. On macOS with Homebrew, run the following commands from the
repository directory:

```bash
brew install llama.cpp
bundle install
```

For other platforms, follow the official
[`llama.cpp` installation guide](https://github.com/ggml-org/llama.cpp/blob/master/docs/install.md),
then run `bundle install` from the repository directory.

After installation, run the required local model server in a separate terminal:

```bash
llama serve -hf ggml-org/Qwen3.5-0.8B-GGUF
```

Wait until the server reports that it is listening before drawing any cards.

## running the app

Start the interactive CLI:

```bash
bundle exec ruby bin/tarot
```

Display the usage statement without starting an interactive session:

```bash
bundle exec ruby bin/tarot --help
```

### saving, reviewing, and loading readings

Start a reading with `new`, enter a question, and use `draw` one to three times.
Then type `save` to append the reading to `readings.json` in the directory where
you launched the app and return to the main menu.

The file keeps earlier readings across app restarts. Each entry includes an integer
`ID`, an ISO 8601 UTC `saved_at` timestamp, the question, card names in draw order,
and the latest available interpretation (an empty string if interpretation failed). See
[`docs/design.md`](docs/design.md#save-file) for the JSON format.

Saving an empty reading is rejected. If saving fails, the app reports the error and
keeps the current reading so you can continue or retry. Invalid existing history is
preserved rather than overwritten.

At the main menu, type `review` to display every saved reading in reverse
chronological order, with the most recent reading first,
including its question, timestamp, cards, and latest interpretation. A missing or
empty history reports `No saved readings found.`; malformed history reports an error
without crashing.

At the main menu, type `load`, then enter one of the displayed reading IDs.
The app restores and displays the question, cards in their original order, and
saved interpretation without contacting the model. You can continue drawing up
to three cards total, view a restored card, save another snapshot, or shuffle
to return to the menu. Saving the continued reading keeps the original snapshot.
A blank selection cancels loading. Missing history, invalid IDs, and load errors
leave the main menu available.

### viewing a card

After drawing a card, type `view <card>` with that card's name. For example,
if you drew The Fool, use `view The Fool`. Names are matched without regard to
letter case. An undrawn or invalid card displays an error and keeps the
reading active.

### describing a card

After drawing a card, type `describe <card>` with its name to display its
visual description and upright meaning. For example, use `describe The Fool`
after drawing The Fool.
Names are matched without regard to letter case. Missing, unknown, undrawn,
and numeric selections are rejected without ending the reading.

## running tests

```bash
bundle exec rake test
```

The automated tests use fake runners and fake HTTP responses. They do not
download or start the local model.

## generating coverage reports

Run `bundle exec rake test`. SimpleCov writes the report to `coverage/index.html`.
View the report by opening the file with a web browser.

## list of main features

- Interactive command-line interface
- Help and usage statement
- Start a reading with a non-blank question
- Draw random cards without duplicates in the active reading
- Display an updated local Qwen interpretation after every card is drawn
- Shuffle all cards back into the deck and return to the main menu
- Save readings to JSON with ordered cards, timestamps, and persistent history
- Load a saved reading by ID and continue from its saved state
- View a drawn card's illustration by name
- Describe a drawn card's imagery and upright meaning by name
- Clean exit with `exit`, `quit`, or end-of-input

## known limitations

- Reversed card meanings are not supported.
- Card illustrations contain Unicode characters and require a UTF-8 terminal.
- `help`, `exit`, and `quit` are treated as question text at the question prompt
  and ignored during an active reading ([#64](https://github.com/ianebeckett/csce-606-project-1/issues/64),
  [#65](https://github.com/ianebeckett/csce-606-project-1/issues/65)). During a reading,
  use `save` after drawing to keep it, or `shuffle` to discard it and return to
  the main menu. End-of-input also exits without saving.
- Interpretation requires `ggml-org/Qwen3.5-0.8B-GGUF` at `http://127.0.0.1:8080`.

## team member names
- Ian Beckett
- Han-Ju Chen

## AI Citations
- [Card descriptions](https://github.com/ianebeckett/csce-606-project-1/blob/draw-one-card/lib/data/cards.json) generated with Grok (xAI).

## Card art source

The 78 upright card illustrations in `lib/data/cards.json` come from
[`lawreka/ascii-tarot`](https://github.com/lawreka/ascii-tarot/blob/c951f8e0ba3b03b670d8f97ae7ad660531f5ccaf/bin/cards.js).
They are used under the MIT License in [`docs/ascii-tarot-LICENSE.txt`](docs/ascii-tarot-LICENSE.txt).

## Card meaning source

The 78 upright card meanings in `lib/data/cards.json` come from the
[CC0 tarot card dataset](https://github.com/smallcat419/tarot-card-data/tree/b40718b33ea9de3a89dc65fc0e2c9a9a605e409e).
