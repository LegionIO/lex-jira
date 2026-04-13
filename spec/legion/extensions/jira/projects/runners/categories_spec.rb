# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/projects/runners/categories'

RSpec.describe Legion::Extensions::Jira::Projects::Runners::Categories do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_project_categories' do
    it 'returns all categories' do
      stubs.get('/rest/api/3/projectCategory') do
        [200, { 'Content-Type' => 'application/json' },
         [{ 'id' => '1', 'name' => 'Engineering' }]]
      end
      result = instance.list_project_categories
      expect(result[:categories]).to be_an(Array)
    end
  end

  describe '#get_project_category' do
    it 'returns a category' do
      stubs.get('/rest/api/3/projectCategory/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'Engineering' }]
      end
      result = instance.get_project_category(category_id: '1')
      expect(result[:category]['name']).to eq('Engineering')
    end
  end

  describe '#create_project_category' do
    it 'creates a category' do
      stubs.post('/rest/api/3/projectCategory') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => '2', 'name' => 'Marketing' }]
      end
      result = instance.create_project_category(name: 'Marketing')
      expect(result[:category]['name']).to eq('Marketing')
    end
  end

  describe '#update_project_category' do
    it 'updates a category' do
      stubs.put('/rest/api/3/projectCategory/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'Eng' }]
      end
      result = instance.update_project_category(category_id: '1', name: 'Eng')
      expect(result[:category]['name']).to eq('Eng')
    end
  end

  describe '#delete_project_category' do
    it 'deletes a category' do
      stubs.delete('/rest/api/3/projectCategory/1') do
        [204, {}, nil]
      end
      result = instance.delete_project_category(category_id: '1')
      expect(result[:deleted]).to be true
    end
  end
end
