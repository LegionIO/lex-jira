# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Watchers
            include Legion::Extensions::Jira::Helpers::Client

            def get_watchers(issue_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/watchers")
              { watchers: resp.body }
            end

            def add_watcher(issue_key:, account_id:, **)
              resp = connection(**).post("/rest/api/3/issue/#{issue_key}/watchers", account_id.to_json)
              { added: resp.status == 204, issue_key: issue_key }
            end

            def remove_watcher(issue_key:, account_id:, **)
              resp = connection(**).delete("/rest/api/3/issue/#{issue_key}/watchers") do |req|
                req.params['accountId'] = account_id
              end
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
