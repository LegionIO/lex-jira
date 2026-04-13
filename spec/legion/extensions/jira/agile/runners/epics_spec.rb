# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/agile/runners/epics'

RSpec.describe Legion::Extensions::Jira::Agile::Runners::Epics do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_epic' do
    it 'returns an epic' do
      stubs.get('/rest/agile/1.0/epic/PROJ-100') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 100, 'key' => 'PROJ-100', 'name' => 'Epic 1' }]
      end
      result = instance.get_epic(epic_id_or_key: 'PROJ-100')
      expect(result[:epic]['name']).to eq('Epic 1')
    end
  end

  describe '#get_epic_issues' do
    it 'returns issues in an epic' do
      stubs.get('/rest/agile/1.0/epic/PROJ-100/issue') do
        [200, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-101' }], 'total' => 1 }]
      end
      result = instance.get_epic_issues(epic_id_or_key: 'PROJ-100')
      expect(result[:issues]['issues']).to be_an(Array)
    end
  end

  describe '#move_issues_to_epic' do
    it 'moves issues to an epic' do
      stubs.post('/rest/agile/1.0/epic/PROJ-100/issue') do
        [204, {}, nil]
      end
      result = instance.move_issues_to_epic(epic_id_or_key: 'PROJ-100', issue_keys: ['PROJ-101'])
      expect(result[:moved]).to be true
    end
  end
end
