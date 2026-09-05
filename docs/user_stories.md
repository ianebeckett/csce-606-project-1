# User Stories

## Usage guidance

The following guidance supports the app but is not one of the eight graded stories.

As a user I want to be shown usage instructions so I can effectively use the application.

**Acceptance Criteria**

Given the user is navigating the application,
When they type the help command (e.g., help or -h),
Then the terminal must display a clear list of available commands and how to use them.

## Essential

### 1. Draw one card per command (#13)

As a user I want to draw one random, unique card per command so that I can do a tarot reading.

**Acceptance Criteria**

Given the deck is shuffled and a non-blank question has been entered,
When the user executes the draw command,
Then the system must randomly select one card from the deck,
And all drawn cards must be unique,
And the terminal must display the name of the drawn card,
And a fourth draw must be rejected until the deck is shuffled.

### 2. Shuffle and start another reading (#14)

As a user I want to shuffle the deck and clear my drawn cards so I can do another reading.

**Acceptance Criteria**

Given the user has already drawn cards,
When the user executes the shuffle command,
Then the active drawn cards must be cleared from the screen,
And all 78 cards must be returned to the deck pool and randomized,
And the prior question and interpretation must be cleared so a new question is required.

### 3. Review saved readings (#17)

As a repeat user I want to review my saved readings so that I can ponder their meanings.

**Acceptance Criteria**

Given the user has previously saved readings in the system,
When they execute the history/review command,
Then the terminal must display a chronological list of all past readings,
showing the question, cards in draw order, save time, and available interpretation for each session.

Given the user is viewing their saved readings history,
Then each entry must explicitly display the date and time (e.g., YYYY-MM-DD HH:MM) of
when that specific reading was saved.

### 4. Save a reading (#15)

As a user I want to save my drawn cards so I can review the same reading later.

**Acceptance Criteria**

Given the user has entered a non-blank question and drawn at least one card,
When they execute the save command,
Then the question, cards in draw order, timestamp, and available interpretation must be saved,
And the reading must remain available after the application restarts.

When saving fails,
Then the system must display a clear error message without crashing.

### 5. Ask a question and receive an interpretation (#18)

As a user I want an interpretation based on my question and three cards so that the reading addresses my intent.

**Acceptance Criteria**

Given the user must enter a non-blank question before drawing,
When the third card is drawn,
Then the local Qwen runner must receive the question and three cards in draw order once,
And the terminal must display the interpretation.

When the local model fails,
Then the system must display a clear error message without crashing.

## Optional

### 6. View card ASCII art (#24)

As a user I want to view ASCII art of the cards so that I can visualize them.

**Acceptance Criteria**

Given a card has been drawn or selected,
When the user requests to see the art for that card,
Then the terminal must render the visual representation (e.g., ASCII art or a
text-based layout wrapper) associated with that specific card.

When the user requests the art for an invalid card identifier,
Then the system must reject the input,
And display an error message stating: "Could not display art. Invalid card selection."

### 7. Describe a card (#23)

As a user I want to read detailed descriptions of the cards so that I can
consider their meanings.

**Acceptance Criteria**

Given a card has been drawn or selected,
When the user requests the details/meaning of that card,
Then the terminal must print a comprehensive text description of its
traditional tarot interpretation.

When the user requests details for a card index or name that does not exist in
the deck (e.g., entering 99 or typing The King of Potatoes),
Then the system must reject the input,
And display an error message stating e.g., "Invalid card selection. Please
select a valid card."

## Essential Sad Path

### 8. Prevent saving an empty reading (#16)

As a user I want to be prevented from saving empty readings so I can
keep my record tidy.

**Acceptance Criteria**

Given the user has initialized the app but has not drawn any cards yet,
When they attempt to execute the save command,
Then the system must block the save action,
And display an error message stating e.g., "Cannot save an empty reading. Please
draw cards first."

## Additional Sad-Path Acceptance Criteria

### Review

Given the user has never saved a reading (or the history file is empty),
When they execute the history/review command,
Then the system must display an informational message stating e.g., "No saved
readings found."

When the saved-reading data is malformed,
Then the system must display a clear error message without crashing.
