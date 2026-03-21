# frozen_string_literal: true

module Legion
  module Extensions
    module Jira
      module Runners
        module Issues
          def create_issue(project_key:, summary:, issue_type: 'Task', description: nil, assignee: nil, priority: nil, labels: nil, **)
            body = {
              fields: {
                project:   { key: project_key },
                summary:   summary,
                issuetype: { name: issue_type }
              }
            }
            body[:fields][:description] = description if description
            body[:fields][:assignee]    = { name: assignee } if assignee
            body[:fields][:priority]    = { name: priority } if priority
            body[:fields][:labels]      = labels if labels
            resp = connection(**).post('/rest/api/3/issue', body)
            { issue: resp.body }
          end

          def get_issue(issue_key:, **)
            resp = connection(**).get("/rest/api/3/issue/#{issue_key}")
            { issue: resp.body }
          end

          def update_issue(issue_key:, summary: nil, description: nil, assignee: nil, priority: nil, **)
            fields = {}
            fields[:summary]     = summary if summary
            fields[:description] = description if description
            fields[:assignee]    = { name: assignee } if assignee
            fields[:priority]    = { name: priority } if priority
            resp = connection(**).put("/rest/api/3/issue/#{issue_key}", { fields: fields })
            { updated: resp.status == 204, issue_key: issue_key }
          end

          def search_issues(jql:, max_results: 50, start_at: 0, **)
            params = { jql: jql, maxResults: max_results, startAt: start_at }
            resp = connection(**).get('/rest/api/3/search', params)
            { issues: resp.body }
          end

          def transition_issue(issue_key:, transition_id:, **)
            body = { transition: { id: transition_id.to_s } }
            resp = connection(**).post("/rest/api/3/issue/#{issue_key}/transitions", body)
            { transitioned: resp.status == 204, issue_key: issue_key }
          end

          def add_comment(issue_key:, body:, **)
            payload = { body: body }
            resp = connection(**).post("/rest/api/3/issue/#{issue_key}/comment", payload)
            { comment: resp.body }
          end
        end
      end
    end
  end
end
