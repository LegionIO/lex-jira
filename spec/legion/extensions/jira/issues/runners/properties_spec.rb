# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/properties'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Properties do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_issue_properties' do
    it 'returns property keys' do
      stubs.get('/rest/api/3/issue/PROJ-1/properties') do
        [200, { 'Content-Type' => 'application/json' },
         { 'keys' => [{ 'key' => 'my.prop' }] }]
      end
      result = instance.get_issue_properties(issue_key: 'PROJ-1')
      expect(result[:properties]['keys']).to be_an(Array)
    end
  end

  describe '#get_issue_property' do
    it 'returns a property value' do
      stubs.get('/rest/api/3/issue/PROJ-1/properties/my.prop') do
        [200, { 'Content-Type' => 'application/json' }, { 'key' => 'my.prop', 'value' => { 'count' => 5 } }]
      end
      result = instance.get_issue_property(issue_key: 'PROJ-1', property_key: 'my.prop')
      expect(result[:property]['key']).to eq('my.prop')
    end
  end

  describe '#set_issue_property' do
    it 'sets a property value' do
      stubs.put('/rest/api/3/issue/PROJ-1/properties/my.prop') do
        [200, {}, nil]
      end
      result = instance.set_issue_property(issue_key: 'PROJ-1', property_key: 'my.prop', value: { count: 10 })
      expect(result[:set]).to be true
    end
  end

  describe '#delete_issue_property' do
    it 'deletes a property' do
      stubs.delete('/rest/api/3/issue/PROJ-1/properties/my.prop') do
        [204, {}, nil]
      end
      result = instance.delete_issue_property(issue_key: 'PROJ-1', property_key: 'my.prop')
      expect(result[:deleted]).to be true
    end
  end
end
