# tarot-cli

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

## running tests

```bash
bundle exec rake test
```

The automated tests use fake runners and fake HTTP responses. They do not
download or start the local model.

## generating coverage reports

Coverage reporting is planned for a later PR.

## list of main features

- Interactive command-line interface
- Help and usage statement
- Start a reading with a non-blank question
- Draw random cards without duplicates in the active reading
- Display an updated local Qwen interpretation after every card is drawn
- Shuffle all cards back into the deck and return to the main menu
- Clean exit with `exit`, `quit`, or end-of-input

## known limitations

- Save, Review, and card details are not implemented yet.
- Interpretation requires `ggml-org/Qwen3.5-0.8B-GGUF` at `http://127.0.0.1:8080`.

## team member names
- Ian Beckett
- Han-Ju Chen

## AI Citations
- [Card descriptions](https://github.com/ianebeckett/csce-606-project-1/blob/draw-one-card/lib/data/cards.json) generated with Grok (xAI).
