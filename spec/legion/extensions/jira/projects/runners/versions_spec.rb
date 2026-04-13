# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/projects/runners/versions'

RSpec.describe Legion::Extensions::Jira::Projects::Runners::Versions do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_project_versions' do
    it 'returns versions for a project' do
      stubs.get('/rest/api/3/project/PROJ/versions') do
        [200, { 'Content-Type' => 'application/json' },
         [{ 'id' => '1', 'name' => 'v1.0' }]]
      end
      result = instance.list_project_versions(project_key: 'PROJ')
      expect(result[:versions]).to be_an(Array)
    end
  end

  describe '#get_version' do
    it 'returns a version' do
      stubs.get('/rest/api/3/version/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'v1.0' }]
      end
      result = instance.get_version(version_id: '1')
      expect(result[:version]['name']).to eq('v1.0')
    end
  end

  describe '#create_version' do
    it 'creates a version' do
      stubs.post('/rest/api/3/version') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => '2', 'name' => 'v2.0' }]
      end
      result = instance.create_version(project_id: '10000', name: 'v2.0')
      expect(result[:version]['name']).to eq('v2.0')
    end
  end

  describe '#update_version' do
    it 'updates a version' do
      stubs.put('/rest/api/3/version/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'v1.1' }]
      end
      result = instance.update_version(version_id: '1', name: 'v1.1')
      expect(result[:version]['name']).to eq('v1.1')
    end
  end

  describe '#delete_version' do
    it 'deletes a version' do
      stubs.delete('/rest/api/3/version/1') do
        [204, {}, nil]
      end
      result = instance.delete_version(version_id: '1')
      expect(result[:deleted]).to be true
    end
  end

  describe '#merge_versions' do
    it 'merges a version into another' do
      stubs.put('/rest/api/3/version/1/mergeto/2') do
        [204, {}, nil]
      end
      result = instance.merge_versions(version_id: '1', move_issues_to: '2')
      expect(result[:merged]).to be true
    end
  end

  describe '#move_version' do
    it 'reorders a version' do
      stubs.post('/rest/api/3/version/1/move') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1' }]
      end
      result = instance.move_version(version_id: '1', position: 'First')
      expect(result[:version]['id']).to eq('1')
    end
  end
end
