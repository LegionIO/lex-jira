# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Agile
        module Runners
          module Backlogs
            include Legion::Extensions::Jira::Helpers::Client

            def move_issues_to_backlog(issue_keys:, **)
              resp = connection(**).post('/rest/agile/1.0/backlog/issue', { issues: issue_keys })
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
