# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/webhooks/runners/webhooks'

RSpec.describe Legion::Extensions::Jira::Webhooks::Runners::Webhooks do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_webhooks' do
    it 'returns registered webhooks' do
      stubs.get('/rest/api/3/webhook') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'id' => 1, 'jqlFilter' => 'project = PROJ' }] }]
      end
      result = instance.list_webhooks
      expect(result[:webhooks]['values']).to be_an(Array)
    end
  end

  describe '#register_webhooks' do
    it 'registers webhooks' do
      stubs.post('/rest/api/3/webhook') do
        [200, { 'Content-Type' => 'application/json' },
         { 'webhookRegistrationResult' => [{ 'createdWebhookId' => 2 }] }]
      end
      result = instance.register_webhooks(
        webhooks: [{ jqlFilter: 'project = PROJ', events: ['jira:issue_created'] }],
        url: 'https://example.com/webhook'
      )
      expect(result[:result]).to have_key('webhookRegistrationResult')
    end
  end

  describe '#delete_webhooks' do
    it 'deletes webhooks' do
      stubs.delete('/rest/api/3/webhook') do
        [202, {}, nil]
      end
      result = instance.delete_webhooks(webhook_ids: [1, 2])
      expect(result[:deleted]).to be true
    end
  end

  describe '#refresh_webhooks' do
    it 'refreshes webhook expiry' do
      stubs.put('/rest/api/3/webhook/refresh') do
        [200, { 'Content-Type' => 'application/json' },
         { 'webhooksRefreshResult' => [{ 'webhookId' => 1, 'expirationDate' => '2026-05-13' }] }]
      end
      result = instance.refresh_webhooks(webhook_ids: [1])
      expect(result[:result]).to have_key('webhooksRefreshResult')
    end
  end
end
