# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/agile/runners/backlogs'

RSpec.describe Legion::Extensions::Jira::Agile::Runners::Backlogs do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#move_issues_to_backlog' do
    it 'moves issues to the backlog' do
      stubs.post('/rest/agile/1.0/backlog/issue') do
        [204, {}, nil]
      end
      result = instance.move_issues_to_backlog(issue_keys: %w[PROJ-1 PROJ-2])
      expect(result[:moved]).to be true
    end
  end
end
