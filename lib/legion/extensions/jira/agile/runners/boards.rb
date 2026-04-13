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
