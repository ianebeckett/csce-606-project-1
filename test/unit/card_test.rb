require 'json'
require 'tempfile'
require 'test_helper'
require 'tarot_cli/card'

class CardTest < Minitest::Test
  def test_load_from_file_builds_cards_in_file_order
    input = {
      cards: [{ id: 2, name: 'B', description: "\u{6708}", meaning: 'Change', art: ['B art'] },
              { id: 1, name: 'A', description: 'Sun', meaning: 'Clarity', art: ['A art'] }]
    }
    cards = load_cards(input)

    assert_equal input[:cards], cards.map(&:to_h)
    assert_equal [Card, Card], cards.map(&:class)
  end

  def test_load_from_file_raises_for_malformed_json
    assert_raises(JSON::ParserError) { load_cards('{"cards": [') }
  end

  def test_every_card_has_a_meaning
    path = File.expand_path('../../lib/data/cards.json', __dir__)
    cards = Card.load_from_file(path)

    assert_equal 78, cards.size
    missing = cards.filter_map { |card| card.name if card.meaning.to_s.strip.empty? }
    assert_empty missing
  end

  private

  def load_cards(data)
    contents = data.is_a?(String) ? data : JSON.generate(data)
    Tempfile.create('cards') do |file|
      file.write(contents)
      file.flush
      Card.load_from_file(file.path)
    end
  end
end
