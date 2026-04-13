# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/dashboards/runners/dashboards'

RSpec.describe Legion::Extensions::Jira::Dashboards::Runners::Dashboards do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_dashboards' do
    it 'returns dashboards' do
      stubs.get('/rest/api/3/dashboard') do
        [200, { 'Content-Type' => 'application/json' },
         { 'dashboards' => [{ 'id' => '1', 'name' => 'My Dash' }], 'total' => 1 }]
      end
      result = instance.list_dashboards
      expect(result[:dashboards]['dashboards']).to be_an(Array)
    end
  end

  describe '#get_dashboard' do
    it 'returns a dashboard' do
      stubs.get('/rest/api/3/dashboard/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'My Dash' }]
      end
      result = instance.get_dashboard(dashboard_id: '1')
      expect(result[:dashboard]['name']).to eq('My Dash')
    end
  end

  describe '#create_dashboard' do
    it 'creates a dashboard' do
      stubs.post('/rest/api/3/dashboard') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '2', 'name' => 'New Dash' }]
      end
      result = instance.create_dashboard(name: 'New Dash')
      expect(result[:dashboard]['name']).to eq('New Dash')
    end
  end

  describe '#update_dashboard' do
    it 'updates a dashboard' do
      stubs.put('/rest/api/3/dashboard/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'Updated' }]
      end
      result = instance.update_dashboard(dashboard_id: '1', name: 'Updated')
      expect(result[:dashboard]['name']).to eq('Updated')
    end
  end

  describe '#delete_dashboard' do
    it 'deletes a dashboard' do
      stubs.delete('/rest/api/3/dashboard/1') do
        [204, {}, nil]
      end
      result = instance.delete_dashboard(dashboard_id: '1')
      expect(result[:deleted]).to be true
    end
  end

  describe '#copy_dashboard' do
    it 'copies a dashboard' do
      stubs.post('/rest/api/3/dashboard/1/copy') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '3', 'name' => 'Copy of Dash' }]
      end
      result = instance.copy_dashboard(dashboard_id: '1', name: 'Copy of Dash')
      expect(result[:dashboard]['id']).to eq('3')
    end
  end
end
