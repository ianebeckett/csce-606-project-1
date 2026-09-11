# frozen_string_literal: true

require_relative 'deck'
require_relative 'qwen_runner'

module TarotCLI
  class Session
    MAX_CARDS = 3
    LINE = <<~TEXT
      ------------------------------------------------------------------------
    TEXT

    attr_reader :question, :interpretation

    def initialize(question, deck: Deck.new, runner: QwenRunner.new, interpretation: nil)
      @question = question
      @deck = deck
      @runner = runner
      @interpretation = interpretation
      puts <<~TEXT
        [Session Initialized]
        Available Commands: [draw], [details <card>], [save], [shuffle], [help], [exit]
      TEXT
    end

    def run
      while (line = gets)
        break if execute(line) == :exit
      end

      0
    end

    def execute(line)
      command = line.strip
      return if command.empty?

      case command
      when 'draw' then draw_card
      when 'details', 'save' then puts 'not yet implemented'
      when 'shuffle' then shuffle
      end
    end

    private

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
      puts 'Session cleared. All cards are available again. Returning to Main Menu...'
      :exit
    end

    def formatted_cards
      @deck.drawn_cards.map { |card| "[ #{card.name} ]" }.join(' -> ')
    end
  end
end
