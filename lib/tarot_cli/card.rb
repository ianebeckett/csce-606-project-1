# frozen_string_literal: true

require 'json'

Card = Data.define(:id, :name, :description, :meaning, :art) do
  def initialize(id:, name:, description:, meaning: nil, art: [])
    super
  end

  def ascii_art
    "#{name}\n#{art.join("\n")}"
  end

  def self.load_from_file(file_path)
    cards = JSON.parse(File.read(file_path, encoding: Encoding::UTF_8)).fetch('cards')
    cards.map do |card_data|
      new(
        id: card_data['id'],
        name: card_data['name'],
        description: card_data['description'],
        meaning: card_data.fetch('meaning'),
        art: card_data.fetch('art')
      )
    end
  end
end
