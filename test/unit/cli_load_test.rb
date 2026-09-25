# frozen_string_literal: true

# Checks Load command handling with scripted input and an isolated saved history.
require 'test_helper'
require 'stringio'
require 'tmpdir'
require 'fileutils'
require 'tarot_cli/cli'

class CLILoadTest < Minitest::Test
  class FakeRunner
    attr_reader :calls

    def initialize
      @calls = []
    end

    def interpret(question:, cards:)
      @calls << [question, cards.map(&:name)]
      'Updated interpretation'
    end
  end

  def setup
    @directory = Dir.mktmpdir('tarot-cli-load-test')
    @path = File.join(@directory, 'readings.json')
    @store = TarotCLI::ReadingStore.new(path: @path)
    @store.save(question: 'My question', cards: ['The World', 'The Tower'], interpretation: 'Saved interpretation')
    @reading = @store.load(1)
    @runner = FakeRunner.new
    @cli = TarotCLI::CLI.new(runner: @runner, save_path: @path)
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_resume_reading_displays_state_before_continuing_with_the_injected_runner
    _result, output = invoke(:resume_reading, @reading, input: "draw\nsave\n")

    assert_includes output, 'Session successfully loaded.'
    assert_operator output.index('Saved interpretation'), :<, output.index('Drawing card...')
    assert_equal [['My question', @store.load(2)['cards']]], @runner.calls
    assert_equal 'Updated interpretation', @store.load(2)['interpretation']
    assert_equal @reading, @store.load(1)
  end

  def test_prompt_for_reading_id_lists_choices_and_trims_input
    choices = [@reading.merge('ID' => 9), @reading.merge('ID' => 3, 'question' => 'Another question')]
    id, output = invoke(:prompt_for_reading_id, choices, input: "  3  \n")

    assert_equal 3, id
    assert_includes output, "Reading ID: 9\nSaved at: #{@reading['saved_at']}\nQuestion: My question\n"
    assert_includes output, "Reading ID: 3\nSaved at: #{@reading['saved_at']}\nQuestion: Another question\n"
    assert_includes output, 'Enter the reading ID to load (blank to cancel):'
  end

  EXPECTED_ERRORS = {
    '0' => 'Error: Please enter a positive reading ID number.',
    '-1' => 'Error: Please enter a positive reading ID number.',
    '1oops' => 'Error: Please enter a positive reading ID number.',
    '99' => 'Error: ID 99 not found in saved readings. Please try again.'
  }.freeze

  def test_load_rejects_invalid_or_missing_ids_without_changing_history
    original = File.binread(@path)
    EXPECTED_ERRORS.each do |input, message|
      _result, output = invoke(:load, input: "#{input}\n")
      assert_includes output, message
      refute_includes output, '[Session Initialized]'
    end
    assert_equal original, File.binread(@path)
  end

  def test_load_resumes_the_selected_record_without_requesting_an_interpretation
    @store.save(question: 'Second question', cards: ['The Fool'], interpretation: 'Second interpretation')
    _result, output = invoke(:load, input: "2\nsave\n")

    assert_includes output, "Question: Second question\n"
    assert_equal @store.load(2).slice('question', 'cards', 'interpretation'),
                 @store.load(3).slice('question', 'cards', 'interpretation')
    assert_empty @runner.calls
  end

  def test_load_returns_without_prompting_when_history_is_missing
    File.rename(@path, "#{@path}.backup")
    _result, output = invoke(:load)

    assert_equal "No saved readings found.\n", output
    refute File.exist?(@path)
  end

  def test_load_cancels_on_blank_input_or_eof_without_changing_history
    original = File.binread(@path)
    ["  \n", ''].each do |input|
      result, output = invoke(:load, input: input)
      assert_nil result
      refute_includes output, '[Session Initialized]'
    end
    assert_equal original, File.binread(@path)
  end

  private

  def invoke(method, *, input: '')
    original_stdin = $stdin
    $stdin = StringIO.new(input)
    result = nil
    output, = capture_io { result = @cli.send(method, *) }
    [result, output]
  ensure
    $stdin = original_stdin
  end
end
