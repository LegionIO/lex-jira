# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/transitions'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Transitions do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_transitions' do
    it 'returns available transitions' do
      stubs.get('/rest/api/3/issue/PROJ-1/transitions') do
        [200, { 'Content-Type' => 'application/json' },
         { 'transitions' => [{ 'id' => '31', 'name' => 'Done' }] }]
      end
      result = instance.get_transitions(issue_key: 'PROJ-1')
      expect(result[:transitions]['transitions']).to be_an(Array)
    end
  end

  describe '#transition_issue' do
    it 'returns transitioned true on 204' do
      stubs.post('/rest/api/3/issue/PROJ-1/transitions') do
        [204, {}, nil]
      end
      result = instance.transition_issue(issue_key: 'PROJ-1', transition_id: '31')
      expect(result[:transitioned]).to be true
    end
  end
end
