# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module TarotCLI
  class QwenRunner
    ENDPOINT = 'http://127.0.0.1:8080/v1/chat/completions'
    MODELS_ENDPOINT = 'http://127.0.0.1:8080/v1/models'
    MODEL = 'ggml-org/Qwen3.5-0.8B-GGUF'
    MAX_TOKENS = 300

    class Error < StandardError; end

    def initialize(http: Net::HTTP)
      @endpoint = URI(ENDPOINT)
      @models_endpoint = URI(MODELS_ENDPOINT)
      @http = http
    end

    def interpret(question:, cards:)
      model_id = verify_model
      response = post(request_body(question, cards, model_id))
      validate_status(response)
      extract_content(response.body)
    rescue Error
      raise
    rescue JSON::ParserError, KeyError, TypeError
      raise Error, 'Local Qwen server returned an invalid response.'
    rescue StandardError => e
      raise Error, "Could not reach the local Qwen server: #{e.message}"
    end

    private

    def verify_model
      response = @http.get_response(@models_endpoint)
      validate_status(response)
      loaded_model_id(response.body)
    end

    def loaded_model_id(body)
      models = JSON.parse(body).fetch('data')
      model_id = models.filter_map { |model| model['id'] if model.is_a?(Hash) }.find do |id|
        id == MODEL
      end
      return model_id if model_id

      raise Error, "Local server is not running the required model: #{MODEL}."
    end

    def post(body)
      @http.post(
        @endpoint,
        JSON.generate(body),
        'Content-Type' => 'application/json'
      )
    end

    def validate_status(response)
      return if response.code.to_i.between?(200, 299)

      raise Error, "Local Qwen server returned HTTP #{response.code}."
    end

    def extract_content(body)
      content = JSON.parse(body).dig('choices', 0, 'message', 'content')
      raise Error, 'Local Qwen server returned an empty interpretation.' if content.to_s.strip.empty?

      content.strip
    end

    def request_body(question, cards, model_id)
      {
        model: model_id,
        max_tokens: MAX_TOKENS,
        stream: false,
        chat_template_kwargs: { enable_thinking: false },
        messages: messages(question, cards)
      }
    end

    def messages(question, cards)
      [
        {
          role: 'system',
          content: <<~PROMPT.strip
            You are a tarot reading service. Give a direct answer to the user's question based on the drawn cards.
            Explain each drawn card exactly once, in draw order, and connect its meaning to the answer.
            For entertainment only, respond in one plain-text paragraph under 120 words.
          PROMPT
        },
        { role: 'user', content: user_prompt(question, cards) }
      ]
    end

    def user_prompt(question, cards)
      card_list = cards.each_with_index.map do |card, index|
        "#{index + 1}. #{card.name}: #{card.description}"
      end.join("\n")

      <<~PROMPT
        Question: #{question}
        Cards in draw order:
        #{card_list}
      PROMPT
    end
  end
end
