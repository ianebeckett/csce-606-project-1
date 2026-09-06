# Design

The document will evolve with implementation and does not block unrelated coding.

## System architecture: major classes/modules, their responsibilities and interactions

### classes

- Session
    - displays user interface (?)
    - holds the user's question and provides it to the LLM when needed
    - reads and writes from disk to save and load session states
    - handles user commands

- Deck
    - handles "shuffling" the deck
    - draws a random card when requested by the user
    - tracks which cards have been drawn and in what order
    - ensures that the same card is not drawn twice at the same time

- Card
    - holds data about the card, including name, suit, rank, art, details, etc.
    - has getters to allow Session to retreive data about the card

### dataflow diagram
```
==================================================================================
         +──────────────────────────────────────────────────────────────────────+
         |                              USER TERMINAL                           |
         +──────────────────────────────────────────────────────────────────────+
                                                                          ^   |
+────────────────────────+             1. requests random, unique ID/Key  |   |
|         DECK           | <──────────────────────────────────────────+   |   |
| - tracks drawn IDs     |                                            │   |   |
| - handles shuffle      | 2. returns unique ID (e.g., "the-tower")   │   |   |
+────────────────────────+                                            │   |   |
                                                                      v   |   v
                                                            +────────────────────+
                                                            |       SESSION      |
                                                            | - holds user state |
+────────────────────────+                                  | - queries LLM      |
|          CARD          | 3. fetches details by drawn ID   | - renders the UI   |
| - name, suit, rank, etc| ────────────────────────────────>|                    |
+────────────────────────+                                  +────────────────────+
           ^                                                         ^  |
           |                                                         |  |
+────────────────────────+                                           |  |
|       cards.json       |                                           |  |
+────────────────────────+                                           |  v
                                                        +────────────────────────+
                                                        |       LOCAL LLM        |
                                                        |     - takes question   |
                                                        |     - inteprets cards  |
                                                        +────────────────────────+
==================================================================================
```

## User interface design: mock-ups, expected interactions/workflows

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
  - Type 'details [card_name]' during a session to read about its symbolism.
  - Type 'reset' at any time to clear the current state.

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

Available Commands: [draw], [details <card>], [save], [reset], [help], [exit]

> draw

Drawing card...
------------------------------------------------------------------------
Current Spread: [ The Tower ]
------------------------------------------------------------------------
The Tower represents sudden upheaval and disruption. In the context of
your software launch, it warns of unexpected technical debt or critical
bugs crashing your production deployment. Prepare mitigation plans.

Available Commands: [draw], [details <card>], [save], [reset], [help], [exit]

> draw

Drawing card...
------------------------------------------------------------------------
Current Spread: [ The Tower ] -> [ Three of Wands ]
------------------------------------------------------------------------
The Three of Wands shifting after The Tower shows forward planning.
While your initial launch window experiences an outage, your team will
rapidly look out toward broader horizons, successfully deploying a stable
architecture immediately after the initial storm.

Available Commands: [draw], [details <card>], [save], [reset], [help], [exit]

> details The Tower
------------------------------------------------------------------------
CARD DETAILS: The Tower
Motifs: A lightning-struck fortress, crown falling, figures plunging.
Meaning: Fundamental breakdowns, sudden revelation, destruction of
         faulty foundations to make way for stable structures.
------------------------------------------------------------------------
==================================================================================
```

### example UI: third card and final interpretation
```
==================================================================================
> draw

Drawing card...
------------------------------------------------------------------------
Current Spread: [ The Tower ] -> [ Three of Wands ] -> [ The World ]
------------------------------------------------------------------------
The World signifies completion, triumph, and harmony. The immediate
hurdles of your launch yield an ultimately perfect deployment.

FINAL INTERPRETATION:
Your journey begins with sudden, sharp technical disruptions (The Tower).
However, by looking outward and executing a structured expansion plan
(Three of Wands), your software project will achieve global success and
complete fulfillment (The World). The launch will be chaotic at first,
but an absolute victory in the end.
------------------------------------------------------------------------

Available Commands: [draw], [details <card>], [save], [reset], [help], [exit]

> draw
[!] You have drawn the maximum limit of 3 cards.

Available Commands: [details <card>], [save], [reset], [help], [exit]

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

