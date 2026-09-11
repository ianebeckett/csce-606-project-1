# frozen_string_literal: true

require 'json'
require 'test_helper'
require 'tarot_cli/card'
require 'tarot_cli/qwen_runner'

class QwenRunnerTest < Minitest::Test
  Response = Data.define(:code, :body)

  class FakeHttp
    attr_reader :model_requests, :requests

    def initialize(response: nil, model_response: nil, error: nil)
      @response = response
      @model_response = model_response || default_model_response
      @error = error
      @model_requests = []
      @requests = []
    end

    def get_response(uri)
      @model_requests << uri
      raise @error if @error

      @model_response
    end

    def post(uri, body, headers)
      @requests << { uri: uri, body: body, headers: headers }
      raise @error if @error

      @response
    end

    private

    def default_model_response
      body = JSON.generate(data: [{ id: 'ggml-org/Qwen3.5-0.8B-GGUF' }])
      Response.new(code: '200', body: body)
    end
  end

  def setup
    @cards = [
      Card.new(id: 1, name: 'First', description: 'Beginning'),
      Card.new(id: 2, name: 'Second', description: 'Middle'),
      Card.new(id: 3, name: 'Third', description: 'Outcome')
    ]
  end

  def test_posts_question_and_ordered_card_names_and_descriptions_to_llama_chat_endpoint
    http = FakeHttp.new(response: successful_response('Read them together.'))
    runner = TarotCLI::QwenRunner.new(http: http)

    result = runner.interpret(question: 'What comes next?', cards: @cards)

    assert_equal 'Read them together.', result
    assert_equal [URI(TarotCLI::QwenRunner::MODELS_ENDPOINT)], http.model_requests
    assert_equal 1, http.requests.size
    assert_request(http.requests.first)
  end

  def assert_request(request)
    assert_equal TarotCLI::QwenRunner::ENDPOINT, request[:uri].to_s
    assert_equal({ 'Content-Type' => 'application/json' }, request[:headers])
    assert_request_body(JSON.parse(request[:body]))
  end

  def assert_request_body(body)
    assert_equal 'ggml-org/Qwen3.5-0.8B-GGUF', body['model']
    assert_equal false, body['stream']
    assert_equal false, body.dig('chat_template_kwargs', 'enable_thinking')
    assert_messages(body['messages'])
  end

  def assert_messages(messages)
    roles = messages.map { |message| message['role'] }
    assert_equal %w[system user], roles
    assert_equal expected_system_prompt, messages[0]['content']
    assert_includes messages[1]['content'], 'Question: What comes next?'
    assert_card_order(messages[1]['content'])
  end

  def expected_system_prompt
    <<~PROMPT.strip
      You are a tarot reading service. Give a direct answer to the user's question based on the drawn cards.
      Explain each drawn card exactly once, in draw order, and connect its meaning to the answer.
      For entertainment only, respond in one plain-text paragraph under 120 words.
    PROMPT
  end

  def assert_card_order(prompt)
    first = prompt.index('1. First: Beginning')
    second = prompt.index('2. Second: Middle')
    third = prompt.index('3. Third: Outcome')
    assert_operator first, :<, second
    assert_operator second, :<, third
  end

  def test_non_success_response_becomes_clear_runner_error
    runner = TarotCLI::QwenRunner.new(http: FakeHttp.new(response: Response.new(code: '503', body: '{}')))

    error = assert_raises(TarotCLI::QwenRunner::Error) do
      runner.interpret(question: 'Question', cards: @cards)
    end

    assert_equal 'Local Qwen server returned HTTP 503.', error.message
  end

  def test_rejects_a_server_running_a_different_model
    body = JSON.generate(data: [{ id: 'bartowski/Qwen3.5-0.8B-GGUF' }])
    http = FakeHttp.new(model_response: Response.new(code: '200', body: body))
    runner = TarotCLI::QwenRunner.new(http: http)

    error = assert_raises(TarotCLI::QwenRunner::Error) do
      runner.interpret(question: 'Question', cards: @cards)
    end

    assert_match(/not running the required model/, error.message)
    assert_empty http.requests
  end

  def test_invalid_response_becomes_clear_runner_error
    runner = TarotCLI::QwenRunner.new(http: FakeHttp.new(response: Response.new(code: '200', body: '{}')))

    error = assert_raises(TarotCLI::QwenRunner::Error) do
      runner.interpret(question: 'Question', cards: @cards)
    end

    assert_equal 'Local Qwen server returned an empty interpretation.', error.message
  end

  def test_connection_failure_becomes_clear_runner_error
    http = FakeHttp.new(error: Errno::ECONNREFUSED.new)
    runner = TarotCLI::QwenRunner.new(http: http)

    error = assert_raises(TarotCLI::QwenRunner::Error) do
      runner.interpret(question: 'Question', cards: @cards)
    end

    assert_match(/Could not reach the local Qwen server/, error.message)
  end

  private

  def successful_response(content)
    body = JSON.generate(choices: [{ message: { content: content } }])
    Response.new(code: '200', body: body)
  end
end
