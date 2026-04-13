# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Groups
        module Runners
          module Groups
            include Legion::Extensions::Jira::Helpers::Client

            def get_group(group_name: nil, group_id: nil, **)
              params = {}
              params[:groupname] = group_name if group_name
              params[:groupId] = group_id if group_id
              resp = connection(**).get('/rest/api/3/group', params)
              { group: resp.body }
            end

            def create_group(name:, **)
              resp = connection(**).post('/rest/api/3/group', { name: name })
              { group: resp.body }
            end

            def delete_group(group_name: nil, group_id: nil, **)
              resp = connection(**).delete('/rest/api/3/group') do |req|
                req.params['groupname'] = group_name if group_name
                req.params['groupId'] = group_id if group_id
              end
              { deleted: [200, 204].include?(resp.status) }
            end

            def add_user_to_group(group_name: nil, group_id: nil, account_id:, **)
              params = {}
              params[:groupname] = group_name if group_name
              params[:groupId] = group_id if group_id
              resp = connection(**).post('/rest/api/3/group/user') do |req|
                req.params = params
                req.body = { accountId: account_id }
              end
              { group: resp.body }
            end

            def remove_user_from_group(group_name: nil, group_id: nil, account_id:, **)
              resp = connection(**).delete('/rest/api/3/group/user') do |req|
                req.params['groupname'] = group_name if group_name
                req.params['groupId'] = group_id if group_id
                req.params['accountId'] = account_id
              end
              { removed: [200, 204].include?(resp.status) }
            end

            def bulk_get_groups(start_at: 0, max_results: 50, **)
              params = { startAt: start_at, maxResults: max_results }
              resp = connection(**).get('/rest/api/3/group/bulk', params)
              { groups: resp.body }
            end

            def find_groups(query: nil, max_results: 50, **)
              params = { maxResults: max_results }
              params[:query] = query if query
              resp = connection(**).get('/rest/api/3/groups/picker', params)
              { groups: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
