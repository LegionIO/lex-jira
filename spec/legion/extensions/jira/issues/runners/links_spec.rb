# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/links'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Links do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#create_issue_link' do
    it 'creates a link between issues' do
      stubs.post('/rest/api/3/issueLink') do
        [201, {}, nil]
      end
      result = instance.create_issue_link(type_name: 'Blocks', inward_issue: 'PROJ-1', outward_issue: 'PROJ-2')
      expect(result[:created]).to be true
    end
  end

  describe '#get_issue_link' do
    it 'returns a single link' do
      stubs.get('/rest/api/3/issueLink/1000') do
        [200, { 'Content-Type' => 'application/json' },
         { 'id' => '1000', 'type' => { 'name' => 'Blocks' } }]
      end
      result = instance.get_issue_link(link_id: '1000')
      expect(result[:link]['type']['name']).to eq('Blocks')
    end
  end

  describe '#delete_issue_link' do
    it 'deletes a link' do
      stubs.delete('/rest/api/3/issueLink/1000') do
        [204, {}, nil]
      end
      result = instance.delete_issue_link(link_id: '1000')
      expect(result[:deleted]).to be true
    end
  end

  describe '#list_link_types' do
    it 'returns all link types' do
      stubs.get('/rest/api/3/issueLinkType') do
        [200, { 'Content-Type' => 'application/json' },
         { 'issueLinkTypes' => [{ 'id' => '1', 'name' => 'Blocks' }] }]
      end
      result = instance.list_link_types
      expect(result[:link_types]['issueLinkTypes']).to be_an(Array)
    end
  end

  describe '#get_link_type' do
    it 'returns a single link type' do
      stubs.get('/rest/api/3/issueLinkType/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'Blocks' }]
      end
      result = instance.get_link_type(link_type_id: '1')
      expect(result[:link_type]['name']).to eq('Blocks')
    end
  end
end
