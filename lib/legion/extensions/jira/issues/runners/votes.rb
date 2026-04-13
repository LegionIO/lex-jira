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
