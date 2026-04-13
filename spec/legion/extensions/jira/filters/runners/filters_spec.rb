# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/filters/runners/filters'

RSpec.describe Legion::Extensions::Jira::Filters::Runners::Filters do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_favorite_filters' do
    it 'returns favorite filters' do
      stubs.get('/rest/api/3/filter/favourite') do
        [200, { 'Content-Type' => 'application/json' }, [{ 'id' => '1', 'name' => 'My Bugs' }]]
      end
      result = instance.list_favorite_filters
      expect(result[:filters]).to be_an(Array)
    end
  end

  describe '#get_filter' do
    it 'returns a filter' do
      stubs.get('/rest/api/3/filter/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'My Bugs' }]
      end
      result = instance.get_filter(filter_id: '1')
      expect(result[:filter]['name']).to eq('My Bugs')
    end
  end

  describe '#create_filter' do
    it 'creates a filter' do
      stubs.post('/rest/api/3/filter') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '2', 'name' => 'New Filter' }]
      end
      result = instance.create_filter(name: 'New Filter', jql: 'project = PROJ')
      expect(result[:filter]['name']).to eq('New Filter')
    end
  end

  describe '#update_filter' do
    it 'updates a filter' do
      stubs.put('/rest/api/3/filter/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'Updated' }]
      end
      result = instance.update_filter(filter_id: '1', name: 'Updated')
      expect(result[:filter]['name']).to eq('Updated')
    end
  end

  describe '#delete_filter' do
    it 'deletes a filter' do
      stubs.delete('/rest/api/3/filter/1') do
        [204, {}, nil]
      end
      result = instance.delete_filter(filter_id: '1')
      expect(result[:deleted]).to be true
    end
  end

  describe '#get_filter_share_permissions' do
    it 'returns share permissions' do
      stubs.get('/rest/api/3/filter/1/permission') do
        [200, { 'Content-Type' => 'application/json' }, [{ 'id' => 100, 'type' => 'global' }]]
      end
      result = instance.get_filter_share_permissions(filter_id: '1')
      expect(result[:permissions]).to be_an(Array)
    end
  end

  describe '#add_filter_share_permission' do
    it 'adds a share permission' do
      stubs.post('/rest/api/3/filter/1/permission') do
        [201, { 'Content-Type' => 'application/json' }, [{ 'id' => 101, 'type' => 'project' }]]
      end
      result = instance.add_filter_share_permission(filter_id: '1', type: 'project', project_id: '10000')
      expect(result[:permissions]).to be_an(Array)
    end
  end

  describe '#delete_filter_share_permission' do
    it 'deletes a share permission' do
      stubs.delete('/rest/api/3/filter/1/permission/100') do
        [204, {}, nil]
      end
      result = instance.delete_filter_share_permission(filter_id: '1', permission_id: '100')
      expect(result[:deleted]).to be true
    end
  end
end
