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
