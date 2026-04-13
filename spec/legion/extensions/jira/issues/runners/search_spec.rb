# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/search'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Search do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#search_issues' do
    it 'returns issues matching JQL' do
      stubs.get('/rest/api/3/search') do
        [200, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-1' }], 'total' => 1 }]
      end
      result = instance.search_issues(jql: 'project = PROJ')
      expect(result[:issues]['issues']).to be_an(Array)
    end
  end

  describe '#pick_issues' do
    it 'returns suggested issues' do
      stubs.get('/rest/api/3/issue/picker') do
        [200, { 'Content-Type' => 'application/json' },
         { 'sections' => [{ 'issues' => [{ 'key' => 'PROJ-1' }] }] }]
      end
      result = instance.pick_issues(query: 'test')
      expect(result[:suggestions]['sections']).to be_an(Array)
    end
  end

  describe '#parse_jql' do
    it 'parses JQL queries' do
      stubs.post('/rest/api/3/jql/parse') do
        [200, { 'Content-Type' => 'application/json' },
         { 'queries' => [{ 'query' => 'project = PROJ', 'errors' => [] }] }]
      end
      result = instance.parse_jql(queries: ['project = PROJ'])
      expect(result[:parsed]['queries'].first['errors']).to be_empty
    end
  end

  describe '#autocomplete_jql' do
    it 'returns autocomplete suggestions' do
      stubs.get('/rest/api/3/jql/autocompletedata') do
        [200, { 'Content-Type' => 'application/json' },
         { 'visibleFieldNames' => [{ 'value' => 'project' }] }]
      end
      result = instance.autocomplete_jql
      expect(result[:suggestions]).to have_key('visibleFieldNames')
    end
  end
end
