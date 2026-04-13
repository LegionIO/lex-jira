# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/watchers'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Watchers do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_watchers' do
    it 'returns watchers' do
      stubs.get('/rest/api/3/issue/PROJ-1/watchers') do
        [200, { 'Content-Type' => 'application/json' },
         { 'watchCount' => 1, 'watchers' => [{ 'accountId' => 'abc123' }] }]
      end
      result = instance.get_watchers(issue_key: 'PROJ-1')
      expect(result[:watchers]['watchers']).to be_an(Array)
    end
  end

  describe '#add_watcher' do
    it 'adds a watcher' do
      stubs.post('/rest/api/3/issue/PROJ-1/watchers') do
        [204, {}, nil]
      end
      result = instance.add_watcher(issue_key: 'PROJ-1', account_id: 'abc123')
      expect(result[:added]).to be true
    end
  end

  describe '#remove_watcher' do
    it 'removes a watcher' do
      stubs.delete('/rest/api/3/issue/PROJ-1/watchers') do
        [204, {}, nil]
      end
      result = instance.remove_watcher(issue_key: 'PROJ-1', account_id: 'abc123')
      expect(result[:removed]).to be true
    end
  end
end
