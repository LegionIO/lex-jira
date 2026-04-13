# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/groups/runners/groups'

RSpec.describe Legion::Extensions::Jira::Groups::Runners::Groups do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_group' do
    it 'returns a group' do
      stubs.get('/rest/api/3/group') do
        [200, { 'Content-Type' => 'application/json' }, { 'name' => 'dev-team', 'users' => { 'items' => [] } }]
      end
      result = instance.get_group(group_name: 'dev-team')
      expect(result[:group]['name']).to eq('dev-team')
    end
  end

  describe '#create_group' do
    it 'creates a group' do
      stubs.post('/rest/api/3/group') do
        [201, { 'Content-Type' => 'application/json' }, { 'name' => 'new-team' }]
      end
      result = instance.create_group(name: 'new-team')
      expect(result[:group]['name']).to eq('new-team')
    end
  end

  describe '#delete_group' do
    it 'deletes a group' do
      stubs.delete('/rest/api/3/group') do
        [200, {}, nil]
      end
      result = instance.delete_group(group_name: 'old-team')
      expect(result[:deleted]).to be true
    end
  end

  describe '#add_user_to_group' do
    it 'adds a user' do
      stubs.post('/rest/api/3/group/user') do
        [201, { 'Content-Type' => 'application/json' }, { 'name' => 'dev-team' }]
      end
      result = instance.add_user_to_group(group_name: 'dev-team', account_id: 'abc')
      expect(result[:group]['name']).to eq('dev-team')
    end
  end

  describe '#remove_user_from_group' do
    it 'removes a user' do
      stubs.delete('/rest/api/3/group/user') do
        [200, {}, nil]
      end
      result = instance.remove_user_from_group(group_name: 'dev-team', account_id: 'abc')
      expect(result[:removed]).to be true
    end
  end

  describe '#bulk_get_groups' do
    it 'returns multiple groups' do
      stubs.get('/rest/api/3/group/bulk') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'name' => 'dev-team' }], 'total' => 1 }]
      end
      result = instance.bulk_get_groups
      expect(result[:groups]['values']).to be_an(Array)
    end
  end

  describe '#find_groups' do
    it 'searches for groups' do
      stubs.get('/rest/api/3/groups/picker') do
        [200, { 'Content-Type' => 'application/json' },
         { 'groups' => [{ 'name' => 'dev-team' }] }]
      end
      result = instance.find_groups(query: 'dev')
      expect(result[:groups]['groups']).to be_an(Array)
    end
  end
end
