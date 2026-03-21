# frozen_string_literal: true

RSpec.describe Legion::Extensions::Jira::Runners::Projects do
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

  describe '#list_projects' do
    it 'returns an array of projects' do
      stubs.get('/rest/api/3/project') do
        [200, { 'Content-Type' => 'application/json' },
         [{ 'key' => 'PROJ', 'name' => 'My Project' }]]
      end
      result = client.list_projects
      expect(result[:projects]).to be_an(Array)
      expect(result[:projects].first['key']).to eq('PROJ')
    end
  end

  describe '#get_project' do
    it 'returns a single project by key' do
      stubs.get('/rest/api/3/project/PROJ') do
        [200, { 'Content-Type' => 'application/json' },
         { 'key' => 'PROJ', 'name' => 'My Project' }]
      end
      result = client.get_project(project_key: 'PROJ')
      expect(result[:project]['key']).to eq('PROJ')
    end
  end
end
