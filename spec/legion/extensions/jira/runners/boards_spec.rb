# frozen_string_literal: true

RSpec.describe Legion::Extensions::Jira::Runners::Boards do
  let(:client) do
    Legion::Extensions::Jira::Client.new(
      url:       'https://acme.atlassian.net',
      email:     'user@example.com',
      api_token: 'secret-token'
    )
  end

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new(url: 'https://acme.atlassian.net') do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :test, stubs
    end
  end

  before { allow(client).to receive(:connection).and_return(test_connection) }

  describe '#list_boards' do
    it 'returns a list of boards' do
      stubs.get('/rest/agile/1.0/board') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'id' => 1, 'name' => 'Scrum Board' }], 'total' => 1 }]
      end
      result = client.list_boards
      expect(result[:boards]['values']).to be_an(Array)
    end
  end

  describe '#get_board' do
    it 'returns a single board by id' do
      stubs.get('/rest/agile/1.0/board/1') do
        [200, { 'Content-Type' => 'application/json' },
         { 'id' => 1, 'name' => 'Scrum Board' }]
      end
      result = client.get_board(board_id: 1)
      expect(result[:board]['id']).to eq(1)
    end
  end

  describe '#get_sprints' do
    it 'returns sprints for a board' do
      stubs.get('/rest/agile/1.0/board/1/sprint') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'id' => 10, 'name' => 'Sprint 1', 'state' => 'active' }] }]
      end
      result = client.get_sprints(board_id: 1)
      expect(result[:sprints]['values']).to be_an(Array)
      expect(result[:sprints]['values'].first['state']).to eq('active')
    end
  end
end
