require 'json'
require 'open3'
require 'rbconfig'
require 'test_helper'
require 'tarot_cli/session'

class DescribeAcceptanceTest < Minitest::Test
  DATA_PATH = File.expand_path('../../lib/data/cards.json', __dir__)
  CARDS = JSON.parse(File.read(DATA_PATH, encoding: Encoding::UTF_8)).fetch('cards')
  EXECUTABLE = File.expand_path('../../bin/tarot', __dir__)
  FAKE_RUNNER = File.expand_path('../support/fake_qwen_runner.rb', __dir__)
  INVALID = 'Could not describe card. Invalid card selection.'.freeze

  def test_executable_describes_only_the_drawn_card_by_name
    names = CARDS.map { |card| "describe #{card['name']}\n" }.join
    input = "new\nQuestion\ndescribe The Fool\ndraw\n#{names}describe Not a card\ndescribe\nshuffle\nexit\n"
    output = run_executable(input)
    drawn = output[/Current Spread: \[ (.*?) \]/, 1]

    assert_equal({ drawn => 1 }, described_counts(output))
    assert_equal CARDS.size + 2, output.scan(INVALID).size
  end

  def test_numeric_id_cannot_describe_a_drawn_card
    fool = Card.load_from_file(DATA_PATH).find { |card| card.name == 'The Fool' }
    assert_equal 0, fool.id
    deck = Deck.new(cards: [fool])
    assert_equal fool, deck.draw_card
    session = nil
    capture_io { session = TarotCLI::Session.new('Question', deck: deck) }

    output, = capture_io { session.execute('describe 0') }
    assert_equal "#{INVALID} Choose a drawn card.\n", output
  end

  private

  def described_counts(output)
    counts = CARDS.to_h do |card|
      description = "#{card['name']}\n#{card['description']}\nMeaning: #{card['meaning']}"
      [card['name'], output.scan(description).size]
    end
    counts.reject { |_name, count| count.zero? }
  end

  def run_executable(input)
    output, error, status = Open3.capture3(RbConfig.ruby, '-r', FAKE_RUNNER, EXECUTABLE, stdin_data: input)
    assert status.success?, error
    output.force_encoding(Encoding::UTF_8)
  end
end
