# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/tarot_cli/session'

class SessionDrawTest < Minitest::Test
  class FakeRunner
    def interpret(question:, cards:)
      "#{question}: #{cards.map(&:name).join(', ')}"
    end
  end

  def setup
    cards = 4.times.map do |index|
      Card.new(id: index + 1, name: "Card #{index + 1}", description: 'Description')
    end
    @deck = Deck.new(cards: cards)
    capture_io do
      @session = TarotCLI::Session.new('Question', deck: @deck, runner: FakeRunner.new)
    end
  end

  def test_fourth_draw_is_rejected_until_shuffle
    3.times { draw_card }
    output, = capture_io { @session.execute('draw') }

    assert_equal 3, @deck.drawn_cards.size
    assert_match(/shuffle/i, output)
  end

  private

  def draw_card
    capture_io { @session.execute('draw') }
  end
end
