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
