# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/worklogs'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Worklogs do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_issue_worklogs' do
    it 'returns worklogs for an issue' do
      stubs.get('/rest/api/3/issue/PROJ-1/worklog') do
        [200, { 'Content-Type' => 'application/json' },
         { 'worklogs' => [{ 'id' => '1', 'timeSpent' => '2h' }], 'total' => 1 }]
      end
      result = instance.get_issue_worklogs(issue_key: 'PROJ-1')
      expect(result[:worklogs]['worklogs']).to be_an(Array)
    end
  end

  describe '#get_worklog' do
    it 'returns a single worklog' do
      stubs.get('/rest/api/3/issue/PROJ-1/worklog/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'timeSpent' => '2h' }]
      end
      result = instance.get_worklog(issue_key: 'PROJ-1', worklog_id: '1')
      expect(result[:worklog]['id']).to eq('1')
    end
  end

  describe '#add_worklog' do
    it 'adds a worklog entry' do
      stubs.post('/rest/api/3/issue/PROJ-1/worklog') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => '2', 'timeSpent' => '1h' }]
      end
      result = instance.add_worklog(issue_key: 'PROJ-1', time_spent: '1h')
      expect(result[:worklog]['timeSpent']).to eq('1h')
    end
  end

  describe '#update_worklog' do
    it 'updates a worklog entry' do
      stubs.put('/rest/api/3/issue/PROJ-1/worklog/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'timeSpent' => '3h' }]
      end
      result = instance.update_worklog(issue_key: 'PROJ-1', worklog_id: '1', time_spent: '3h')
      expect(result[:worklog]['timeSpent']).to eq('3h')
    end
  end

  describe '#delete_worklog' do
    it 'deletes a worklog entry' do
      stubs.delete('/rest/api/3/issue/PROJ-1/worklog/1') do
        [204, {}, nil]
      end
      result = instance.delete_worklog(issue_key: 'PROJ-1', worklog_id: '1')
      expect(result[:deleted]).to be true
    end
  end
end
