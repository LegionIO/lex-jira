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
