# lex-jira Modularization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure lex-jira from 3 flat runners into 10 nested domain modules (27 runners, ~130 methods) covering Jira REST API v3 and Agile API.

**Architecture:** Each domain (Issues, Projects, Agile, etc.) gets its own namespace with `Runners::*` modules inside. A shared `Helpers::Client` provides the Faraday connection. The top-level `Client` class includes all runner modules for a unified interface. Specs use a shared test harness so each runner can be tested independently before Client integration.

**Tech Stack:** Ruby 3.4+, Faraday >= 2.0, faraday-multipart (for attachment uploads), RSpec

**Spec:** `docs/superpowers/specs/2026-04-13-jira-modularization-design.md`

---

## Shared Conventions

Every runner module in this plan follows this structure:

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module <Domain>
        module Runners
          module <Name>
            include Legion::Extensions::Jira::Helpers::Client

            # methods here

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

Every spec file follows this structure:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/<domain>/runners/<name>'

RSpec.describe Legion::Extensions::Jira::<Domain>::Runners::<Name> do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  # describe blocks per method
end
```

---

### Task 1: Foundation — directories, helpers, test harness, gemspec

**Files:**
- Modify: `lex-jira.gemspec`
- Modify: `lib/legion/extensions/jira/helpers/client.rb`
- Create: `spec/support/runner_test_harness.rb`

- [ ] **Step 1: Update gemspec — add faraday-multipart dependency**

```ruby
# In lex-jira.gemspec, add after the faraday line:
  spec.add_dependency 'faraday-multipart', '>= 1.0'
```

- [ ] **Step 2: Update helpers/client.rb — add upload_connection for multipart**

```ruby
# frozen_string_literal: true

require 'faraday'

module Legion
  module Extensions
    module Jira
      module Helpers
        module Client
          def connection(url: nil, email: nil, api_token: nil, **_opts)
            base_url = url || 'https://your-org.atlassian.net'
            Faraday.new(url: base_url) do |conn|
              conn.request :json
              conn.response :json, content_type: /\bjson$/
              conn.request :authorization, :basic, email, api_token if email && api_token
              conn.adapter Faraday.default_adapter
            end
          end

          def upload_connection(url: nil, email: nil, api_token: nil, **_opts)
            require 'faraday/multipart'
            base_url = url || 'https://your-org.atlassian.net'
            Faraday.new(url: base_url) do |conn|
              conn.request :multipart
              conn.request :url_encoded
              conn.response :json, content_type: /\bjson$/
              conn.request :authorization, :basic, email, api_token if email && api_token
              conn.headers['X-Atlassian-Token'] = 'no-check'
              conn.adapter Faraday.default_adapter
            end
          end
        end
      end
    end
  end
end
```

- [ ] **Step 3: Create spec/support/runner_test_harness.rb**

```ruby
# frozen_string_literal: true

module RunnerTestHarness
  def self.build(*runner_modules)
    klass = Class.new do
      include Legion::Extensions::Jira::Helpers::Client
      runner_modules.each { |mod| include mod }

      attr_reader :opts

      def initialize(**opts)
        @opts = opts
      end

      def connection(**override)
        super(**@opts.merge(override))
      end

      def upload_connection(**override)
        super(**@opts.merge(override))
      end
    end
    klass.new(url: 'https://acme.atlassian.net', email: 'user@example.com', api_token: 'secret-token')
  end

  def self.stub_connection
    stubs = Faraday::Adapter::Test::Stubs.new
    conn = Faraday.new(url: 'https://acme.atlassian.net') do |c|
      c.request :json
      c.response :json, content_type: /\bjson$/
      c.adapter :test, stubs
    end
    [stubs, conn]
  end
end
```

- [ ] **Step 4: Create directory structure**

Run:
```bash
mkdir -p lib/legion/extensions/jira/{issues,projects,users,groups,permissions,dashboards,filters,agile,webhooks,audit_records}/runners
mkdir -p spec/legion/extensions/jira/{issues,projects,users,groups,permissions,dashboards,filters,agile,webhooks,audit_records}/runners
mkdir -p spec/support
```

- [ ] **Step 5: Run existing specs to verify nothing is broken**

Run: `bundle install && bundle exec rspec`
Expected: All 16 examples pass.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "foundation: add directories, test harness, upload_connection helper"
```

---

### Task 2: Issues::Runners::Issues — core CRUD

**Files:**
- Create: `lib/legion/extensions/jira/issues/runners/issues.rb`
- Create: `spec/legion/extensions/jira/issues/runners/issues_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/issues'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Issues do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#create_issue' do
    it 'creates an issue' do
      stubs.post('/rest/api/3/issue') do
        [201, { 'Content-Type' => 'application/json' }, { 'key' => 'PROJ-1', 'id' => '10001' }]
      end
      result = instance.create_issue(project_key: 'PROJ', summary: 'Test', issue_type: 'Bug')
      expect(result[:issue]['key']).to eq('PROJ-1')
    end
  end

  describe '#get_issue' do
    it 'returns a single issue' do
      stubs.get('/rest/api/3/issue/PROJ-1') do
        [200, { 'Content-Type' => 'application/json' }, { 'key' => 'PROJ-1', 'fields' => {} }]
      end
      result = instance.get_issue(issue_key: 'PROJ-1')
      expect(result[:issue]['key']).to eq('PROJ-1')
    end
  end

  describe '#update_issue' do
    it 'returns updated true on 204' do
      stubs.put('/rest/api/3/issue/PROJ-1') do
        [204, {}, nil]
      end
      result = instance.update_issue(issue_key: 'PROJ-1', summary: 'Updated')
      expect(result[:updated]).to be true
    end
  end

  describe '#delete_issue' do
    it 'returns deleted true on 204' do
      stubs.delete('/rest/api/3/issue/PROJ-1') do
        [204, {}, nil]
      end
      result = instance.delete_issue(issue_key: 'PROJ-1')
      expect(result[:deleted]).to be true
    end
  end

  describe '#bulk_create_issues' do
    it 'creates multiple issues' do
      stubs.post('/rest/api/3/issue/bulk') do
        [201, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-1' }, { 'key' => 'PROJ-2' }] }]
      end
      issues = [{ project_key: 'PROJ', summary: 'One', issue_type: 'Task' },
                { project_key: 'PROJ', summary: 'Two', issue_type: 'Task' }]
      result = instance.bulk_create_issues(issues: issues)
      expect(result[:issues]['issues'].length).to eq(2)
    end
  end

  describe '#get_issue_changelog' do
    it 'returns changelog entries' do
      stubs.get('/rest/api/3/issue/PROJ-1/changelog') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'id' => '100' }], 'total' => 1 }]
      end
      result = instance.get_issue_changelog(issue_key: 'PROJ-1')
      expect(result[:changelog]['values']).to be_an(Array)
    end
  end
end
```

- [ ] **Step 2: Run spec to verify it fails**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/issues_spec.rb`
Expected: FAIL — `uninitialized constant Legion::Extensions::Jira::Issues`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Issues
            include Legion::Extensions::Jira::Helpers::Client

            def create_issue(project_key:, summary:, issue_type: 'Task', description: nil,
                             assignee: nil, priority: nil, labels: nil, **)
              body = {
                fields: {
                  project:   { key: project_key },
                  summary:   summary,
                  issuetype: { name: issue_type }
                }
              }
              body[:fields][:description] = description if description
              body[:fields][:assignee]    = { accountId: assignee } if assignee
              body[:fields][:priority]    = { name: priority } if priority
              body[:fields][:labels]      = labels if labels
              resp = connection(**).post('/rest/api/3/issue', body)
              { issue: resp.body }
            end

            def get_issue(issue_key:, fields: nil, expand: nil, **)
              params = {}
              params[:fields] = fields if fields
              params[:expand] = expand if expand
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}", params)
              { issue: resp.body }
            end

            def update_issue(issue_key:, summary: nil, description: nil, assignee: nil, priority: nil, **)
              fields = {}
              fields[:summary]     = summary if summary
              fields[:description] = description if description
              fields[:assignee]    = { accountId: assignee } if assignee
              fields[:priority]    = { name: priority } if priority
              resp = connection(**).put("/rest/api/3/issue/#{issue_key}", { fields: fields })
              { updated: resp.status == 204, issue_key: issue_key }
            end

            def delete_issue(issue_key:, delete_subtasks: false, **)
              params = {}
              params[:deleteSubtasks] = true if delete_subtasks
              resp = connection(**).delete("/rest/api/3/issue/#{issue_key}") do |req|
                req.params = params
              end
              { deleted: resp.status == 204, issue_key: issue_key }
            end

            def bulk_create_issues(issues:, **)
              issue_updates = issues.map do |i|
                {
                  fields: {
                    project:   { key: i[:project_key] },
                    summary:   i[:summary],
                    issuetype: { name: i[:issue_type] || 'Task' }
                  }
                }
              end
              resp = connection(**).post('/rest/api/3/issue/bulk', { issueUpdates: issue_updates })
              { issues: resp.body }
            end

            def get_issue_changelog(issue_key:, start_at: 0, max_results: 100, **)
              params = { startAt: start_at, maxResults: max_results }
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/changelog", params)
              { changelog: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec to verify it passes**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/issues_spec.rb`
