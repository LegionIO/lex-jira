# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/remote_links'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::RemoteLinks do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_remote_links' do
    it 'returns remote links for an issue' do
      stubs.get('/rest/api/3/issue/PROJ-1/remotelink') do
        [200, { 'Content-Type' => 'application/json' },
         [{ 'id' => 1, 'object' => { 'url' => 'https://example.com' } }]]
      end
      result = instance.get_remote_links(issue_key: 'PROJ-1')
      expect(result[:remote_links]).to be_an(Array)
    end
  end

  describe '#get_remote_link' do
    it 'returns a single remote link' do
      stubs.get('/rest/api/3/issue/PROJ-1/remotelink/1') do
        [200, { 'Content-Type' => 'application/json' },
         { 'id' => 1, 'object' => { 'url' => 'https://example.com' } }]
      end
      result = instance.get_remote_link(issue_key: 'PROJ-1', link_id: '1')
      expect(result[:remote_link]['id']).to eq(1)
    end
  end

  describe '#create_remote_link' do
    it 'creates a remote link' do
      stubs.post('/rest/api/3/issue/PROJ-1/remotelink') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => 2 }]
      end
      result = instance.create_remote_link(issue_key: 'PROJ-1', url: 'https://example.com', title: 'Example')
      expect(result[:remote_link]['id']).to eq(2)
    end
  end

  describe '#update_remote_link' do
    it 'updates a remote link' do
      stubs.put('/rest/api/3/issue/PROJ-1/remotelink/1') do
        [204, {}, nil]
      end
      result = instance.update_remote_link(issue_key: 'PROJ-1', link_id: '1', url: 'https://new.com', title: 'New')
      expect(result[:updated]).to be true
    end
  end

  describe '#delete_remote_link' do
    it 'deletes a remote link' do
      stubs.delete('/rest/api/3/issue/PROJ-1/remotelink/1') do
        [204, {}, nil]
      end
      result = instance.delete_remote_link(issue_key: 'PROJ-1', link_id: '1')
      expect(result[:deleted]).to be true
    end
  end
end
