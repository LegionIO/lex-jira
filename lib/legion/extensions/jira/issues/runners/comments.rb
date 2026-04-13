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
