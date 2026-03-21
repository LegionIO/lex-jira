# frozen_string_literal: true

RSpec.describe Legion::Extensions::Jira::Runners::Issues do
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

  describe '#create_issue' do
    it 'creates an issue and returns it' do
      stubs.post('/rest/api/3/issue') do
        [201, { 'Content-Type' => 'application/json' }, { 'key' => 'PROJ-1', 'id' => '10001' }]
      end
      result = client.create_issue(project_key: 'PROJ', summary: 'Test bug', issue_type: 'Bug')
      expect(result[:issue]['key']).to eq('PROJ-1')
    end
  end

  describe '#get_issue' do
    it 'returns a single issue' do
      stubs.get('/rest/api/3/issue/PROJ-1') do
        [200, { 'Content-Type' => 'application/json' }, { 'key' => 'PROJ-1', 'fields' => { 'summary' => 'Test bug' } }]
      end
      result = client.get_issue(issue_key: 'PROJ-1')
      expect(result[:issue]['key']).to eq('PROJ-1')
    end
  end

  describe '#update_issue' do
    it 'returns updated true on 204' do
      stubs.put('/rest/api/3/issue/PROJ-1') do
        [204, {}, nil]
      end
      result = client.update_issue(issue_key: 'PROJ-1', summary: 'Updated summary')
      expect(result[:updated]).to be true
      expect(result[:issue_key]).to eq('PROJ-1')
    end
  end

  describe '#search_issues' do
    it 'returns issues matching the JQL query' do
      stubs.get('/rest/api/3/search') do
        [200, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-1' }], 'total' => 1 }]
      end
      result = client.search_issues(jql: 'project = PROJ')
      expect(result[:issues]['issues']).to be_an(Array)
    end
  end

  describe '#transition_issue' do
    it 'returns transitioned true on 204' do
      stubs.post('/rest/api/3/issue/PROJ-1/transitions') do
        [204, {}, nil]
      end
      result = client.transition_issue(issue_key: 'PROJ-1', transition_id: '31')
      expect(result[:transitioned]).to be true
      expect(result[:issue_key]).to eq('PROJ-1')
    end
  end

  describe '#add_comment' do
    it 'adds a comment and returns it' do
      stubs.post('/rest/api/3/issue/PROJ-1/comment') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => '10000', 'body' => 'Looks good' }]
      end
      result = client.add_comment(issue_key: 'PROJ-1', body: 'Looks good')
      expect(result[:comment]['body']).to eq('Looks good')
    end
  end
end
