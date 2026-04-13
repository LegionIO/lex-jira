# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/permissions/runners/permissions'

RSpec.describe Legion::Extensions::Jira::Permissions::Runners::Permissions do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_my_permissions' do
    it 'returns permissions for the current user' do
      stubs.get('/rest/api/3/mypermissions') do
        [200, { 'Content-Type' => 'application/json' },
         { 'permissions' => { 'BROWSE_PROJECTS' => { 'havePermission' => true } } }]
      end
      result = instance.get_my_permissions(permissions: 'BROWSE_PROJECTS')
      expect(result[:permissions]['permissions']).to have_key('BROWSE_PROJECTS')
    end
  end

  describe '#get_all_permissions' do
    it 'returns all system permissions' do
      stubs.get('/rest/api/3/permissions') do
        [200, { 'Content-Type' => 'application/json' },
         { 'permissions' => { 'BROWSE_PROJECTS' => { 'key' => 'BROWSE_PROJECTS' } } }]
      end
      result = instance.get_all_permissions
      expect(result[:permissions]['permissions']).to be_a(Hash)
    end
  end

  describe '#list_permission_schemes' do
    it 'returns permission schemes' do
      stubs.get('/rest/api/3/permissionscheme') do
        [200, { 'Content-Type' => 'application/json' },
         { 'permissionSchemes' => [{ 'id' => 1, 'name' => 'Default' }] }]
      end
      result = instance.list_permission_schemes
      expect(result[:schemes]['permissionSchemes']).to be_an(Array)
    end
  end

  describe '#get_permission_scheme' do
    it 'returns a permission scheme' do
      stubs.get('/rest/api/3/permissionscheme/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 1, 'name' => 'Default' }]
      end
      result = instance.get_permission_scheme(scheme_id: '1')
      expect(result[:scheme]['name']).to eq('Default')
    end
  end

  describe '#check_permissions' do
    it 'checks bulk permissions' do
      stubs.post('/rest/api/3/permissions/check') do
        [200, { 'Content-Type' => 'application/json' },
         { 'projectPermissions' => [{ 'permission' => 'BROWSE_PROJECTS', 'projects' => [10000] }] }]
      end
      result = instance.check_permissions(
        project_permissions: [{ permissions: ['BROWSE_PROJECTS'], projects: [10_000] }]
      )
      expect(result[:permissions]['projectPermissions']).to be_an(Array)
    end
  end
end
