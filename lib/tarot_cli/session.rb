# frozen_string_literal: true

require_relative 'deck'
require_relative 'qwen_runner'
require_relative 'reading_store'

module TarotCLI
  class Session # rubocop:disable Metrics/ClassLength
    MAX_CARDS = 3

    LINE = <<~TEXT
      ------------------------------------------------------------------------
    TEXT

    AVAILABLE_COMMANDS = <<~TEXT
      Available Commands: [draw], [view <drawn card>], [describe <drawn card>], [save], [shuffle], [help], [exit]
    TEXT

    COMMAND_HANDLERS = {
      'draw' => :draw_card,
      'save' => :save, 'shuffle' => :shuffle,
      'help' => :show_usage,
      'new' => :non_session_command, 'review' => :non_session_command,
      'load' => :non_session_command,
      'exit' => :exit_with_statement, 'quit' => :exit_with_statement
    }.freeze

    attr_reader :question, :interpretation

    # Rebuild a playable reading without drawing new cards or requesting another interpretation.
    def self.from_reading(reading, runner: QwenRunner.new, save_path: ReadingStore::DEFAULT_PATH)
      unless (1..MAX_CARDS).cover?(reading['cards'].size) && !reading['question'].strip.empty?
        raise ArgumentError, 'Saved reading needs a question and one to three cards.'
      end

      deck = Deck.new
      deck.restore(reading['cards'])
      new(
        reading['question'], deck: deck, runner: runner,
                             interpretation: reading['interpretation'], save_path: save_path
      )
    end

    # Show restored state before the user chooses how to continue the reading.
    def display_reading
      puts "Question: #{@question}"
      display_spread
      puts 'INTERPRETATION:'
      puts @interpretation
      show_usage
    end

    # Keep the active reading and its save destination together for this session.
    def initialize(question, deck: Deck.new, runner: QwenRunner.new, interpretation: nil, save_path: ReadingStore::DEFAULT_PATH)
      @question = question
      @deck = deck
      @runner = runner
      @interpretation = interpretation
      @reading_store = ReadingStore.new(path: save_path)
      puts <<~TEXT
        [Session Initialized]
      TEXT
    end

    def run
      while (line = gets)
        break if execute(line) == :exit
      end

      0
    end

    # Session commands operate on the active reading until it returns to the main menu.
    def execute(line)
      command = line.strip
      execute_command(command) unless command.empty?
    end

    def execute_command(command)
      name, selection = command.split(' ', 2)
      return view_card(selection) if name == 'view'
      return describe_card(selection) if name == 'describe'

      handler = COMMAND_HANDLERS[command]
      return :exit if handler == :exit
      return send(handler) if handler

      unknown_command
    end

    private

    def show_usage
      puts AVAILABLE_COMMANDS
    end

    def view_card(selection)
      card = @deck.find_drawn_card(selection)
      puts(card ? card.ascii_art : 'Could not display art. Invalid card selection. Choose a drawn card.')
    end

    def describe_card(selection)
      card = @deck.find_drawn_card(selection)
      return puts 'Could not describe card. Invalid card selection. Choose a drawn card.' unless card

      puts "#{card.name}\n#{card.description}\nMeaning: #{card.meaning}"
    end

    # Return to the menu only after saving succeeds, keeping a failed reading available to retry.
    def save
      error = save_error
      return puts(error) if error

      @reading_store.save(question: @question, cards: @deck.drawn_cards.map(&:name), interpretation: @interpretation)
      puts 'Session successfully saved to disk. Returning to Main Menu...'
      :exit
    rescue ReadingStore::Error => e
      puts "Could not save reading: #{e.message}"
    end

    # A useful saved reading needs both a question and at least one drawn card.
    def save_error
      return 'Cannot save a reading without a question. Start a new reading first.' if @question.to_s.strip.empty?

      'Cannot save an empty reading. Please draw cards first.' if @deck.drawn_cards.empty?
    end

    def draw_card
      return missing_question if @question.to_s.strip.empty?

      if @deck.drawn_cards.size >= MAX_CARDS
        puts "Maximum of #{MAX_CARDS} cards reached. Shuffle before drawing again."
        return
      end

      puts 'Drawing card...'
      return unless @deck.draw_card

      display_spread
      interpret_spread
    end

    def display_spread
      puts LINE
      puts "Current Spread: #{formatted_cards}"
      puts LINE
    end

    def missing_question
      puts "Start a new reading with 'new' and enter a question before drawing."
    end

    def interpret_spread
      @interpretation = nil
      @interpretation = @runner.interpret(
        question: @question,
        cards: @deck.drawn_cards.dup
      )
      puts 'INTERPRETATION:'
      puts @interpretation
    rescue StandardError => e
      puts "Interpretation unavailable: #{e.message}"
    end

    def shuffle
      @deck.shuffle
      @question = nil
      @interpretation = nil
      exit_with_statement
      puts 'Session cleared. All cards are available again.'
      exit_with_statement
    end

    def non_session_command
      puts <<~TEXT
        That command is not available during a reading.
        #{AVAILABLE_COMMANDS}
      TEXT
    end

    def unknown_command
      puts <<~TEXT
        Unknown command.
        #{AVAILABLE_COMMANDS}
      TEXT
    end

    def exit_with_statement
      puts 'Returning to Main Menu...'
      :exit
    end

    def not_implemented
      puts <<~TEXT
        That command has not yet been implemented.
      TEXT
    end

    def formatted_cards
      @deck.drawn_cards.map { |card| "[ #{card.name} ]" }.join(' -> ')
    end
  end
end
