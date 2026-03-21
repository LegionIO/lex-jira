# frozen_string_literal: true

module Legion
  module Extensions
    module Jira
      module Runners
        module Boards
          def list_boards(project_key: nil, board_type: nil, start_at: 0, max_results: 50, **)
            params = { startAt: start_at, maxResults: max_results }
            params[:projectKeyOrId] = project_key if project_key
            params[:type]           = board_type if board_type
            resp = connection(**).get('/rest/agile/1.0/board', params)
            { boards: resp.body }
          end

          def get_board(board_id:, **)
            resp = connection(**).get("/rest/agile/1.0/board/#{board_id}")
            { board: resp.body }
          end

          def get_sprints(board_id:, state: nil, start_at: 0, max_results: 50, **)
            params = { startAt: start_at, maxResults: max_results }
            params[:state] = state if state
            resp = connection(**).get("/rest/agile/1.0/board/#{board_id}/sprint", params)
            { sprints: resp.body }
          end
        end
      end
    end
  end
end
