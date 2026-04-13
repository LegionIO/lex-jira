# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/projects/runners/components'

RSpec.describe Legion::Extensions::Jira::Projects::Runners::Components do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_project_components' do
    it 'returns components for a project' do
      stubs.get('/rest/api/3/project/PROJ/components') do
        [200, { 'Content-Type' => 'application/json' },
         [{ 'id' => '1', 'name' => 'Backend' }]]
      end
      result = instance.list_project_components(project_key: 'PROJ')
      expect(result[:components]).to be_an(Array)
    end
  end

  describe '#get_component' do
    it 'returns a component' do
      stubs.get('/rest/api/3/component/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'Backend' }]
      end
      result = instance.get_component(component_id: '1')
      expect(result[:component]['name']).to eq('Backend')
    end
  end

  describe '#create_component' do
    it 'creates a component' do
      stubs.post('/rest/api/3/component') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => '2', 'name' => 'Frontend' }]
      end
      result = instance.create_component(project_key: 'PROJ', name: 'Frontend')
      expect(result[:component]['name']).to eq('Frontend')
    end
  end

  describe '#update_component' do
    it 'updates a component' do
      stubs.put('/rest/api/3/component/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'API' }]
      end
      result = instance.update_component(component_id: '1', name: 'API')
      expect(result[:component]['name']).to eq('API')
    end
  end

  describe '#delete_component' do
    it 'deletes a component' do
      stubs.delete('/rest/api/3/component/1') do
        [204, {}, nil]
      end
      result = instance.delete_component(component_id: '1')
      expect(result[:deleted]).to be true
    end
  end
end