Expected: 6 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/issues/runners/issues.rb spec/legion/extensions/jira/issues/runners/issues_spec.rb
git commit -m "feat: add Issues::Runners::Issues — core CRUD, bulk create, changelog"
```

---

### Task 3: Issues::Runners::Search

**Files:**
- Create: `lib/legion/extensions/jira/issues/runners/search.rb`
- Create: `spec/legion/extensions/jira/issues/runners/search_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/search'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Search do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#search_issues' do
    it 'returns issues matching JQL' do
      stubs.get('/rest/api/3/search') do
        [200, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-1' }], 'total' => 1 }]
      end
      result = instance.search_issues(jql: 'project = PROJ')
      expect(result[:issues]['issues']).to be_an(Array)
    end
  end

  describe '#pick_issues' do
    it 'returns suggested issues' do
      stubs.get('/rest/api/3/issue/picker') do
        [200, { 'Content-Type' => 'application/json' },
         { 'sections' => [{ 'issues' => [{ 'key' => 'PROJ-1' }] }] }]
      end
      result = instance.pick_issues(query: 'test')
      expect(result[:suggestions]['sections']).to be_an(Array)
    end
  end

  describe '#parse_jql' do
    it 'parses JQL queries' do
      stubs.post('/rest/api/3/jql/parse') do
        [200, { 'Content-Type' => 'application/json' },
         { 'queries' => [{ 'query' => 'project = PROJ', 'errors' => [] }] }]
      end
      result = instance.parse_jql(queries: ['project = PROJ'])
      expect(result[:parsed]['queries'].first['errors']).to be_empty
    end
  end

  describe '#autocomplete_jql' do
    it 'returns autocomplete suggestions' do
      stubs.get('/rest/api/3/jql/autocompletedata') do
        [200, { 'Content-Type' => 'application/json' },
         { 'visibleFieldNames' => [{ 'value' => 'project' }] }]
      end
      result = instance.autocomplete_jql
      expect(result[:suggestions]).to have_key('visibleFieldNames')
    end
  end
end
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/search_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Search
            include Legion::Extensions::Jira::Helpers::Client

            def search_issues(jql:, max_results: 50, start_at: 0, fields: nil, expand: nil, **)
              params = { jql: jql, maxResults: max_results, startAt: start_at }
              params[:fields] = fields if fields
              params[:expand] = expand if expand
              resp = connection(**).get('/rest/api/3/search', params)
              { issues: resp.body }
            end

            def pick_issues(query: nil, current_jql: nil, **)
              params = {}
              params[:query] = query if query
              params[:currentJQL] = current_jql if current_jql
              resp = connection(**).get('/rest/api/3/issue/picker', params)
              { suggestions: resp.body }
            end

            def parse_jql(queries:, **)
              resp = connection(**).post('/rest/api/3/jql/parse', { queries: queries })
              { parsed: resp.body }
            end

            def autocomplete_jql(**)
              resp = connection(**).get('/rest/api/3/jql/autocompletedata')
              { suggestions: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/search_spec.rb`
Expected: 4 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/issues/runners/search.rb spec/legion/extensions/jira/issues/runners/search_spec.rb
git commit -m "feat: add Issues::Runners::Search — JQL search, picker, parse, autocomplete"
```

---

### Task 4: Issues::Runners::Comments

**Files:**
- Create: `lib/legion/extensions/jira/issues/runners/comments.rb`
- Create: `spec/legion/extensions/jira/issues/runners/comments_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
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
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/comments_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Comments
            include Legion::Extensions::Jira::Helpers::Client

            def get_issue_comments(issue_key:, start_at: 0, max_results: 50, order_by: nil, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:orderBy] = order_by if order_by
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/comment", params)
              { comments: resp.body }
            end

            def get_comment(issue_key:, comment_id:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/comment/#{comment_id}")
              { comment: resp.body }
            end

            def add_comment(issue_key:, body:, **)
              resp = connection(**).post("/rest/api/3/issue/#{issue_key}/comment", { body: body })
              { comment: resp.body }
            end

            def update_comment(issue_key:, comment_id:, body:, **)
              resp = connection(**).put("/rest/api/3/issue/#{issue_key}/comment/#{comment_id}", { body: body })
              { comment: resp.body }
            end

            def delete_comment(issue_key:, comment_id:, **)
              resp = connection(**).delete("/rest/api/3/issue/#{issue_key}/comment/#{comment_id}")
              { deleted: resp.status == 204, issue_key: issue_key, comment_id: comment_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/comments_spec.rb`
Expected: 5 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/issues/runners/comments.rb spec/legion/extensions/jira/issues/runners/comments_spec.rb
git commit -m "feat: add Issues::Runners::Comments — CRUD for issue comments"
```

---

### Task 5: Issues::Runners::Transitions

**Files:**
- Create: `lib/legion/extensions/jira/issues/runners/transitions.rb`
- Create: `spec/legion/extensions/jira/issues/runners/transitions_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/transitions'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Transitions do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_transitions' do
    it 'returns available transitions' do
      stubs.get('/rest/api/3/issue/PROJ-1/transitions') do
        [200, { 'Content-Type' => 'application/json' },
         { 'transitions' => [{ 'id' => '31', 'name' => 'Done' }] }]
      end
      result = instance.get_transitions(issue_key: 'PROJ-1')
      expect(result[:transitions]['transitions']).to be_an(Array)
    end
  end

  describe '#transition_issue' do
    it 'returns transitioned true on 204' do
      stubs.post('/rest/api/3/issue/PROJ-1/transitions') do
        [204, {}, nil]
      end
      result = instance.transition_issue(issue_key: 'PROJ-1', transition_id: '31')
      expect(result[:transitioned]).to be true
    end
  end
end
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/transitions_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Transitions
            include Legion::Extensions::Jira::Helpers::Client

            def get_transitions(issue_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/transitions")
              { transitions: resp.body }
            end

            def transition_issue(issue_key:, transition_id:, fields: nil, **)
              body = { transition: { id: transition_id.to_s } }
              body[:fields] = fields if fields
              resp = connection(**).post("/rest/api/3/issue/#{issue_key}/transitions", body)
              { transitioned: resp.status == 204, issue_key: issue_key }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/transitions_spec.rb`
Expected: 2 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/issues/runners/transitions.rb spec/legion/extensions/jira/issues/runners/transitions_spec.rb
git commit -m "feat: add Issues::Runners::Transitions — get and perform transitions"
```

---

### Task 6: Issues::Runners::Attachments

**Files:**
- Create: `lib/legion/extensions/jira/issues/runners/attachments.rb`
- Create: `spec/legion/extensions/jira/issues/runners/attachments_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
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
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/attachments_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Attachments
            include Legion::Extensions::Jira::Helpers::Client

            def get_attachments(issue_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}", { fields: 'attachment' })
              { attachments: resp.body.dig('fields', 'attachment') || [] }
            end

            def get_attachment(attachment_id:, **)
              resp = connection(**).get("/rest/api/3/attachment/#{attachment_id}")
              { attachment: resp.body }
            end

            def add_attachment(issue_key:, file:, filename: 'file', content_type: 'application/octet-stream', **)
              payload = { file: Faraday::Multipart::FilePart.new(file, content_type, filename) }
              resp = upload_connection(**).post("/rest/api/3/issue/#{issue_key}/attachments", payload)
              { attachments: resp.body }
            end

            def delete_attachment(attachment_id:, **)
              resp = connection(**).delete("/rest/api/3/attachment/#{attachment_id}")
              { deleted: resp.status == 204, attachment_id: attachment_id }
            end

            def get_attachment_meta(**)
              resp = connection(**).get('/rest/api/3/attachment/meta')
              { meta: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/attachments_spec.rb`
Expected: 5 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/issues/runners/attachments.rb spec/legion/extensions/jira/issues/runners/attachments_spec.rb
git commit -m "feat: add Issues::Runners::Attachments — get, upload, delete, meta"
```

---

### Task 7: Issues::Runners::Worklogs

**Files:**
- Create: `lib/legion/extensions/jira/issues/runners/worklogs.rb`
- Create: `spec/legion/extensions/jira/issues/runners/worklogs_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/worklogs'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Worklogs do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_issue_worklogs' do
    it 'returns worklogs for an issue' do
      stubs.get('/rest/api/3/issue/PROJ-1/worklog') do
        [200, { 'Content-Type' => 'application/json' },
         { 'worklogs' => [{ 'id' => '1', 'timeSpent' => '2h' }], 'total' => 1 }]
      end
      result = instance.get_issue_worklogs(issue_key: 'PROJ-1')
      expect(result[:worklogs]['worklogs']).to be_an(Array)
    end
  end

  describe '#get_worklog' do
    it 'returns a single worklog' do
      stubs.get('/rest/api/3/issue/PROJ-1/worklog/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'timeSpent' => '2h' }]
      end
      result = instance.get_worklog(issue_key: 'PROJ-1', worklog_id: '1')
      expect(result[:worklog]['id']).to eq('1')
    end
  end

  describe '#add_worklog' do
    it 'adds a worklog entry' do
      stubs.post('/rest/api/3/issue/PROJ-1/worklog') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => '2', 'timeSpent' => '1h' }]
      end
      result = instance.add_worklog(issue_key: 'PROJ-1', time_spent: '1h')
      expect(result[:worklog]['timeSpent']).to eq('1h')
    end
  end

  describe '#update_worklog' do
    it 'updates a worklog entry' do
      stubs.put('/rest/api/3/issue/PROJ-1/worklog/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'timeSpent' => '3h' }]
      end
      result = instance.update_worklog(issue_key: 'PROJ-1', worklog_id: '1', time_spent: '3h')
      expect(result[:worklog]['timeSpent']).to eq('3h')
    end
  end

  describe '#delete_worklog' do
    it 'deletes a worklog entry' do
      stubs.delete('/rest/api/3/issue/PROJ-1/worklog/1') do
        [204, {}, nil]
      end
      result = instance.delete_worklog(issue_key: 'PROJ-1', worklog_id: '1')
      expect(result[:deleted]).to be true
    end
  end
end
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/worklogs_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Worklogs
            include Legion::Extensions::Jira::Helpers::Client

            def get_issue_worklogs(issue_key:, start_at: 0, max_results: 5000, **)
              params = { startAt: start_at, maxResults: max_results }
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/worklog", params)
              { worklogs: resp.body }
            end

            def get_worklog(issue_key:, worklog_id:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/worklog/#{worklog_id}")
              { worklog: resp.body }
            end

            def add_worklog(issue_key:, time_spent:, comment: nil, started: nil, **)
              body = { timeSpent: time_spent }
              body[:comment] = comment if comment
              body[:started] = started if started
              resp = connection(**).post("/rest/api/3/issue/#{issue_key}/worklog", body)
              { worklog: resp.body }
            end

            def update_worklog(issue_key:, worklog_id:, time_spent: nil, comment: nil, **)
              body = {}
              body[:timeSpent] = time_spent if time_spent
              body[:comment] = comment if comment
              resp = connection(**).put("/rest/api/3/issue/#{issue_key}/worklog/#{worklog_id}", body)
              { worklog: resp.body }
            end

            def delete_worklog(issue_key:, worklog_id:, **)
              resp = connection(**).delete("/rest/api/3/issue/#{issue_key}/worklog/#{worklog_id}")
              { deleted: resp.status == 204, issue_key: issue_key, worklog_id: worklog_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/worklogs_spec.rb`
Expected: 5 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/issues/runners/worklogs.rb spec/legion/extensions/jira/issues/runners/worklogs_spec.rb
git commit -m "feat: add Issues::Runners::Worklogs — time log CRUD"
```

---

### Task 8: Issues::Runners::Links

**Files:**
- Create: `lib/legion/extensions/jira/issues/runners/links.rb`
- Create: `spec/legion/extensions/jira/issues/runners/links_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
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
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/links_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Links
            include Legion::Extensions::Jira::Helpers::Client

            def create_issue_link(type_name:, inward_issue:, outward_issue:, comment: nil, **)
              body = {
                type: { name: type_name },
                inwardIssue: { key: inward_issue },
                outwardIssue: { key: outward_issue }
              }
              body[:comment] = { body: comment } if comment
              resp = connection(**).post('/rest/api/3/issueLink', body)
              { created: resp.status == 201 }
            end

            def get_issue_link(link_id:, **)
              resp = connection(**).get("/rest/api/3/issueLink/#{link_id}")
              { link: resp.body }
            end

            def delete_issue_link(link_id:, **)
              resp = connection(**).delete("/rest/api/3/issueLink/#{link_id}")
              { deleted: resp.status == 204, link_id: link_id }
            end

            def list_link_types(**)
              resp = connection(**).get('/rest/api/3/issueLinkType')
              { link_types: resp.body }
            end

            def get_link_type(link_type_id:, **)
              resp = connection(**).get("/rest/api/3/issueLinkType/#{link_type_id}")
              { link_type: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/links_spec.rb`
Expected: 5 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/issues/runners/links.rb spec/legion/extensions/jira/issues/runners/links_spec.rb
git commit -m "feat: add Issues::Runners::Links — issue links and link types"
```

---

### Task 9: Issues::Runners::RemoteLinks

**Files:**
- Create: `lib/legion/extensions/jira/issues/runners/remote_links.rb`
- Create: `spec/legion/extensions/jira/issues/runners/remote_links_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
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
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/remote_links_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module RemoteLinks
            include Legion::Extensions::Jira::Helpers::Client

            def get_remote_links(issue_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/remotelink")
              { remote_links: resp.body }
            end

            def get_remote_link(issue_key:, link_id:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/remotelink/#{link_id}")
              { remote_link: resp.body }
            end

            def create_remote_link(issue_key:, url:, title:, summary: nil, **)
              body = { object: { url: url, title: title } }
              body[:object][:summary] = summary if summary
              resp = connection(**).post("/rest/api/3/issue/#{issue_key}/remotelink", body)
              { remote_link: resp.body }
            end

            def update_remote_link(issue_key:, link_id:, url:, title:, summary: nil, **)
              body = { object: { url: url, title: title } }
              body[:object][:summary] = summary if summary
              resp = connection(**).put("/rest/api/3/issue/#{issue_key}/remotelink/#{link_id}", body)
              { updated: resp.status == 204, issue_key: issue_key, link_id: link_id }
            end

            def delete_remote_link(issue_key:, link_id:, **)
              resp = connection(**).delete("/rest/api/3/issue/#{issue_key}/remotelink/#{link_id}")
              { deleted: resp.status == 204, issue_key: issue_key, link_id: link_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/remote_links_spec.rb`
Expected: 5 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/issues/runners/remote_links.rb spec/legion/extensions/jira/issues/runners/remote_links_spec.rb
git commit -m "feat: add Issues::Runners::RemoteLinks — external URL links on issues"
```

---

### Task 10: Issues::Runners::Votes + Watchers + Properties

Three small runners grouped together.

**Files:**
- Create: `lib/legion/extensions/jira/issues/runners/votes.rb`
- Create: `lib/legion/extensions/jira/issues/runners/watchers.rb`
- Create: `lib/legion/extensions/jira/issues/runners/properties.rb`
- Create: `spec/legion/extensions/jira/issues/runners/votes_spec.rb`
- Create: `spec/legion/extensions/jira/issues/runners/watchers_spec.rb`
- Create: `spec/legion/extensions/jira/issues/runners/properties_spec.rb`

- [ ] **Step 1: Write votes spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/votes'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Votes do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_votes' do
    it 'returns vote info' do
      stubs.get('/rest/api/3/issue/PROJ-1/votes') do
        [200, { 'Content-Type' => 'application/json' }, { 'votes' => 3, 'hasVoted' => false }]
      end
      result = instance.get_votes(issue_key: 'PROJ-1')
      expect(result[:votes]['votes']).to eq(3)
    end
  end

  describe '#add_vote' do
    it 'adds a vote' do
      stubs.post('/rest/api/3/issue/PROJ-1/votes') do
        [204, {}, nil]
      end
      result = instance.add_vote(issue_key: 'PROJ-1')
      expect(result[:voted]).to be true
    end
  end

  describe '#remove_vote' do
    it 'removes a vote' do
      stubs.delete('/rest/api/3/issue/PROJ-1/votes') do
        [204, {}, nil]
      end
      result = instance.remove_vote(issue_key: 'PROJ-1')
      expect(result[:removed]).to be true
    end
  end
end
```

- [ ] **Step 2: Write votes implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Votes
            include Legion::Extensions::Jira::Helpers::Client

            def get_votes(issue_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/votes")
              { votes: resp.body }
            end

            def add_vote(issue_key:, **)
              resp = connection(**).post("/rest/api/3/issue/#{issue_key}/votes")
              { voted: resp.status == 204, issue_key: issue_key }
            end

            def remove_vote(issue_key:, **)
              resp = connection(**).delete("/rest/api/3/issue/#{issue_key}/votes")
              { removed: resp.status == 204, issue_key: issue_key }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 3: Write watchers spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/watchers'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Watchers do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_watchers' do
    it 'returns watchers' do
      stubs.get('/rest/api/3/issue/PROJ-1/watchers') do
        [200, { 'Content-Type' => 'application/json' },
         { 'watchCount' => 1, 'watchers' => [{ 'accountId' => 'abc123' }] }]
      end
      result = instance.get_watchers(issue_key: 'PROJ-1')
      expect(result[:watchers]['watchers']).to be_an(Array)
    end
  end

  describe '#add_watcher' do
    it 'adds a watcher' do
      stubs.post('/rest/api/3/issue/PROJ-1/watchers') do
        [204, {}, nil]
      end
      result = instance.add_watcher(issue_key: 'PROJ-1', account_id: 'abc123')
      expect(result[:added]).to be true
    end
  end

  describe '#remove_watcher' do
    it 'removes a watcher' do
      stubs.delete('/rest/api/3/issue/PROJ-1/watchers') do
        [204, {}, nil]
      end
      result = instance.remove_watcher(issue_key: 'PROJ-1', account_id: 'abc123')
      expect(result[:removed]).to be true
    end
  end
end
```

- [ ] **Step 4: Write watchers implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Watchers
            include Legion::Extensions::Jira::Helpers::Client

            def get_watchers(issue_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/watchers")
              { watchers: resp.body }
            end

            def add_watcher(issue_key:, account_id:, **)
              resp = connection(**).post("/rest/api/3/issue/#{issue_key}/watchers", account_id.to_json)
              { added: resp.status == 204, issue_key: issue_key }
            end

            def remove_watcher(issue_key:, account_id:, **)
              resp = connection(**).delete("/rest/api/3/issue/#{issue_key}/watchers") do |req|
                req.params['accountId'] = account_id
              end
              { removed: resp.status == 204, issue_key: issue_key }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 5: Write properties spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/issues/runners/properties'

RSpec.describe Legion::Extensions::Jira::Issues::Runners::Properties do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_issue_properties' do
    it 'returns property keys' do
      stubs.get('/rest/api/3/issue/PROJ-1/properties') do
        [200, { 'Content-Type' => 'application/json' },
         { 'keys' => [{ 'key' => 'my.prop' }] }]
      end
      result = instance.get_issue_properties(issue_key: 'PROJ-1')
      expect(result[:properties]['keys']).to be_an(Array)
    end
  end

  describe '#get_issue_property' do
    it 'returns a property value' do
      stubs.get('/rest/api/3/issue/PROJ-1/properties/my.prop') do
        [200, { 'Content-Type' => 'application/json' }, { 'key' => 'my.prop', 'value' => { 'count' => 5 } }]
      end
      result = instance.get_issue_property(issue_key: 'PROJ-1', property_key: 'my.prop')
      expect(result[:property]['key']).to eq('my.prop')
    end
  end

  describe '#set_issue_property' do
    it 'sets a property value' do
      stubs.put('/rest/api/3/issue/PROJ-1/properties/my.prop') do
        [200, {}, nil]
      end
      result = instance.set_issue_property(issue_key: 'PROJ-1', property_key: 'my.prop', value: { count: 10 })
      expect(result[:set]).to be true
    end
  end

  describe '#delete_issue_property' do
    it 'deletes a property' do
      stubs.delete('/rest/api/3/issue/PROJ-1/properties/my.prop') do
        [204, {}, nil]
      end
      result = instance.delete_issue_property(issue_key: 'PROJ-1', property_key: 'my.prop')
      expect(result[:deleted]).to be true
    end
  end
end
```

- [ ] **Step 6: Write properties implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Properties
            include Legion::Extensions::Jira::Helpers::Client

            def get_issue_properties(issue_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/properties")
              { properties: resp.body }
            end

            def get_issue_property(issue_key:, property_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/properties/#{property_key}")
              { property: resp.body }
            end

            def set_issue_property(issue_key:, property_key:, value:, **)
              resp = connection(**).put("/rest/api/3/issue/#{issue_key}/properties/#{property_key}", value)
              { set: [200, 201].include?(resp.status), issue_key: issue_key, property_key: property_key }
            end

            def delete_issue_property(issue_key:, property_key:, **)
              resp = connection(**).delete("/rest/api/3/issue/#{issue_key}/properties/#{property_key}")
              { deleted: resp.status == 204, issue_key: issue_key, property_key: property_key }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 7: Run all three specs**

Run: `bundle exec rspec spec/legion/extensions/jira/issues/runners/votes_spec.rb spec/legion/extensions/jira/issues/runners/watchers_spec.rb spec/legion/extensions/jira/issues/runners/properties_spec.rb`
Expected: 10 examples, 0 failures

- [ ] **Step 8: Commit**

```bash
git add lib/legion/extensions/jira/issues/runners/votes.rb lib/legion/extensions/jira/issues/runners/watchers.rb lib/legion/extensions/jira/issues/runners/properties.rb spec/legion/extensions/jira/issues/runners/votes_spec.rb spec/legion/extensions/jira/issues/runners/watchers_spec.rb spec/legion/extensions/jira/issues/runners/properties_spec.rb
git commit -m "feat: add Issues::Runners::Votes, Watchers, Properties"
```

---

### Task 11: Projects::Runners::Projects

**Files:**
- Create: `lib/legion/extensions/jira/projects/runners/projects.rb`
- Create: `spec/legion/extensions/jira/projects/runners/projects_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
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
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/projects/runners/projects_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Projects
        module Runners
          module Projects
            include Legion::Extensions::Jira::Helpers::Client

            def list_projects(expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get('/rest/api/3/project', params)
              { projects: resp.body }
            end

            def get_project(project_key:, expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get("/rest/api/3/project/#{project_key}", params)
              { project: resp.body }
            end

            def create_project(key:, name:, project_type_key:, lead_account_id:, description: nil, **)
              body = { key: key, name: name, projectTypeKey: project_type_key, leadAccountId: lead_account_id }
              body[:description] = description if description
              resp = connection(**).post('/rest/api/3/project', body)
              { project: resp.body }
            end

            def update_project(project_key:, name: nil, description: nil, lead_account_id: nil, **)
              body = {}
              body[:name] = name if name
              body[:description] = description if description
              body[:leadAccountId] = lead_account_id if lead_account_id
              resp = connection(**).put("/rest/api/3/project/#{project_key}", body)
              { project: resp.body }
            end

            def delete_project(project_key:, **)
              resp = connection(**).delete("/rest/api/3/project/#{project_key}")
              { deleted: resp.status == 204, project_key: project_key }
            end

            def search_projects(query: nil, start_at: 0, max_results: 50, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:query] = query if query
              resp = connection(**).get('/rest/api/3/project/search', params)
              { projects: resp.body }
            end

            def get_project_statuses(project_key:, **)
              resp = connection(**).get("/rest/api/3/project/#{project_key}/statuses")
              { statuses: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/projects/runners/projects_spec.rb`
Expected: 7 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/projects/runners/projects.rb spec/legion/extensions/jira/projects/runners/projects_spec.rb
git commit -m "feat: add Projects::Runners::Projects — CRUD, search, statuses"
```

---

### Task 12: Projects::Runners::Components

**Files:**
- Create: `lib/legion/extensions/jira/projects/runners/components.rb`
- Create: `spec/legion/extensions/jira/projects/runners/components_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
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
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/projects/runners/components_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Projects
        module Runners
          module Components
            include Legion::Extensions::Jira::Helpers::Client

            def list_project_components(project_key:, **)
              resp = connection(**).get("/rest/api/3/project/#{project_key}/components")
              { components: resp.body }
            end

            def get_component(component_id:, **)
              resp = connection(**).get("/rest/api/3/component/#{component_id}")
              { component: resp.body }
            end

            def create_component(project_key:, name:, description: nil, lead_account_id: nil, **)
              body = { project: project_key, name: name }
              body[:description] = description if description
              body[:leadAccountId] = lead_account_id if lead_account_id
              resp = connection(**).post('/rest/api/3/component', body)
              { component: resp.body }
            end

            def update_component(component_id:, name: nil, description: nil, lead_account_id: nil, **)
              body = {}
              body[:name] = name if name
              body[:description] = description if description
              body[:leadAccountId] = lead_account_id if lead_account_id
              resp = connection(**).put("/rest/api/3/component/#{component_id}", body)
              { component: resp.body }
            end

            def delete_component(component_id:, move_issues_to: nil, **)
              params = {}
              params[:moveIssuesTo] = move_issues_to if move_issues_to
              resp = connection(**).delete("/rest/api/3/component/#{component_id}") do |req|
                req.params = params
              end
              { deleted: resp.status == 204, component_id: component_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/projects/runners/components_spec.rb`
Expected: 5 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/projects/runners/components.rb spec/legion/extensions/jira/projects/runners/components_spec.rb
git commit -m "feat: add Projects::Runners::Components — component CRUD"
```

---

### Task 13: Projects::Runners::Versions

**Files:**
- Create: `lib/legion/extensions/jira/projects/runners/versions.rb`
- Create: `spec/legion/extensions/jira/projects/runners/versions_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
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
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/projects/runners/versions_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Projects
        module Runners
          module Versions
            include Legion::Extensions::Jira::Helpers::Client

            def list_project_versions(project_key:, **)
              resp = connection(**).get("/rest/api/3/project/#{project_key}/versions")
              { versions: resp.body }
            end

            def get_version(version_id:, **)
              resp = connection(**).get("/rest/api/3/version/#{version_id}")
              { version: resp.body }
            end

            def create_version(project_id:, name:, description: nil, released: nil, start_date: nil,
                               release_date: nil, **)
              body = { projectId: project_id, name: name }
              body[:description] = description if description
              body[:released] = released unless released.nil?
              body[:startDate] = start_date if start_date
              body[:releaseDate] = release_date if release_date
              resp = connection(**).post('/rest/api/3/version', body)
              { version: resp.body }
            end

            def update_version(version_id:, name: nil, description: nil, released: nil, **)
              body = {}
              body[:name] = name if name
              body[:description] = description if description
              body[:released] = released unless released.nil?
              resp = connection(**).put("/rest/api/3/version/#{version_id}", body)
              { version: resp.body }
            end

            def delete_version(version_id:, move_fixed_issues_to: nil, move_affected_issues_to: nil, **)
              params = {}
              params[:moveFixIssuesTo] = move_fixed_issues_to if move_fixed_issues_to
              params[:moveAffectedIssuesTo] = move_affected_issues_to if move_affected_issues_to
              resp = connection(**).delete("/rest/api/3/version/#{version_id}") do |req|
                req.params = params
              end
              { deleted: resp.status == 204, version_id: version_id }
            end

            def merge_versions(version_id:, move_issues_to:, **)
              resp = connection(**).put("/rest/api/3/version/#{version_id}/mergeto/#{move_issues_to}")
              { merged: resp.status == 204, version_id: version_id }
            end

            def move_version(version_id:, position: nil, after: nil, **)
              body = {}
              body[:position] = position if position
              body[:after] = after if after
              resp = connection(**).post("/rest/api/3/version/#{version_id}/move", body)
              { version: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/projects/runners/versions_spec.rb`
Expected: 7 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/projects/runners/versions.rb spec/legion/extensions/jira/projects/runners/versions_spec.rb
git commit -m "feat: add Projects::Runners::Versions — version CRUD, merge, move"
```

---

### Task 14: Projects::Runners::Roles + Categories

**Files:**
- Create: `lib/legion/extensions/jira/projects/runners/roles.rb`
- Create: `lib/legion/extensions/jira/projects/runners/categories.rb`
- Create: `spec/legion/extensions/jira/projects/runners/roles_spec.rb`
- Create: `spec/legion/extensions/jira/projects/runners/categories_spec.rb`

- [ ] **Step 1: Write roles spec**

```ruby
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
         { 'id' => 10001, 'name' => 'Developers', 'actors' => [] }]
      end
      result = instance.get_project_role(project_key: 'PROJ', role_id: '10001')
      expect(result[:role]['name']).to eq('Developers')
    end
  end

  describe '#set_role_actors' do
    it 'replaces role actors' do
      stubs.put('/rest/api/3/project/PROJ/role/10001') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 10001, 'actors' => [] }]
      end
      result = instance.set_role_actors(project_key: 'PROJ', role_id: '10001', user_account_ids: ['abc'])
      expect(result[:role]['id']).to eq(10001)
    end
  end

  describe '#add_role_actors' do
    it 'adds actors to a role' do
      stubs.post('/rest/api/3/project/PROJ/role/10001') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 10001, 'actors' => [{ 'actorUser' => {} }] }]
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
```

- [ ] **Step 2: Write roles implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Projects
        module Runners
          module Roles
            include Legion::Extensions::Jira::Helpers::Client

            def list_project_roles(project_key:, **)
              resp = connection(**).get("/rest/api/3/project/#{project_key}/role")
              { roles: resp.body }
            end

            def get_project_role(project_key:, role_id:, **)
              resp = connection(**).get("/rest/api/3/project/#{project_key}/role/#{role_id}")
              { role: resp.body }
            end

            def set_role_actors(project_key:, role_id:, user_account_ids: [], group_names: [], **)
              body = {}
              body['atlassian-user-role-actor'] = user_account_ids unless user_account_ids.empty?
              body['atlassian-group-role-actor'] = group_names unless group_names.empty?
              resp = connection(**).put("/rest/api/3/project/#{project_key}/role/#{role_id}",
                                       { categorisedActors: body })
              { role: resp.body }
            end

            def add_role_actors(project_key:, role_id:, user_account_ids: [], group_names: [], **)
              body = {}
              body[:user] = user_account_ids unless user_account_ids.empty?
              body[:group] = group_names unless group_names.empty?
              resp = connection(**).post("/rest/api/3/project/#{project_key}/role/#{role_id}", body)
              { role: resp.body }
            end

            def remove_role_actor(project_key:, role_id:, user: nil, group: nil, **)
              resp = connection(**).delete("/rest/api/3/project/#{project_key}/role/#{role_id}") do |req|
                req.params['user'] = user if user
                req.params['group'] = group if group
              end
              { removed: resp.status == 204, project_key: project_key, role_id: role_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 3: Write categories spec**

```ruby
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
```

- [ ] **Step 4: Write categories implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Projects
        module Runners
          module Categories
            include Legion::Extensions::Jira::Helpers::Client

            def list_project_categories(**)
              resp = connection(**).get('/rest/api/3/projectCategory')
              { categories: resp.body }
            end

            def get_project_category(category_id:, **)
              resp = connection(**).get("/rest/api/3/projectCategory/#{category_id}")
              { category: resp.body }
            end

            def create_project_category(name:, description: nil, **)
              body = { name: name }
              body[:description] = description if description
              resp = connection(**).post('/rest/api/3/projectCategory', body)
              { category: resp.body }
            end

            def update_project_category(category_id:, name: nil, description: nil, **)
              body = {}
              body[:name] = name if name
              body[:description] = description if description
              resp = connection(**).put("/rest/api/3/projectCategory/#{category_id}", body)
              { category: resp.body }
            end

            def delete_project_category(category_id:, **)
              resp = connection(**).delete("/rest/api/3/projectCategory/#{category_id}")
              { deleted: resp.status == 204, category_id: category_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 5: Run both specs**

Run: `bundle exec rspec spec/legion/extensions/jira/projects/runners/roles_spec.rb spec/legion/extensions/jira/projects/runners/categories_spec.rb`
Expected: 10 examples, 0 failures

- [ ] **Step 6: Commit**

```bash
git add lib/legion/extensions/jira/projects/runners/roles.rb lib/legion/extensions/jira/projects/runners/categories.rb spec/legion/extensions/jira/projects/runners/roles_spec.rb spec/legion/extensions/jira/projects/runners/categories_spec.rb
git commit -m "feat: add Projects::Runners::Roles and Categories"
```

---

### Task 15: Users::Runners::Users

**Files:**
- Create: `lib/legion/extensions/jira/users/runners/users.rb`
- Create: `spec/legion/extensions/jira/users/runners/users_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/users/runners/users'

RSpec.describe Legion::Extensions::Jira::Users::Runners::Users do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_user' do
    it 'returns a user by account id' do
      stubs.get('/rest/api/3/user') do
        [200, { 'Content-Type' => 'application/json' }, { 'accountId' => 'abc', 'displayName' => 'Alice' }]
      end
      result = instance.get_user(account_id: 'abc')
      expect(result[:user]['displayName']).to eq('Alice')
    end
  end

  describe '#create_user' do
    it 'creates a user' do
      stubs.post('/rest/api/3/user') do
        [201, { 'Content-Type' => 'application/json' }, { 'accountId' => 'new', 'emailAddress' => 'new@test.com' }]
      end
      result = instance.create_user(email_address: 'new@test.com')
      expect(result[:user]['emailAddress']).to eq('new@test.com')
    end
  end

  describe '#delete_user' do
    it 'deletes a user' do
      stubs.delete('/rest/api/3/user') do
        [204, {}, nil]
      end
      result = instance.delete_user(account_id: 'abc')
      expect(result[:deleted]).to be true
    end
  end

  describe '#bulk_get_users' do
    it 'returns multiple users' do
      stubs.get('/rest/api/3/user/bulk') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'accountId' => 'abc' }, { 'accountId' => 'def' }] }]
      end
      result = instance.bulk_get_users(account_ids: %w[abc def])
      expect(result[:users]['values'].length).to eq(2)
    end
  end

  describe '#find_users' do
    it 'searches for users' do
      stubs.get('/rest/api/3/user/search') do
        [200, { 'Content-Type' => 'application/json' }, [{ 'accountId' => 'abc', 'displayName' => 'Alice' }]]
      end
      result = instance.find_users(query: 'alice')
      expect(result[:users]).to be_an(Array)
    end
  end

  describe '#find_users_by_query' do
    it 'searches users by query string' do
      stubs.get('/rest/api/3/user/search/query') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'accountId' => 'abc' }] }]
      end
      result = instance.find_users_by_query(query: 'is assignee of PROJ')
      expect(result[:users]['values']).to be_an(Array)
    end
  end

  describe '#get_myself' do
    it 'returns the current user' do
      stubs.get('/rest/api/3/myself') do
        [200, { 'Content-Type' => 'application/json' }, { 'accountId' => 'me', 'displayName' => 'Me' }]
      end
      result = instance.get_myself
      expect(result[:user]['accountId']).to eq('me')
    end
  end

  describe '#get_user_columns' do
    it 'returns user default columns' do
      stubs.get('/rest/api/3/user/columns') do
        [200, { 'Content-Type' => 'application/json' }, [{ 'label' => 'Key', 'value' => 'issuekey' }]]
      end
      result = instance.get_user_columns(account_id: 'abc')
      expect(result[:columns]).to be_an(Array)
    end
  end
end
```

- [ ] **Step 2: Run spec — expect fail**

Run: `bundle exec rspec spec/legion/extensions/jira/users/runners/users_spec.rb`

- [ ] **Step 3: Write implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Users
        module Runners
          module Users
            include Legion::Extensions::Jira::Helpers::Client

            def get_user(account_id:, expand: nil, **)
              params = { accountId: account_id }
              params[:expand] = expand if expand
              resp = connection(**).get('/rest/api/3/user', params)
              { user: resp.body }
            end

            def create_user(email_address:, display_name: nil, **)
              body = { emailAddress: email_address }
              body[:displayName] = display_name if display_name
              resp = connection(**).post('/rest/api/3/user', body)
              { user: resp.body }
            end

            def delete_user(account_id:, **)
              resp = connection(**).delete('/rest/api/3/user') do |req|
                req.params['accountId'] = account_id
              end
              { deleted: resp.status == 204, account_id: account_id }
            end

            def bulk_get_users(account_ids:, start_at: 0, max_results: 200, **)
              params = { startAt: start_at, maxResults: max_results }
              account_ids.each { |id| (params[:accountId] ||= []) << id }
              resp = connection(**).get('/rest/api/3/user/bulk', params)
              { users: resp.body }
            end

            def find_users(query: nil, start_at: 0, max_results: 50, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:query] = query if query
              resp = connection(**).get('/rest/api/3/user/search', params)
              { users: resp.body }
            end

            def find_users_by_query(query:, start_at: 0, max_results: 100, **)
              params = { query: query, startAt: start_at, maxResults: max_results }
              resp = connection(**).get('/rest/api/3/user/search/query', params)
              { users: resp.body }
            end

            def get_myself(**)
              resp = connection(**).get('/rest/api/3/myself')
              { user: resp.body }
            end

            def get_user_columns(account_id: nil, **)
              params = {}
              params[:accountId] = account_id if account_id
              resp = connection(**).get('/rest/api/3/user/columns', params)
              { columns: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect pass**

Run: `bundle exec rspec spec/legion/extensions/jira/users/runners/users_spec.rb`
Expected: 8 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/legion/extensions/jira/users/runners/users.rb spec/legion/extensions/jira/users/runners/users_spec.rb
git commit -m "feat: add Users::Runners::Users — user CRUD, search, myself"
```

---

### Task 16: Groups::Runners::Groups + Permissions::Runners::Permissions

**Files:**
- Create: `lib/legion/extensions/jira/groups/runners/groups.rb`
- Create: `lib/legion/extensions/jira/permissions/runners/permissions.rb`
- Create: `spec/legion/extensions/jira/groups/runners/groups_spec.rb`
- Create: `spec/legion/extensions/jira/permissions/runners/permissions_spec.rb`

- [ ] **Step 1: Write groups spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/groups/runners/groups'

RSpec.describe Legion::Extensions::Jira::Groups::Runners::Groups do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_group' do
    it 'returns a group' do
      stubs.get('/rest/api/3/group') do
        [200, { 'Content-Type' => 'application/json' }, { 'name' => 'dev-team', 'users' => { 'items' => [] } }]
      end
      result = instance.get_group(group_name: 'dev-team')
      expect(result[:group]['name']).to eq('dev-team')
    end
  end

  describe '#create_group' do
    it 'creates a group' do
      stubs.post('/rest/api/3/group') do
        [201, { 'Content-Type' => 'application/json' }, { 'name' => 'new-team' }]
      end
      result = instance.create_group(name: 'new-team')
      expect(result[:group]['name']).to eq('new-team')
    end
  end

  describe '#delete_group' do
    it 'deletes a group' do
      stubs.delete('/rest/api/3/group') do
        [200, {}, nil]
      end
      result = instance.delete_group(group_name: 'old-team')
      expect(result[:deleted]).to be true
    end
  end

  describe '#add_user_to_group' do
    it 'adds a user' do
      stubs.post('/rest/api/3/group/user') do
        [201, { 'Content-Type' => 'application/json' }, { 'name' => 'dev-team' }]
      end
      result = instance.add_user_to_group(group_name: 'dev-team', account_id: 'abc')
      expect(result[:group]['name']).to eq('dev-team')
    end
  end

  describe '#remove_user_from_group' do
    it 'removes a user' do
      stubs.delete('/rest/api/3/group/user') do
        [200, {}, nil]
      end
      result = instance.remove_user_from_group(group_name: 'dev-team', account_id: 'abc')
      expect(result[:removed]).to be true
    end
  end

  describe '#bulk_get_groups' do
    it 'returns multiple groups' do
      stubs.get('/rest/api/3/group/bulk') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'name' => 'dev-team' }], 'total' => 1 }]
      end
      result = instance.bulk_get_groups
      expect(result[:groups]['values']).to be_an(Array)
    end
  end

  describe '#find_groups' do
    it 'searches for groups' do
      stubs.get('/rest/api/3/groups/picker') do
        [200, { 'Content-Type' => 'application/json' },
         { 'groups' => [{ 'name' => 'dev-team' }] }]
      end
      result = instance.find_groups(query: 'dev')
      expect(result[:groups]['groups']).to be_an(Array)
    end
  end
end
```

- [ ] **Step 2: Write groups implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Groups
        module Runners
          module Groups
            include Legion::Extensions::Jira::Helpers::Client

            def get_group(group_name: nil, group_id: nil, **)
              params = {}
              params[:groupname] = group_name if group_name
              params[:groupId] = group_id if group_id
              resp = connection(**).get('/rest/api/3/group', params)
              { group: resp.body }
            end

            def create_group(name:, **)
              resp = connection(**).post('/rest/api/3/group', { name: name })
              { group: resp.body }
            end

            def delete_group(group_name: nil, group_id: nil, **)
              resp = connection(**).delete('/rest/api/3/group') do |req|
                req.params['groupname'] = group_name if group_name
                req.params['groupId'] = group_id if group_id
              end
              { deleted: [200, 204].include?(resp.status) }
            end

            def add_user_to_group(group_name: nil, group_id: nil, account_id:, **)
              params = {}
              params[:groupname] = group_name if group_name
              params[:groupId] = group_id if group_id
              resp = connection(**).post('/rest/api/3/group/user') do |req|
                req.params = params
                req.body = { accountId: account_id }
              end
              { group: resp.body }
            end

            def remove_user_from_group(group_name: nil, group_id: nil, account_id:, **)
              resp = connection(**).delete('/rest/api/3/group/user') do |req|
                req.params['groupname'] = group_name if group_name
                req.params['groupId'] = group_id if group_id
                req.params['accountId'] = account_id
              end
              { removed: [200, 204].include?(resp.status) }
            end

            def bulk_get_groups(start_at: 0, max_results: 50, **)
              params = { startAt: start_at, maxResults: max_results }
              resp = connection(**).get('/rest/api/3/group/bulk', params)
              { groups: resp.body }
            end

            def find_groups(query: nil, max_results: 50, **)
              params = { maxResults: max_results }
              params[:query] = query if query
              resp = connection(**).get('/rest/api/3/groups/picker', params)
              { groups: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 3: Write permissions spec**

```ruby
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
```

- [ ] **Step 4: Write permissions implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Permissions
        module Runners
          module Permissions
            include Legion::Extensions::Jira::Helpers::Client

            def get_my_permissions(permissions: nil, project_key: nil, issue_key: nil, **)
              params = {}
              params[:permissions] = permissions if permissions
              params[:projectKey] = project_key if project_key
              params[:issueKey] = issue_key if issue_key
              resp = connection(**).get('/rest/api/3/mypermissions', params)
              { permissions: resp.body }
            end

            def get_all_permissions(**)
              resp = connection(**).get('/rest/api/3/permissions')
              { permissions: resp.body }
            end

            def list_permission_schemes(expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get('/rest/api/3/permissionscheme', params)
              { schemes: resp.body }
            end

            def get_permission_scheme(scheme_id:, expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get("/rest/api/3/permissionscheme/#{scheme_id}", params)
              { scheme: resp.body }
            end

            def check_permissions(project_permissions:, account_id: nil, **)
              body = { projectPermissions: project_permissions }
              body[:accountId] = account_id if account_id
              resp = connection(**).post('/rest/api/3/permissions/check', body)
              { permissions: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 5: Run both specs**

Run: `bundle exec rspec spec/legion/extensions/jira/groups/runners/groups_spec.rb spec/legion/extensions/jira/permissions/runners/permissions_spec.rb`
Expected: 12 examples, 0 failures

- [ ] **Step 6: Commit**

```bash
git add lib/legion/extensions/jira/groups/runners/groups.rb lib/legion/extensions/jira/permissions/runners/permissions.rb spec/legion/extensions/jira/groups/runners/groups_spec.rb spec/legion/extensions/jira/permissions/runners/permissions_spec.rb
git commit -m "feat: add Groups::Runners::Groups and Permissions::Runners::Permissions"
```

---

### Task 17: Dashboards::Runners::Dashboards + Filters::Runners::Filters

**Files:**
- Create: `lib/legion/extensions/jira/dashboards/runners/dashboards.rb`
- Create: `lib/legion/extensions/jira/filters/runners/filters.rb`
- Create: `spec/legion/extensions/jira/dashboards/runners/dashboards_spec.rb`
- Create: `spec/legion/extensions/jira/filters/runners/filters_spec.rb`

- [ ] **Step 1: Write dashboards spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/dashboards/runners/dashboards'

RSpec.describe Legion::Extensions::Jira::Dashboards::Runners::Dashboards do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_dashboards' do
    it 'returns dashboards' do
      stubs.get('/rest/api/3/dashboard') do
        [200, { 'Content-Type' => 'application/json' },
         { 'dashboards' => [{ 'id' => '1', 'name' => 'My Dash' }], 'total' => 1 }]
      end
      result = instance.list_dashboards
      expect(result[:dashboards]['dashboards']).to be_an(Array)
    end
  end

  describe '#get_dashboard' do
    it 'returns a dashboard' do
      stubs.get('/rest/api/3/dashboard/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'My Dash' }]
      end
      result = instance.get_dashboard(dashboard_id: '1')
      expect(result[:dashboard]['name']).to eq('My Dash')
    end
  end

  describe '#create_dashboard' do
    it 'creates a dashboard' do
      stubs.post('/rest/api/3/dashboard') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '2', 'name' => 'New Dash' }]
      end
      result = instance.create_dashboard(name: 'New Dash')
      expect(result[:dashboard]['name']).to eq('New Dash')
    end
  end

  describe '#update_dashboard' do
    it 'updates a dashboard' do
      stubs.put('/rest/api/3/dashboard/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'Updated' }]
      end
      result = instance.update_dashboard(dashboard_id: '1', name: 'Updated')
      expect(result[:dashboard]['name']).to eq('Updated')
    end
  end

  describe '#delete_dashboard' do
    it 'deletes a dashboard' do
      stubs.delete('/rest/api/3/dashboard/1') do
        [204, {}, nil]
      end
      result = instance.delete_dashboard(dashboard_id: '1')
      expect(result[:deleted]).to be true
    end
  end

  describe '#copy_dashboard' do
    it 'copies a dashboard' do
      stubs.post('/rest/api/3/dashboard/1/copy') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '3', 'name' => 'Copy of Dash' }]
      end
      result = instance.copy_dashboard(dashboard_id: '1', name: 'Copy of Dash')
      expect(result[:dashboard]['id']).to eq('3')
    end
  end
end
```

- [ ] **Step 2: Write dashboards implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Dashboards
        module Runners
          module Dashboards
            include Legion::Extensions::Jira::Helpers::Client

            def list_dashboards(start_at: 0, max_results: 20, filter: nil, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:filter] = filter if filter
              resp = connection(**).get('/rest/api/3/dashboard', params)
              { dashboards: resp.body }
            end

            def get_dashboard(dashboard_id:, **)
              resp = connection(**).get("/rest/api/3/dashboard/#{dashboard_id}")
              { dashboard: resp.body }
            end

            def create_dashboard(name:, description: nil, share_permissions: nil, **)
              body = { name: name }
              body[:description] = description if description
              body[:sharePermissions] = share_permissions if share_permissions
              resp = connection(**).post('/rest/api/3/dashboard', body)
              { dashboard: resp.body }
            end

            def update_dashboard(dashboard_id:, name: nil, description: nil, share_permissions: nil, **)
              body = {}
              body[:name] = name if name
              body[:description] = description if description
              body[:sharePermissions] = share_permissions if share_permissions
              resp = connection(**).put("/rest/api/3/dashboard/#{dashboard_id}", body)
              { dashboard: resp.body }
            end

            def delete_dashboard(dashboard_id:, **)
              resp = connection(**).delete("/rest/api/3/dashboard/#{dashboard_id}")
              { deleted: resp.status == 204, dashboard_id: dashboard_id }
            end

            def copy_dashboard(dashboard_id:, name:, description: nil, share_permissions: nil, **)
              body = { name: name }
              body[:description] = description if description
              body[:sharePermissions] = share_permissions if share_permissions
              resp = connection(**).post("/rest/api/3/dashboard/#{dashboard_id}/copy", body)
              { dashboard: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 3: Write filters spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/filters/runners/filters'

RSpec.describe Legion::Extensions::Jira::Filters::Runners::Filters do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_favorite_filters' do
    it 'returns favorite filters' do
      stubs.get('/rest/api/3/filter/favourite') do
        [200, { 'Content-Type' => 'application/json' }, [{ 'id' => '1', 'name' => 'My Bugs' }]]
      end
      result = instance.list_favorite_filters
      expect(result[:filters]).to be_an(Array)
    end
  end

  describe '#get_filter' do
    it 'returns a filter' do
      stubs.get('/rest/api/3/filter/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'My Bugs' }]
      end
      result = instance.get_filter(filter_id: '1')
      expect(result[:filter]['name']).to eq('My Bugs')
    end
  end

  describe '#create_filter' do
    it 'creates a filter' do
      stubs.post('/rest/api/3/filter') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '2', 'name' => 'New Filter' }]
      end
      result = instance.create_filter(name: 'New Filter', jql: 'project = PROJ')
      expect(result[:filter]['name']).to eq('New Filter')
    end
  end

  describe '#update_filter' do
    it 'updates a filter' do
      stubs.put('/rest/api/3/filter/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => '1', 'name' => 'Updated' }]
      end
      result = instance.update_filter(filter_id: '1', name: 'Updated')
      expect(result[:filter]['name']).to eq('Updated')
    end
  end

  describe '#delete_filter' do
    it 'deletes a filter' do
      stubs.delete('/rest/api/3/filter/1') do
        [204, {}, nil]
      end
      result = instance.delete_filter(filter_id: '1')
      expect(result[:deleted]).to be true
    end
  end

  describe '#get_filter_share_permissions' do
    it 'returns share permissions' do
      stubs.get('/rest/api/3/filter/1/permission') do
        [200, { 'Content-Type' => 'application/json' }, [{ 'id' => 100, 'type' => 'global' }]]
      end
      result = instance.get_filter_share_permissions(filter_id: '1')
      expect(result[:permissions]).to be_an(Array)
    end
  end

  describe '#add_filter_share_permission' do
    it 'adds a share permission' do
      stubs.post('/rest/api/3/filter/1/permission') do
        [201, { 'Content-Type' => 'application/json' }, [{ 'id' => 101, 'type' => 'project' }]]
      end
      result = instance.add_filter_share_permission(filter_id: '1', type: 'project', project_id: '10000')
      expect(result[:permissions]).to be_an(Array)
    end
  end

  describe '#delete_filter_share_permission' do
    it 'deletes a share permission' do
      stubs.delete('/rest/api/3/filter/1/permission/100') do
        [204, {}, nil]
      end
      result = instance.delete_filter_share_permission(filter_id: '1', permission_id: '100')
      expect(result[:deleted]).to be true
    end
  end
end
```

- [ ] **Step 4: Write filters implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Filters
        module Runners
          module Filters
            include Legion::Extensions::Jira::Helpers::Client

            def list_favorite_filters(expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get('/rest/api/3/filter/favourite', params)
              { filters: resp.body }
            end

            def get_filter(filter_id:, expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get("/rest/api/3/filter/#{filter_id}", params)
              { filter: resp.body }
            end

            def create_filter(name:, jql: nil, description: nil, favourite: nil, **)
              body = { name: name }
              body[:jql] = jql if jql
              body[:description] = description if description
              body[:favourite] = favourite unless favourite.nil?
              resp = connection(**).post('/rest/api/3/filter', body)
              { filter: resp.body }
            end

            def update_filter(filter_id:, name: nil, jql: nil, description: nil, **)
              body = {}
              body[:name] = name if name
              body[:jql] = jql if jql
              body[:description] = description if description
              resp = connection(**).put("/rest/api/3/filter/#{filter_id}", body)
              { filter: resp.body }
            end

            def delete_filter(filter_id:, **)
              resp = connection(**).delete("/rest/api/3/filter/#{filter_id}")
              { deleted: resp.status == 204, filter_id: filter_id }
            end

            def get_filter_share_permissions(filter_id:, **)
              resp = connection(**).get("/rest/api/3/filter/#{filter_id}/permission")
              { permissions: resp.body }
            end

            def add_filter_share_permission(filter_id:, type:, project_id: nil, group_name: nil, **)
              body = { type: type }
              body[:projectId] = project_id if project_id
              body[:groupname] = group_name if group_name
              resp = connection(**).post("/rest/api/3/filter/#{filter_id}/permission", body)
              { permissions: resp.body }
            end

            def delete_filter_share_permission(filter_id:, permission_id:, **)
              resp = connection(**).delete("/rest/api/3/filter/#{filter_id}/permission/#{permission_id}")
              { deleted: resp.status == 204, filter_id: filter_id, permission_id: permission_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 5: Run both specs**

Run: `bundle exec rspec spec/legion/extensions/jira/dashboards/runners/dashboards_spec.rb spec/legion/extensions/jira/filters/runners/filters_spec.rb`
Expected: 14 examples, 0 failures

- [ ] **Step 6: Commit**

```bash
git add lib/legion/extensions/jira/dashboards/runners/dashboards.rb lib/legion/extensions/jira/filters/runners/filters.rb spec/legion/extensions/jira/dashboards/runners/dashboards_spec.rb spec/legion/extensions/jira/filters/runners/filters_spec.rb
git commit -m "feat: add Dashboards::Runners::Dashboards and Filters::Runners::Filters"
```

---

### Task 18: Agile::Runners::Boards + Sprints

**Files:**
- Create: `lib/legion/extensions/jira/agile/runners/boards.rb`
- Create: `lib/legion/extensions/jira/agile/runners/sprints.rb`
- Create: `spec/legion/extensions/jira/agile/runners/boards_spec.rb`
- Create: `spec/legion/extensions/jira/agile/runners/sprints_spec.rb`

- [ ] **Step 1: Write boards spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/agile/runners/boards'

RSpec.describe Legion::Extensions::Jira::Agile::Runners::Boards do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_boards' do
    it 'returns boards' do
      stubs.get('/rest/agile/1.0/board') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'id' => 1, 'name' => 'Scrum Board' }], 'total' => 1 }]
      end
      result = instance.list_boards
      expect(result[:boards]['values']).to be_an(Array)
    end
  end

  describe '#get_board' do
    it 'returns a board' do
      stubs.get('/rest/agile/1.0/board/1') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 1, 'name' => 'Scrum Board' }]
      end
      result = instance.get_board(board_id: 1)
      expect(result[:board]['id']).to eq(1)
    end
  end

  describe '#get_board_configuration' do
    it 'returns board configuration' do
      stubs.get('/rest/agile/1.0/board/1/configuration') do
        [200, { 'Content-Type' => 'application/json' },
         { 'id' => 1, 'name' => 'Scrum Board', 'columnConfig' => {} }]
      end
      result = instance.get_board_configuration(board_id: 1)
      expect(result[:configuration]).to have_key('columnConfig')
    end
  end

  describe '#get_board_issues' do
    it 'returns issues on a board' do
      stubs.get('/rest/agile/1.0/board/1/issue') do
        [200, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-1' }], 'total' => 1 }]
      end
      result = instance.get_board_issues(board_id: 1)
      expect(result[:issues]['issues']).to be_an(Array)
    end
  end
end
```

- [ ] **Step 2: Write boards implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Agile
        module Runners
          module Boards
            include Legion::Extensions::Jira::Helpers::Client

            def list_boards(project_key: nil, board_type: nil, start_at: 0, max_results: 50, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:projectKeyOrId] = project_key if project_key
              params[:type] = board_type if board_type
              resp = connection(**).get('/rest/agile/1.0/board', params)
              { boards: resp.body }
            end

            def get_board(board_id:, **)
              resp = connection(**).get("/rest/agile/1.0/board/#{board_id}")
              { board: resp.body }
            end

            def get_board_configuration(board_id:, **)
              resp = connection(**).get("/rest/agile/1.0/board/#{board_id}/configuration")
              { configuration: resp.body }
            end

            def get_board_issues(board_id:, jql: nil, start_at: 0, max_results: 50, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:jql] = jql if jql
              resp = connection(**).get("/rest/agile/1.0/board/#{board_id}/issue", params)
              { issues: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 3: Write sprints spec**

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/agile/runners/sprints'

RSpec.describe Legion::Extensions::Jira::Agile::Runners::Sprints do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_sprint' do
    it 'returns a sprint' do
      stubs.get('/rest/agile/1.0/sprint/10') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 10, 'name' => 'Sprint 1', 'state' => 'active' }]
      end
      result = instance.get_sprint(sprint_id: 10)
      expect(result[:sprint]['state']).to eq('active')
    end
  end

  describe '#create_sprint' do
    it 'creates a sprint' do
      stubs.post('/rest/agile/1.0/sprint') do
        [201, { 'Content-Type' => 'application/json' }, { 'id' => 11, 'name' => 'Sprint 2' }]
      end
      result = instance.create_sprint(name: 'Sprint 2', board_id: 1)
      expect(result[:sprint]['name']).to eq('Sprint 2')
    end
  end

  describe '#update_sprint' do
    it 'updates a sprint' do
      stubs.put('/rest/agile/1.0/sprint/10') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 10, 'name' => 'Sprint 1 - Updated' }]
      end
      result = instance.update_sprint(sprint_id: 10, name: 'Sprint 1 - Updated')
      expect(result[:sprint]['name']).to eq('Sprint 1 - Updated')
    end
  end

  describe '#delete_sprint' do
    it 'deletes a sprint' do
      stubs.delete('/rest/agile/1.0/sprint/10') do
        [204, {}, nil]
      end
      result = instance.delete_sprint(sprint_id: 10)
      expect(result[:deleted]).to be true
    end
  end

  describe '#get_sprint_issues' do
    it 'returns issues in a sprint' do
      stubs.get('/rest/agile/1.0/sprint/10/issue') do
        [200, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-1' }], 'total' => 1 }]
      end
      result = instance.get_sprint_issues(sprint_id: 10)
      expect(result[:issues]['issues']).to be_an(Array)
    end
  end

  describe '#move_issues_to_sprint' do
    it 'moves issues to a sprint' do
      stubs.post('/rest/agile/1.0/sprint/10/issue') do
        [204, {}, nil]
      end
      result = instance.move_issues_to_sprint(sprint_id: 10, issue_keys: %w[PROJ-1 PROJ-2])
      expect(result[:moved]).to be true
    end
  end
end
```

- [ ] **Step 4: Write sprints implementation**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Agile
        module Runners
          module Sprints
            include Legion::Extensions::Jira::Helpers::Client

            def get_sprint(sprint_id:, **)
              resp = connection(**).get("/rest/agile/1.0/sprint/#{sprint_id}")
              { sprint: resp.body }
            end

            def create_sprint(name:, board_id:, start_date: nil, end_date: nil, goal: nil, **)
              body = { name: name, originBoardId: board_id }
              body[:startDate] = start_date if start_date
              body[:endDate] = end_date if end_date
              body[:goal] = goal if goal
              resp = connection(**).post('/rest/agile/1.0/sprint', body)
              { sprint: resp.body }
            end

            def update_sprint(sprint_id:, name: nil, state: nil, start_date: nil, end_date: nil, goal: nil, **)
              body = {}
              body[:name] = name if name
              body[:state] = state if state
              body[:startDate] = start_date if start_date
              body[:endDate] = end_date if end_date
              body[:goal] = goal if goal
              resp = connection(**).put("/rest/agile/1.0/sprint/#{sprint_id}", body)
              { sprint: resp.body }
            end

            def delete_sprint(sprint_id:, **)
              resp = connection(**).delete("/rest/agile/1.0/sprint/#{sprint_id}")
              { deleted: resp.status == 204, sprint_id: sprint_id }
            end

            def get_sprint_issues(sprint_id:, jql: nil, start_at: 0, max_results: 50, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:jql] = jql if jql
              resp = connection(**).get("/rest/agile/1.0/sprint/#{sprint_id}/issue", params)
              { issues: resp.body }
            end

            def move_issues_to_sprint(sprint_id:, issue_keys:, **)
              resp = connection(**).post("/rest/agile/1.0/sprint/#{sprint_id}/issue", { issues: issue_keys })
              { moved: resp.status == 204, sprint_id: sprint_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 5: Run both specs**

Run: `bundle exec rspec spec/legion/extensions/jira/agile/runners/boards_spec.rb spec/legion/extensions/jira/agile/runners/sprints_spec.rb`
Expected: 10 examples, 0 failures

- [ ] **Step 6: Commit**

```bash
git add lib/legion/extensions/jira/agile/runners/boards.rb lib/legion/extensions/jira/agile/runners/sprints.rb spec/legion/extensions/jira/agile/runners/boards_spec.rb spec/legion/extensions/jira/agile/runners/sprints_spec.rb
git commit -m "feat: add Agile::Runners::Boards and Sprints"
```

---

### Task 19: Agile::Runners::Epics + Backlogs + Webhooks + AuditRecords

Four small runners grouped.

**Files:**
- Create: `lib/legion/extensions/jira/agile/runners/epics.rb`
- Create: `lib/legion/extensions/jira/agile/runners/backlogs.rb`
- Create: `lib/legion/extensions/jira/webhooks/runners/webhooks.rb`
- Create: `lib/legion/extensions/jira/audit_records/runners/audit_records.rb`
- Create: `spec/legion/extensions/jira/agile/runners/epics_spec.rb`
- Create: `spec/legion/extensions/jira/agile/runners/backlogs_spec.rb`
- Create: `spec/legion/extensions/jira/webhooks/runners/webhooks_spec.rb`
- Create: `spec/legion/extensions/jira/audit_records/runners/audit_records_spec.rb`

- [ ] **Step 1: Write epics spec + implementation**

Spec:
```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/agile/runners/epics'

RSpec.describe Legion::Extensions::Jira::Agile::Runners::Epics do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_epic' do
    it 'returns an epic' do
      stubs.get('/rest/agile/1.0/epic/PROJ-100') do
        [200, { 'Content-Type' => 'application/json' }, { 'id' => 100, 'key' => 'PROJ-100', 'name' => 'Epic 1' }]
      end
      result = instance.get_epic(epic_id_or_key: 'PROJ-100')
      expect(result[:epic]['name']).to eq('Epic 1')
    end
  end

  describe '#get_epic_issues' do
    it 'returns issues in an epic' do
      stubs.get('/rest/agile/1.0/epic/PROJ-100/issue') do
        [200, { 'Content-Type' => 'application/json' },
         { 'issues' => [{ 'key' => 'PROJ-101' }], 'total' => 1 }]
      end
      result = instance.get_epic_issues(epic_id_or_key: 'PROJ-100')
      expect(result[:issues]['issues']).to be_an(Array)
    end
  end

  describe '#move_issues_to_epic' do
    it 'moves issues to an epic' do
      stubs.post('/rest/agile/1.0/epic/PROJ-100/issue') do
        [204, {}, nil]
      end
      result = instance.move_issues_to_epic(epic_id_or_key: 'PROJ-100', issue_keys: ['PROJ-101'])
      expect(result[:moved]).to be true
    end
  end
end
```

Implementation:
```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Agile
        module Runners
          module Epics
            include Legion::Extensions::Jira::Helpers::Client

            def get_epic(epic_id_or_key:, **)
              resp = connection(**).get("/rest/agile/1.0/epic/#{epic_id_or_key}")
              { epic: resp.body }
            end

            def get_epic_issues(epic_id_or_key:, start_at: 0, max_results: 50, jql: nil, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:jql] = jql if jql
              resp = connection(**).get("/rest/agile/1.0/epic/#{epic_id_or_key}/issue", params)
              { issues: resp.body }
            end

            def move_issues_to_epic(epic_id_or_key:, issue_keys:, **)
              resp = connection(**).post("/rest/agile/1.0/epic/#{epic_id_or_key}/issue", { issues: issue_keys })
              { moved: resp.status == 204 }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 2: Write backlogs spec + implementation**

Spec:
```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/agile/runners/backlogs'

RSpec.describe Legion::Extensions::Jira::Agile::Runners::Backlogs do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#move_issues_to_backlog' do
    it 'moves issues to the backlog' do
      stubs.post('/rest/agile/1.0/backlog/issue') do
        [204, {}, nil]
      end
      result = instance.move_issues_to_backlog(issue_keys: %w[PROJ-1 PROJ-2])
      expect(result[:moved]).to be true
    end
  end
end
```

Implementation:
```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Agile
        module Runners
          module Backlogs
            include Legion::Extensions::Jira::Helpers::Client

            def move_issues_to_backlog(issue_keys:, **)
              resp = connection(**).post('/rest/agile/1.0/backlog/issue', { issues: issue_keys })
              { moved: resp.status == 204 }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 3: Write webhooks spec + implementation**

Spec:
```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/webhooks/runners/webhooks'

RSpec.describe Legion::Extensions::Jira::Webhooks::Runners::Webhooks do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#list_webhooks' do
    it 'returns registered webhooks' do
      stubs.get('/rest/api/3/webhook') do
        [200, { 'Content-Type' => 'application/json' },
         { 'values' => [{ 'id' => 1, 'jqlFilter' => 'project = PROJ' }] }]
      end
      result = instance.list_webhooks
      expect(result[:webhooks]['values']).to be_an(Array)
    end
  end

  describe '#register_webhooks' do
    it 'registers webhooks' do
      stubs.post('/rest/api/3/webhook') do
        [200, { 'Content-Type' => 'application/json' },
         { 'webhookRegistrationResult' => [{ 'createdWebhookId' => 2 }] }]
      end
      result = instance.register_webhooks(
        webhooks: [{ jqlFilter: 'project = PROJ', events: ['jira:issue_created'] }],
        url: 'https://example.com/webhook'
      )
      expect(result[:result]).to have_key('webhookRegistrationResult')
    end
  end

  describe '#delete_webhooks' do
    it 'deletes webhooks' do
      stubs.delete('/rest/api/3/webhook') do
        [202, {}, nil]
      end
      result = instance.delete_webhooks(webhook_ids: [1, 2])
      expect(result[:deleted]).to be true
    end
  end

  describe '#refresh_webhooks' do
    it 'refreshes webhook expiry' do
      stubs.put('/rest/api/3/webhook/refresh') do
        [200, { 'Content-Type' => 'application/json' },
         { 'webhooksRefreshResult' => [{ 'webhookId' => 1, 'expirationDate' => '2026-05-13' }] }]
      end
      result = instance.refresh_webhooks(webhook_ids: [1])
      expect(result[:result]).to have_key('webhooksRefreshResult')
    end
  end
end
```

Implementation:
```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Webhooks
        module Runners
          module Webhooks
            include Legion::Extensions::Jira::Helpers::Client

            def list_webhooks(start_at: 0, max_results: 100, **)
              params = { startAt: start_at, maxResults: max_results }
              resp = connection(**).get('/rest/api/3/webhook', params)
              { webhooks: resp.body }
            end

            def register_webhooks(webhooks:, url:, **)
              resp = connection(**).post('/rest/api/3/webhook', { webhooks: webhooks, url: url })
              { result: resp.body }
            end

            def delete_webhooks(webhook_ids:, **)
              resp = connection(**).delete('/rest/api/3/webhook') do |req|
                req.body = { webhookIds: webhook_ids }
              end
              { deleted: [200, 202, 204].include?(resp.status) }
            end

            def refresh_webhooks(webhook_ids:, **)
              resp = connection(**).put('/rest/api/3/webhook/refresh', { webhookIds: webhook_ids })
              { result: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Write audit_records spec + implementation**

Spec:
```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/runner_test_harness'
require 'legion/extensions/jira/audit_records/runners/audit_records'

RSpec.describe Legion::Extensions::Jira::AuditRecords::Runners::AuditRecords do
  let(:stubs) { @stubs }
  let(:instance) { @instance }

  before do
    @stubs, conn = RunnerTestHarness.stub_connection
    @instance = RunnerTestHarness.build(described_class)
    allow(@instance).to receive(:connection).and_return(conn)
  end

  describe '#get_audit_records' do
    it 'returns audit records' do
      stubs.get('/rest/api/3/auditing/record') do
        [200, { 'Content-Type' => 'application/json' },
         { 'records' => [{ 'id' => 1, 'summary' => 'User created' }], 'total' => 1 }]
      end
      result = instance.get_audit_records
      expect(result[:records]['records']).to be_an(Array)
    end
  end
end
```

Implementation:
```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module AuditRecords
        module Runners
          module AuditRecords
            include Legion::Extensions::Jira::Helpers::Client

            def get_audit_records(offset: 0, limit: 1000, filter: nil, from: nil, to: nil, **)
              params = { offset: offset, limit: limit }
              params[:filter] = filter if filter
              params[:from] = from if from
              params[:to] = to if to
              resp = connection(**).get('/rest/api/3/auditing/record', params)
              { records: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

- [ ] **Step 5: Run all four specs**

Run: `bundle exec rspec spec/legion/extensions/jira/agile/runners/epics_spec.rb spec/legion/extensions/jira/agile/runners/backlogs_spec.rb spec/legion/extensions/jira/webhooks/runners/webhooks_spec.rb spec/legion/extensions/jira/audit_records/runners/audit_records_spec.rb`
Expected: 12 examples, 0 failures

- [ ] **Step 6: Commit**

```bash
git add lib/legion/extensions/jira/agile/runners/epics.rb lib/legion/extensions/jira/agile/runners/backlogs.rb lib/legion/extensions/jira/webhooks/runners/webhooks.rb lib/legion/extensions/jira/audit_records/runners/audit_records.rb spec/legion/extensions/jira/agile/runners/epics_spec.rb spec/legion/extensions/jira/agile/runners/backlogs_spec.rb spec/legion/extensions/jira/webhooks/runners/webhooks_spec.rb spec/legion/extensions/jira/audit_records/runners/audit_records_spec.rb
git commit -m "feat: add Agile Epics/Backlogs, Webhooks, and AuditRecords runners"
```

---

### Task 20: Integration — Client, entry point, remove old files

**Files:**
- Modify: `lib/legion/extensions/jira/client.rb`
- Modify: `lib/legion/extensions/jira.rb`
- Modify: `spec/legion/extensions/jira/client_spec.rb`
- Delete: `lib/legion/extensions/jira/runners/issues.rb`
- Delete: `lib/legion/extensions/jira/runners/projects.rb`
- Delete: `lib/legion/extensions/jira/runners/boards.rb`
- Delete: `spec/legion/extensions/jira/runners/issues_spec.rb`
- Delete: `spec/legion/extensions/jira/runners/projects_spec.rb`
- Delete: `spec/legion/extensions/jira/runners/boards_spec.rb`

- [ ] **Step 1: Rewrite lib/legion/extensions/jira.rb**

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/version'
require 'legion/extensions/jira/helpers/client'

# Issues domain
require 'legion/extensions/jira/issues/runners/issues'
require 'legion/extensions/jira/issues/runners/search'
require 'legion/extensions/jira/issues/runners/comments'
require 'legion/extensions/jira/issues/runners/transitions'
require 'legion/extensions/jira/issues/runners/attachments'
require 'legion/extensions/jira/issues/runners/worklogs'
require 'legion/extensions/jira/issues/runners/links'
require 'legion/extensions/jira/issues/runners/remote_links'
require 'legion/extensions/jira/issues/runners/votes'
require 'legion/extensions/jira/issues/runners/watchers'
require 'legion/extensions/jira/issues/runners/properties'

# Projects domain
require 'legion/extensions/jira/projects/runners/projects'
require 'legion/extensions/jira/projects/runners/components'
require 'legion/extensions/jira/projects/runners/versions'
require 'legion/extensions/jira/projects/runners/roles'
require 'legion/extensions/jira/projects/runners/categories'

# Users, Groups, Permissions
require 'legion/extensions/jira/users/runners/users'
require 'legion/extensions/jira/groups/runners/groups'
require 'legion/extensions/jira/permissions/runners/permissions'

# Dashboards & Filters
require 'legion/extensions/jira/dashboards/runners/dashboards'
require 'legion/extensions/jira/filters/runners/filters'

# Agile
require 'legion/extensions/jira/agile/runners/boards'
require 'legion/extensions/jira/agile/runners/sprints'
require 'legion/extensions/jira/agile/runners/epics'
require 'legion/extensions/jira/agile/runners/backlogs'

# Admin
require 'legion/extensions/jira/webhooks/runners/webhooks'
require 'legion/extensions/jira/audit_records/runners/audit_records'

require 'legion/extensions/jira/client'

module Legion
  module Extensions
    module Jira
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
```

- [ ] **Step 2: Rewrite lib/legion/extensions/jira/client.rb**

```ruby
# frozen_string_literal: true

module Legion
  module Extensions
    module Jira
      class Client
        include Helpers::Client

        # Issues
        include Issues::Runners::Issues
        include Issues::Runners::Search
        include Issues::Runners::Comments
        include Issues::Runners::Transitions
        include Issues::Runners::Attachments
        include Issues::Runners::Worklogs
        include Issues::Runners::Links
        include Issues::Runners::RemoteLinks
        include Issues::Runners::Votes
        include Issues::Runners::Watchers
        include Issues::Runners::Properties

        # Projects
        include Projects::Runners::Projects
        include Projects::Runners::Components
        include Projects::Runners::Versions
        include Projects::Runners::Roles
        include Projects::Runners::Categories

        # Users, Groups, Permissions
        include Users::Runners::Users
        include Groups::Runners::Groups
        include Permissions::Runners::Permissions

        # Dashboards & Filters
        include Dashboards::Runners::Dashboards
        include Filters::Runners::Filters

        # Agile
        include Agile::Runners::Boards
        include Agile::Runners::Sprints
        include Agile::Runners::Epics
        include Agile::Runners::Backlogs

        # Admin
        include Webhooks::Runners::Webhooks
        include AuditRecords::Runners::AuditRecords

        attr_reader :opts

        def initialize(url:, email:, api_token:, **extra)
          @opts = { url: url, email: email, api_token: api_token, **extra }
        end

        def settings
          { options: @opts }
        end

        def connection(**override)
          super(**@opts.merge(override))
        end

        def upload_connection(**override)
          super(**@opts.merge(override))
        end
      end
    end
  end
end
```

- [ ] **Step 3: Update spec/legion/extensions/jira/client_spec.rb**

```ruby
# frozen_string_literal: true

RSpec.describe Legion::Extensions::Jira::Client do
  subject(:client) do
    described_class.new(
      url:       'https://acme.atlassian.net',
      email:     'user@example.com',
      api_token: 'secret-token'
    )
  end

  describe '#initialize' do
    it 'stores url in opts' do
      expect(client.opts[:url]).to eq('https://acme.atlassian.net')
    end

    it 'stores email in opts' do
      expect(client.opts[:email]).to eq('user@example.com')
    end

    it 'stores api_token in opts' do
      expect(client.opts[:api_token]).to eq('secret-token')
    end
  end

  describe '#settings' do
    it 'returns a hash with options key' do
      expect(client.settings).to eq({ options: client.opts })
    end
  end

  describe '#connection' do
    it 'returns a Faraday connection' do
      expect(client.connection).to be_a(Faraday::Connection)
    end
  end

  describe '#upload_connection' do
    it 'returns a Faraday connection' do
      expect(client.upload_connection).to be_a(Faraday::Connection)
    end
  end

  describe 'runner inclusion' do
    it 'includes all 27 runner modules' do
      expected_modules = [
        Legion::Extensions::Jira::Issues::Runners::Issues,
        Legion::Extensions::Jira::Issues::Runners::Search,
        Legion::Extensions::Jira::Issues::Runners::Comments,
        Legion::Extensions::Jira::Issues::Runners::Transitions,
        Legion::Extensions::Jira::Issues::Runners::Attachments,
        Legion::Extensions::Jira::Issues::Runners::Worklogs,
        Legion::Extensions::Jira::Issues::Runners::Links,
        Legion::Extensions::Jira::Issues::Runners::RemoteLinks,
        Legion::Extensions::Jira::Issues::Runners::Votes,
        Legion::Extensions::Jira::Issues::Runners::Watchers,
        Legion::Extensions::Jira::Issues::Runners::Properties,
        Legion::Extensions::Jira::Projects::Runners::Projects,
        Legion::Extensions::Jira::Projects::Runners::Components,
        Legion::Extensions::Jira::Projects::Runners::Versions,
        Legion::Extensions::Jira::Projects::Runners::Roles,
        Legion::Extensions::Jira::Projects::Runners::Categories,
        Legion::Extensions::Jira::Users::Runners::Users,
        Legion::Extensions::Jira::Groups::Runners::Groups,
        Legion::Extensions::Jira::Permissions::Runners::Permissions,
        Legion::Extensions::Jira::Dashboards::Runners::Dashboards,
        Legion::Extensions::Jira::Filters::Runners::Filters,
        Legion::Extensions::Jira::Agile::Runners::Boards,
        Legion::Extensions::Jira::Agile::Runners::Sprints,
        Legion::Extensions::Jira::Agile::Runners::Epics,
        Legion::Extensions::Jira::Agile::Runners::Backlogs,
        Legion::Extensions::Jira::Webhooks::Runners::Webhooks,
        Legion::Extensions::Jira::AuditRecords::Runners::AuditRecords
      ]
      expected_modules.each do |mod|
        expect(described_class.ancestors).to include(mod)
      end
    end
  end
end
```

- [ ] **Step 4: Delete old runner files and specs**

Run:
```bash
rm lib/legion/extensions/jira/runners/issues.rb
rm lib/legion/extensions/jira/runners/projects.rb
rm lib/legion/extensions/jira/runners/boards.rb
rm spec/legion/extensions/jira/runners/issues_spec.rb
rm spec/legion/extensions/jira/runners/projects_spec.rb
rm spec/legion/extensions/jira/runners/boards_spec.rb
rmdir lib/legion/extensions/jira/runners
rmdir spec/legion/extensions/jira/runners
```

- [ ] **Step 5: Run full test suite**

Run: `bundle exec rspec`
Expected: All new specs pass (old specs removed, replaced by new ones).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "integrate: wire all 27 runners into Client, remove old flat runners"
```

---

### Task 21: Final polish — rubocop, version bump, CLAUDE.md

**Files:**
- Modify: `lib/legion/extensions/jira/version.rb`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Run rubocop**

Run: `bundle exec rubocop`
If offenses: `bundle exec rubocop -a` then review and commit fixes.

- [ ] **Step 2: Bump version to 0.2.0**

In `lib/legion/extensions/jira/version.rb`:
```ruby
VERSION = '0.2.0'
```

- [ ] **Step 3: Update CLAUDE.md to reflect new structure**

Update the Architecture, Key Files, and Development sections to reflect the new 10-domain, 27-runner module structure.

- [ ] **Step 4: Run full suite one final time**

Run: `bundle exec rspec`
Expected: All examples pass, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: rubocop, bump to 0.2.0, update CLAUDE.md for modular structure"
```
