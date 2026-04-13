# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/audit_records/runners/audit_records'

RSpec.describe Legion::Extensions::Jira::AuditRecords::Runners::AuditRecords do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_audit_records' do
    it 'returns audit records' do
      stubs.get('/rest/api/3/auditing/record') do
        [200, { 'Content-Type' => 'application/json' },
         { 'records' => [{ 'id' => 1, 'summary' => 'User created' }], 'total' => 1 }]
      end
      result = instance.get_audit_records
      expect(result[:records]['records']).to be_an(Array)
    end
  end
end
