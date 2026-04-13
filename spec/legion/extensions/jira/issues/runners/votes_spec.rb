# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/votes'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Votes do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_votes' do
    it 'returns vote info' do
      stubs.get('/rest/api/3/issue/PROJ-1/votes') do
        [200, { 'Content-Type' => 'application/json' }, { 'votes' => 3, 'hasVoted' => false }]
      end
      result = instance.get_votes(issue_key: 'PROJ-1')
      expect(result[:votes]['votes']).to eq(3)
    end
  end

  describe '#add_vote' do
    it 'adds a vote' do
      stubs.post('/rest/api/3/issue/PROJ-1/votes') do
        [204, {}, nil]
      end
      result = instance.add_vote(issue_key: 'PROJ-1')
      expect(result[:voted]).to be true
    end
  end

  describe '#remove_vote' do
    it 'removes a vote' do
      stubs.delete('/rest/api/3/issue/PROJ-1/votes') do
        [204, {}, nil]
      end
      result = instance.remove_vote(issue_key: 'PROJ-1')
      expect(result[:removed]).to be true
    end
  end
end
