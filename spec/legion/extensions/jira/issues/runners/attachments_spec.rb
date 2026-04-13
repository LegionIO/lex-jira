# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'faraday/multipart'
require 'legion/extensions/jira/issues/runners/attachments'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Attachments do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_attachments' do
    it 'returns attachments for an issue' do
      stubs.get('/rest/api/3/issue/PROJ-1') do
        [200, { 'Content-Type' => 'application/json' },
         { 'fields' => { 'attachment' => [{ 'id' => '1', 'filename' => 'test.txt' }] } }]
      end
      result = instance.get_attachments(issue_key: 'PROJ-1')
      expect(result[:attachments]).to be_an(Array)
    end
  end

  describe '#get_attachment' do
    it 'returns attachment metadata' do
      stubs.get('/rest/api/3/attachment/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'filename' => 'test.txt' }]
      end
      result = instance.get_attachment(attachment_id: '1')
      expect(result[:attachment]['filename']).to eq('test.txt')
    end
  end

  describe '#add_attachment' do
    it 'uploads an attachment' do
      upload_stubs = Faraday::Adapter::Test::Stubs.new
      upload_conn = Faraday.new(url: 'https://acme.atlassian.net') do |c|
        c.request :multipart
        c.response :json, content_type: /\bjson$/
        c.adapter :test, upload_stubs
      end
      allow(instance).to receive(:upload_connection).and_return(upload_conn)

      upload_stubs.post('/rest/api/3/issue/PROJ-1/attachments') do
        [200, { 'Content-Type' => 'application/json' }, [{ 'id' => '2', 'filename' => 'upload.txt' }]]
      end
      result = instance.add_attachment(issue_key: 'PROJ-1', file: StringIO.new('content'), filename: 'upload.txt')
      expect(result[:attachments].first['filename']).to eq('upload.txt')
    end
  end

  describe '#delete_attachment' do
    it 'deletes an attachment' do
      stubs.delete('/rest/api/3/attachment/1') do
        [204, {}, nil]
      end
      result = instance.delete_attachment(attachment_id: '1')
      expect(result[:deleted]).to be true
    end
  end

  describe '#get_attachment_meta' do
    it 'returns attachment settings' do
      stubs.get('/rest/api/3/attachment/meta') do
        [200, { 'Content-Type' => 'application/json' }, { 'enabled' => true, 'uploadLimit' => 10_485_760 }]
      end
      result = instance.get_attachment_meta
      expect(result[:meta]['enabled']).to be true
    end
  end
end
