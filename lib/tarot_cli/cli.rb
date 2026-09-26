# frozen_string_literal: true

require_relative 'session'

module TarotCLI
  class CLI # rubocop:disable Metrics/ClassLength
    USAGE = <<~TEXT
      Usage: tarot [command]

      Commands:
        help, -h, --help  Show this help
        new               Start a new session
        review            Review saved past sessions
        load              Load a past saved session
        exit, quit        Exit tarot-cli
    TEXT

    COMMAND_HANDLERS = {
      'help' => :show_usage, '-h' => :show_usage, '--help' => :show_usage,
      'new' => :start_session, 'review' => :review_readings,
      'load' => :load, 'draw' => :show_draw_without_reading,
      'save' => :show_save_without_reading, 'shuffle' => :show_shuffle_without_reading,
      'exit' => :exit, 'quit' => :exit
    }.freeze

    # Use one history file across readings while allowing tests to choose a temporary path.
    def initialize(runner: QwenRunner.new, save_path: ReadingStore::DEFAULT_PATH)
      @save_path = save_path
      @runner = runner
    end

    def run(arguments = [])
      unless arguments.empty?
        result = execute(arguments.join(' '))
        return result == :unknown ? 1 : 0
      end

      puts 'Welcome to tarot-cli.'
      puts "Type 'help' to see available commands."

      while (line = gets)
        break if execute(line) == :exit
      end

      0
    end

    private

    def execute(line)
      command = line.strip
      execute_command(command) unless command.empty?
    end

    def execute_command(command)
      handler = COMMAND_HANDLERS[command]
      return :exit if handler == :exit
      return send(handler) if handler

      unknown_command(command)
    end

    def show_usage
      puts USAGE
    end

    # Select a snapshot before starting a session so failed loads leave the menu usable.
    def load
      store = ReadingStore.new(path: @save_path)
      readings = store.readings
      return puts 'No saved readings found.' if readings.empty?

      id = prompt_for_reading_id(readings)
      return if id == :exit || !id

      resume_reading(store.load(id))
    rescue ReadingStore::Error, ArgumentError => e
      puts "Could not load reading: #{e.message}"
    end

    # Continue through the same command loop and save destination as a new reading.
    def resume_reading(reading)
      session = Session.from_reading(reading, runner: @runner, save_path: @save_path)
      puts 'Session successfully loaded.'
      session.display_reading
      session.run
    end

    # Show saved IDs and reject partial numbers rather than selecting an unintended reading.
    def prompt_for_reading_id(readings)
      display_readings(readings)
      valid_ids = readings.map { |reading| reading['ID'].to_i }

      loop do
        puts 'Enter the reading ID to load (blank to cancel):'
        selection = gets&.strip

        return nil if selection.nil?
        return exit_with_statement if selection.empty?
        return selection.to_i if valid_selection?(selection, valid_ids)
      end
    end

    def valid_selection?(selection, valid_ids)
      unless selection.match?(/\A[1-9]\d*\z/)
        puts 'Error: Please enter a positive reading ID number.'
        return false
      end

      id_integer = selection.to_i
      unless valid_ids.include?(id_integer)
        puts "Error: ID #{id_integer} not found in saved readings. Please try again."
        return false
      end

      true
    end

    def show_draw_without_reading
      missing_reading('draw')
    end

    def show_save_without_reading
      missing_reading('save')
    end

    def show_shuffle_without_reading
      puts 'No active reading to shuffle.'
    end

    def missing_reading(command)
      if command == 'save'
        puts 'Cannot save an empty reading. Please start a new reading and draw cards first.'
      else
        puts "Start a new reading with 'new' and enter a question before drawing."
      end
    end

    def review_readings
      readings = ReadingStore.new(path: @save_path).readings
      return puts 'No saved readings found.' if readings.empty?

      readings.sort_by { |reading| Time.iso8601(reading['saved_at']) }.reverse_each do |reading|
        display_reading(reading)
      end
    rescue ReadingStore::Error => e
      puts "Could not review saved readings: #{e.message}"
    end

    def display_reading(reading)
      puts <<~TEXT
        Reading ID: #{reading['ID']}
        Saved at: #{reading['saved_at']}
        Question: #{reading['question']}
        Cards: #{reading['cards'].join(' -> ')}
        Interpretation: #{reading['interpretation']}

      TEXT
    end

    def display_readings(readings)
      readings.each do |r|
        display_reading(r)
      end
    end

    # Carry the chosen runner and save destination into every new reading.
    def start_session
      question = prompt_for_question
      Session.new(question, runner: @runner, save_path: @save_path).run if question
    end

    def prompt_for_question
      loop do
        puts 'Enter your intention or question for this session: '
        question = gets&.strip
        return if question.nil?
        return question unless question.empty?

        puts 'Question cannot be blank.'
      end
    end

    def exit_with_statement
      puts 'Returning to Main Menu...'
      :exit
    end

    def unknown_command(command)
      puts "Unknown command: #{command}"
      puts "Type 'help' to see available commands."
      :unknown
    end
  end
end
