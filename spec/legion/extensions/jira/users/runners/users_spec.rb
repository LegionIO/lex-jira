# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/users/runners/users'

RSpec.describe Legion::Extensions::Jira::Users::Runners::Users do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_user' do
    it 'returns a user by account id' do
      stubs.get('/rest/api/3/user') do
        [200, { 'Content-Type' => 'application/json' }, { 'accountId' => 'abc', 'displayName' => 'Alice' }]
      end
      result = instance.get_user(account_id: 'abc')
      expect(result[:user]['displayName']).to eq('Alice')
    end
  end

  describe '#create_user' do
    it 'creates a user' do
      stubs.post('/rest/api/3/user') do
        [201, { 'Content-Type' => 'application/json' }, { 'accountId' => 'new', 'emailAddress' => 'new@test.com' }]
      end
      result = instance.create_user(email_address: 'new@test.com')
      expect(result[:user]['emailAddress']).to eq('new@test.com')
    end
  end

  describe '#delete_user' do
    it 'deletes a user' do
      stubs.delete('/rest/api/3/user') do
        [204, {}, nil]
      end
      result = instance.delete_user(account_id: 'abc')
      expect(result[:deleted]).to be true
    end
  end

  describe '#bulk_get_users' do
    it 'returns multiple users' do
      stubs.get('/rest/api/3/user/bulk') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'accountId' => 'abc' }, { 'accountId' => 'def' }] }]
      end
      result = instance.bulk_get_users(account_ids: %w[abc def])
      expect(result[:users]['values'].length).to eq(2)
    end
  end

  describe '#find_users' do
    it 'searches for users' do
      stubs.get('/rest/api/3/user/search') do
        [200, { 'Content-Type' => 'application/json' }, [{ 'accountId' => 'abc', 'displayName' => 'Alice' }]]
      end
      result = instance.find_users(query: 'alice')
      expect(result[:users]).to be_an(Array)
    end
  end

  describe '#find_users_by_query' do
    it 'searches users by query string' do
      stubs.get('/rest/api/3/user/search/query') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'accountId' => 'abc' }] }]
      end
      result = instance.find_users_by_query(query: 'is assignee of PROJ')
      expect(result[:users]['values']).to be_an(Array)
    end
  end

  describe '#get_myself' do
    it 'returns the current user' do
      stubs.get('/rest/api/3/myself') do
        [200, { 'Content-Type' => 'application/json' }, { 'accountId' => 'me', 'displayName' => 'Me' }]
      end
      result = instance.get_myself
      expect(result[:user]['accountId']).to eq('me')
    end
  end

  describe '#get_user_columns' do
    it 'returns user default columns' do
      stubs.get('/rest/api/3/user/columns') do
        [200, { 'Content-Type' => 'application/json' }, [{ 'label' => 'Key', 'value' => 'issuekey' }]]
      end
      result = instance.get_user_columns(account_id: 'abc')
      expect(result[:columns]).to be_an(Array)
    end
  end
end
