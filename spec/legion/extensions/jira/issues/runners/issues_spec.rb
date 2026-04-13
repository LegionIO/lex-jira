# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/issues'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Issues do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#create_issue' do
    it 'creates an issue' do
      stubs.post('/rest/api/3/issue') do
        [201, { 'Content-Type' => 'application/json' }, { 'key' => 'PROJ-1', 'id' => '10001' }]
      end
      result = instance.create_issue(project_key: 'PROJ', summary: 'Test', issue_type: 'Bug')
      expect(result[:issue]['key']).to eq('PROJ-1')
    end
  end

  describe '#get_issue' do
    it 'returns a single issue' do
      stubs.get('/rest/api/3/issue/PROJ-1') do
        [200, { 'Content-Type' => 'application/json' }, { 'key' => 'PROJ-1', 'fields' => {} }]
      end
      result = instance.get_issue(issue_key: 'PROJ-1')
      expect(result[:issue]['key']).to eq('PROJ-1')
    end
  end

  describe '#update_issue' do
    it 'returns updated true on 204' do
      stubs.put('/rest/api/3/issue/PROJ-1') do
        [204, {}, nil]
      end
      result = instance.update_issue(issue_key: 'PROJ-1', summary: 'Updated')
      expect(result[:updated]).to be true
    end
  end

  describe '#delete_issue' do
    it 'returns deleted true on 204' do
      stubs.delete('/rest/api/3/issue/PROJ-1') do
        [204, {}, nil]
      end
      result = instance.delete_issue(issue_key: 'PROJ-1')
      expect(result[:deleted]).to be true
    end
  end

  describe '#bulk_create_issues' do
    it 'creates multiple issues' do
      stubs.post('/rest/api/3/issue/bulk') do
        [201, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-1' }, { 'key' => 'PROJ-2' }] }]
      end
      issues = [{ project_key: 'PROJ', summary: 'One', issue_type: 'Task' },
                { project_key: 'PROJ', summary: 'Two', issue_type: 'Task' }]
      result = instance.bulk_create_issues(issues: issues)
      expect(result[:issues]['issues'].length).to eq(2)
    end
  end

  describe '#get_issue_changelog' do
    it 'returns changelog entries' do
      stubs.get('/rest/api/3/issue/PROJ-1/changelog') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'id' => '100' }], 'total' => 1 }]
      end
      result = instance.get_issue_changelog(issue_key: 'PROJ-1')
      expect(result[:changelog]['values']).to be_an(Array)
    end
  end
end
