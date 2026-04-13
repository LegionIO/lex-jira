# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/agile/runners/sprints'

RSpec.describe Legion::Extensions::Jira::Agile::Runners::Sprints do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_sprint' do
    it 'returns a sprint' do
      stubs.get('/rest/agile/1.0/sprint/10') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 10, 'name' => 'Sprint 1', 'state' => 'active' }]
      end
      result = instance.get_sprint(sprint_id: 10)
      expect(result[:sprint]['state']).to eq('active')
    end
  end

  describe '#create_sprint' do
    it 'creates a sprint' do
      stubs.post('/rest/agile/1.0/sprint') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => 11, 'name' => 'Sprint 2' }]
      end
      result = instance.create_sprint(name: 'Sprint 2', board_id: 1)
      expect(result[:sprint]['name']).to eq('Sprint 2')
    end
  end

  describe '#update_sprint' do
    it 'updates a sprint' do
      stubs.put('/rest/agile/1.0/sprint/10') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 10, 'name' => 'Sprint 1 - Updated' }]
      end
      result = instance.update_sprint(sprint_id: 10, name: 'Sprint 1 - Updated')
      expect(result[:sprint]['name']).to eq('Sprint 1 - Updated')
    end
  end

  describe '#delete_sprint' do
    it 'deletes a sprint' do
      stubs.delete('/rest/agile/1.0/sprint/10') do
        [204, {}, nil]
      end
      result = instance.delete_sprint(sprint_id: 10)
      expect(result[:deleted]).to be true
    end
  end

  describe '#get_sprint_issues' do
    it 'returns issues in a sprint' do
      stubs.get('/rest/agile/1.0/sprint/10/issue') do
        [200, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-1' }], 'total' => 1 }]
      end
      result = instance.get_sprint_issues(sprint_id: 10)
      expect(result[:issues]['issues']).to be_an(Array)
    end
  end

  describe '#move_issues_to_sprint' do
    it 'moves issues to a sprint' do
      stubs.post('/rest/agile/1.0/sprint/10/issue') do
        [204, {}, nil]
      end
      result = instance.move_issues_to_sprint(sprint_id: 10, issue_keys: %w[PROJ-1 PROJ-2])
      expect(result[:moved]).to be true
    end
  end
end
