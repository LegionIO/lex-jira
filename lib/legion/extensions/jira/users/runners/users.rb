# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Users
        module Runners
          module Users
            include Legion::Extensions::Jira::Helpers::Client

            def get_user(account_id:, expand: nil, **)
              params = { accountId: account_id }
              params[:expand] = expand if expand
              resp = connection(**).get('/rest/api/3/user', params)
              { user: resp.body }
            end

            def create_user(email_address:, display_name: nil, **)
              body = { emailAddress: email_address }
              body[:displayName] = display_name if display_name
              resp = connection(**).post('/rest/api/3/user', body)
              { user: resp.body }
            end

            def delete_user(account_id:, **)
              resp = connection(**).delete('/rest/api/3/user') do |req|
                req.params['accountId'] = account_id
              end
              { deleted: resp.status == 204, account_id: account_id }
            end

            def bulk_get_users(account_ids:, start_at: 0, max_results: 200, **)
              params = { startAt: start_at, maxResults: max_results }
              account_ids.each { |id| (params[:accountId] ||= []) << id }
              resp = connection(**).get('/rest/api/3/user/bulk', params)
              { users: resp.body }
            end

            def find_users(query: nil, start_at: 0, max_results: 50, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:query] = query if query
              resp = connection(**).get('/rest/api/3/user/search', params)
              { users: resp.body }
            end

            def find_users_by_query(query:, start_at: 0, max_results: 100, **)
              params = { query: query, startAt: start_at, maxResults: max_results }
              resp = connection(**).get('/rest/api/3/user/search/query', params)
              { users: resp.body }
            end

            def get_myself(**)
              resp = connection(**).get('/rest/api/3/myself')
              { user: resp.body }
            end

            def get_user_columns(account_id: nil, **)
              params = {}
              params[:accountId] = account_id if account_id
              resp = connection(**).get('/rest/api/3/user/columns', params)
              { columns: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
