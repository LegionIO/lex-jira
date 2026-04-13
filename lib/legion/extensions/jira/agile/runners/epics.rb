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
