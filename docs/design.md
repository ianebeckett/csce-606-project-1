# Design

## System architecture: major classes/modules, their responsibilities and interactions

### classes

- Session
    - displays user interface (?)
    - holds the user's question and provides it to the LLM when needed
    - reads and writes from disk to save and load session states
    - handles shuffle/reset

- Deck
    - handles keeping the deck shuffled
    - draws a random card when requested by the user
    - tracks which cards have been drawn and in what order
    - ensures that the same card is not drawn twice at the same time

- Card
    - holds data about the card, including name, suit, rank, art, details, etc.
    - has getters to allow Session to retreive data about the card

## User interface design: mock-ups, expected interactions/workflows

User starts the application.
User can use the help command to get usage guidance
User is greeted and prompted to load, review, or start a new session

## design decisions or tradeoffs

### motivation

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

### motivation

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

