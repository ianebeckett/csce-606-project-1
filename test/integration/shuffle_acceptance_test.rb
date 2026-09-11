# frozen_string_literal: true

require 'stringio'
require 'test_helper'
require 'tarot_cli/cli'

class ShuffleAcceptanceTest < Minitest::Test
  class FakeRunner
    def interpret(question:, cards:)
      "#{question}: #{cards.map(&:name).join(', ')}"
    end
  end

  SHUFFLE_FLOW = <<~INPUT
    new
    First question
    draw
    shuffle
    draw
    new

    Second question
    draw
    shuffle
    exit
  INPUT

  def test_shuffle_starts_a_clean_reading_with_a_new_question
    status, output = run_cli(SHUFFLE_FLOW)

    assert_equal 0, status
    assert_clean_spreads(output)
  end

  private

  def assert_clean_spreads(output)
    spreads = output.lines.grep(/^Current Spread:/)
    assert_equal 2, spreads.length
    spreads.each { |spread| refute_includes spread, '->' }
  end

  def run_cli(input)
    original_stdin = $stdin
    $stdin = StringIO.new(input)
    status = nil
    output, = capture_io { status = TarotCLI::CLI.new(runner: FakeRunner.new).run }
    [status, output]
  ensure
    $stdin = original_stdin
  end
end
