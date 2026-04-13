# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/agile/runners/boards'

RSpec.describe Legion::Extensions::Jira::Agile::Runners::Boards do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_boards' do
    it 'returns boards' do
      stubs.get('/rest/agile/1.0/board') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'id' => 1, 'name' => 'Scrum Board' }], 'total' => 1 }]
      end
      result = instance.list_boards
      expect(result[:boards]['values']).to be_an(Array)
    end
  end

  describe '#get_board' do
    it 'returns a board' do
      stubs.get('/rest/agile/1.0/board/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 1, 'name' => 'Scrum Board' }]
      end
      result = instance.get_board(board_id: 1)
      expect(result[:board]['id']).to eq(1)
    end
  end

  describe '#get_board_configuration' do
    it 'returns board configuration' do
      stubs.get('/rest/agile/1.0/board/1/configuration') do
        [200, { 'Content-Type' => 'application/json' },
         { 'id' => 1, 'name' => 'Scrum Board', 'columnConfig' => {} }]
      end
      result = instance.get_board_configuration(board_id: 1)
      expect(result[:configuration]).to have_key('columnConfig')
    end
  end

  describe '#get_board_issues' do
    it 'returns issues on a board' do
      stubs.get('/rest/agile/1.0/board/1/issue') do
        [200, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-1' }], 'total' => 1 }]
      end
      result = instance.get_board_issues(board_id: 1)
      expect(result[:issues]['issues']).to be_an(Array)
    end
  end
end
