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
