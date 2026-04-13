# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Search
            include Legion::Extensions::Jira::Helpers::Client

            def search_issues(jql:, max_results: 50, start_at: 0, fields: nil, expand: nil, **)
              params = { jql: jql, maxResults: max_results, startAt: start_at }
              params[:fields] = fields if fields
              params[:expand] = expand if expand
              resp = connection(**).get('/rest/api/3/search', params)
              { issues: resp.body }
            end

            def pick_issues(query: nil, current_jql: nil, **)
              params = {}
              params[:query] = query if query
              params[:currentJQL] = current_jql if current_jql
              resp = connection(**).get('/rest/api/3/issue/picker', params)
              { suggestions: resp.body }
            end

            def parse_jql(queries:, **)
              resp = connection(**).post('/rest/api/3/jql/parse', { queries: queries })
              { parsed: resp.body }
            end

            def autocomplete_jql(**)
              resp = connection(**).get('/rest/api/3/jql/autocompletedata')
              { suggestions: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