### example UI: mid-session reset
```
=> new
Enter your intention or question for this session:
> Should I relocate to a new city?

[Session Initialized]
------------------------------------------------------------------------
Current Spread:
------------------------------------------------------------------------

Available Commands: [draw], [details <card>], [save], [reset], [help], [exit]

> draw

Drawing card...
------------------------------------------------------------------------
Current Spread: [ Six of Swords ]
------------------------------------------------------------------------
The Six of Swords is a highly literal and encouraging sign for relocation. The
imagery of the ferryman carrying passengers away from a choppy past matches
your desire to move. It suggests that while leaving your current environment
might bring a tinge of sadness or nostalgia, the journey across the water is
essential for your mental peace. The destination promises much calmer, more
supportive conditions.

> reset
Are you sure you want to reset? Unsaved progress will be lost. (y/n): y
Session cleared. Returning to Main Menu...

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
- User starts the application.
- User is greeted and prompted to load, review, or start a new session.
- If the user reviews a session, they will be shown the question, timestamp, cards drawn,
and all 4 interpretation statements for that session.
- If there is no session to load/review but the user attempts to load/review,
they will be shown a fallback message.
- At any time, the user may shuffle/reset. If they have set an intention/question, they will
be asked if they would like to save the session before the session is reset:
"Are you sure you want to reset? Unsaved progress will be lost."
- At any time, user can use the help command to get usage guidance
- The user may not review a session while they are currently in a session. They must
shuffle/reset before they can review other sessions.
- When user starts a new session, they are prompted to submit an intention/question.
- At any time after submitting their intention/question, the user may save the session.
- When user has submitted their intention/question, they may start drawing cards.
- When user draws a card, they are shown the names of the cards they've drawn, in
order of earliest to latest, from left to right. They are also shown an
interpretation of the card as it relates to the question and the other cards
they've drawn this session.
- If user has drawn at least one card, they may request to see details or art of any of the
drawn cards.
- If the user requests to see details of one of the drawn cards, they will be shown a
statement explaining major motifs depicted on the card and their meanings independent of
the session and question.
- When the user draws their third card, they will be shown two interpretations: the standard
interpretation of that card as mentioned above, and a final, overarching interpretation
that takes the question and all three cards and their order into context.
- If user has already drawn three cards, they will not be allowed to draw another card.
They will have the option to save, after which they will be brought back to the main menu.

## design decisions or tradeoffs

### design decision 1 motivation

We needed to decide where to store data about cards

### solution 1

held in Deck

pros:
- no I/O dependency
- everything is done in source files, no need for extra asset files

cons:
- Violates single responsibility principle: Deck becomes both a database and state handler
- loading a big object full of static data when doing initialization every time is inefficient
- messy code structure: we would have over 70 rows of just static card data in Deck class

### solution 2

stored in JSON database

pros:
- easy serialization for saving/loading cards
- the cards can easily be edited or added to directly without touching application source.
- looks more clean

cons:
- more reads from disk
- need to write exception handling for cases with missing or corrupted cards.json

### decision

We decided to go with solution 2. Since these card properties are permanent and static,
there's no reason to bloat a dynamic object with that data. We can use Card as a DTO to
deliver card data to the rest of the application.

### test plan

an end-to-end test

### design decision 2 motivation

We needed to decide whether the status of which cards were drawn and how to
draw a random card would be tracked by the Deck or Session class.

### solution 1

Session tracks state

pros:
- Deck stays stateless and is just used to deliver cards to the Session
- All dynamic data lives in the session, making saving and loading simpler

cons:
- Violates single responsibility principle: Session will become a god object
- Harder to test features in isolation

### solution 2

Deck tracks state

pros:
- Separation of concerns: Session handles workflow and LLM interaction, while deck handles
  drawing and shuffling cards
- lazy evaluation of cards allows us to only track drawn cards
- easier testing

cons:
- Session has to interact with deck in order to save/load session or shuffle the deck

### decision

We decided to go with solution 2. Since the user isn't concerned with the cards that
haven't been drawn, we don't need to do anything with them. By ensuring that cards are
drawn randomly and that each drawn card is unique, we can keep the program lightweight,
testable, and more extensible. Drawing a random card from the pool is mathematically
identical to shuffling the deck and drawing the top card. We should be able to handle
 the communication between Deck and Session by having methods in deck that can export and
import states to/from Session.

### test plan

an end-to-end test

### design decision 3 motivation

In order to have a project with a wider scope, we decided to add LLM
integration to act as a fortune teller or tarot card interpreter for the user.
That way, the user could just read the interpretations instead of having to
study themselves the esoteric meanings of the cards and how they relate to the
question/intent they had in mind.

### solution 1

Use LLM functionality for divining the user's question/intent, drawing the
cards, and interpreting the meanings of the cards.

pros:
- cless source code requred on our end

cons:
- the LLM might make a mistake and draw the same card twice.
- the LLM might be influenced by the user's statement of intent to perform an action we
didn't intend.
- security: The LLM would be responsible for generating data that later gets saved to disk.
This seems risky.
- security: probably a greater risk of prompt injection

### solution 2

Use LLM functionality only for divining the user's question/intent based on the cards
drawn.

pros:
- more secure: there's less of a risk of prompt injection or saving unsafe data to disk
- deterministic control over the deck; we can ensure the same card isn't drawn twice

cons:
- need to implement the deck, card draw, etc. in the source code

### decision

We decided on solution 2: integrate LLM API functionality only for the feature
of taking the user's intention/question and using that for context to interpret
"divine" the meanings of the cards. This facilitates runnning a small model
locally so that we don't have to deal the networking issues of using e.g.
OpenAI API.

### test plan

an end-to-end test

