# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/projects/runners/roles'

RSpec.describe Legion::Extensions::Jira::Projects::Runners::Roles do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_project_roles' do
    it 'returns roles for a project' do
      stubs.get('/rest/api/3/project/PROJ/role') do
        [200, { 'Content-Type' => 'application/json' },
         { 'Developers' => 'https://jira/rest/api/3/project/PROJ/role/10001' }]
      end
      result = instance.list_project_roles(project_key: 'PROJ')
      expect(result[:roles]).to have_key('Developers')
    end
  end

  describe '#get_project_role' do
    it 'returns a project role' do
      stubs.get('/rest/api/3/project/PROJ/role/10001') do
        [200, { 'Content-Type' => 'application/json' },
         { 'id' => 10_001, 'name' => 'Developers', 'actors' => [] }]
      end
      result = instance.get_project_role(project_key: 'PROJ', role_id: '10001')
      expect(result[:role]['name']).to eq('Developers')
    end
  end

  describe '#set_role_actors' do
    it 'replaces role actors' do
      stubs.put('/rest/api/3/project/PROJ/role/10001') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 10_001, 'actors' => [] }]
      end
      result = instance.set_role_actors(project_key: 'PROJ', role_id: '10001', user_account_ids: ['abc'])
      expect(result[:role]['id']).to eq(10_001)
    end
  end

  describe '#add_role_actors' do
    it 'adds actors to a role' do
      stubs.post('/rest/api/3/project/PROJ/role/10001') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 10_001, 'actors' => [{ 'actorUser' => {} }] }]
      end
      result = instance.add_role_actors(project_key: 'PROJ', role_id: '10001', user_account_ids: ['abc'])
      expect(result[:role]['actors']).to be_an(Array)
    end
  end

  describe '#remove_role_actor' do
    it 'removes an actor from a role' do
      stubs.delete('/rest/api/3/project/PROJ/role/10001') do
        [204, {}, nil]
      end
      result = instance.remove_role_actor(project_key: 'PROJ', role_id: '10001', user: 'abc')
      expect(result[:removed]).to be true
    end
  end
end
