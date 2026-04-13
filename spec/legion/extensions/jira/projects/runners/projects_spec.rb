# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/projects/runners/projects'

RSpec.describe Legion::Extensions::Jira::Projects::Runners::Projects do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_projects' do
    it 'returns all projects' do
      stubs.get('/rest/api/3/project') do
        [200, { 'Content-Type' => 'application/json' },
         [{ 'key' => 'PROJ', 'name' => 'My Project' }]]
      end
      result = instance.list_projects
      expect(result[:projects]).to be_an(Array)
    end
  end

  describe '#get_project' do
    it 'returns a project by key' do
      stubs.get('/rest/api/3/project/PROJ') do
        [200, { 'Content-Type' => 'application/json' }, { 'key' => 'PROJ', 'name' => 'My Project' }]
      end
      result = instance.get_project(project_key: 'PROJ')
      expect(result[:project]['key']).to eq('PROJ')
    end
  end

  describe '#create_project' do
    it 'creates a project' do
      stubs.post('/rest/api/3/project') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => '10000', 'key' => 'NEW' }]
      end
      result = instance.create_project(key: 'NEW', name: 'New Project', project_type_key: 'software', lead_account_id: 'abc')
      expect(result[:project]['key']).to eq('NEW')
    end
  end

  describe '#update_project' do
    it 'updates a project' do
      stubs.put('/rest/api/3/project/PROJ') do
        [200, { 'Content-Type' => 'application/json' }, { 'key' => 'PROJ', 'name' => 'Updated' }]
      end
      result = instance.update_project(project_key: 'PROJ', name: 'Updated')
      expect(result[:project]['name']).to eq('Updated')
    end
  end

  describe '#delete_project' do
    it 'deletes a project' do
      stubs.delete('/rest/api/3/project/PROJ') do
        [204, {}, nil]
      end
      result = instance.delete_project(project_key: 'PROJ')
      expect(result[:deleted]).to be true
    end
  end

  describe '#search_projects' do
    it 'returns paginated projects' do
      stubs.get('/rest/api/3/project/search') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'key' => 'PROJ' }], 'total' => 1 }]
      end
      result = instance.search_projects
      expect(result[:projects]['values']).to be_an(Array)
    end
  end

  describe '#get_project_statuses' do
    it 'returns statuses for a project' do
      stubs.get('/rest/api/3/project/PROJ/statuses') do
        [200, { 'Content-Type' => 'application/json' },
         [{ 'id' => '1', 'name' => 'Bug', 'statuses' => [{ 'name' => 'Open' }] }]]
      end
      result = instance.get_project_statuses(project_key: 'PROJ')
      expect(result[:statuses]).to be_an(Array)
    end
  end
end
