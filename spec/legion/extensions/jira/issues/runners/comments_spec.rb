# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/comments'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Comments do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_issue_comments' do
    it 'returns comments for an issue' do
      stubs.get('/rest/api/3/issue/PROJ-1/comment') do
        [200, { 'Content-Type' => 'application/json' },
         { 'comments' => [{ 'id' => '100', 'body' => 'test' }], 'total' => 1 }]
      end
      result = instance.get_issue_comments(issue_key: 'PROJ-1')
      expect(result[:comments]['comments']).to be_an(Array)
    end
  end

  describe '#get_comment' do
    it 'returns a single comment' do
      stubs.get('/rest/api/3/issue/PROJ-1/comment/100') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '100', 'body' => 'test' }]
      end
      result = instance.get_comment(issue_key: 'PROJ-1', comment_id: '100')
      expect(result[:comment]['id']).to eq('100')
    end
  end

  describe '#add_comment' do
    it 'adds a comment' do
      stubs.post('/rest/api/3/issue/PROJ-1/comment') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => '101', 'body' => 'new' }]
      end
      result = instance.add_comment(issue_key: 'PROJ-1', body: 'new')
      expect(result[:comment]['id']).to eq('101')
    end
  end

  describe '#update_comment' do
    it 'updates a comment' do
      stubs.put('/rest/api/3/issue/PROJ-1/comment/100') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '100', 'body' => 'updated' }]
      end
      result = instance.update_comment(issue_key: 'PROJ-1', comment_id: '100', body: 'updated')
      expect(result[:comment]['body']).to eq('updated')
    end
  end

  describe '#delete_comment' do
    it 'deletes a comment' do
      stubs.delete('/rest/api/3/issue/PROJ-1/comment/100') do
        [204, {}, nil]
      end
      result = instance.delete_comment(issue_key: 'PROJ-1', comment_id: '100')
      expect(result[:deleted]).to be true
    end
  end
end
