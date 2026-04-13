# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Filters
        module Runners
          module Filters
            include Legion::Extensions::Jira::Helpers::Client

            def list_favorite_filters(expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get('/rest/api/3/filter/favourite', params)
              { filters: resp.body }
            end

            def get_filter(filter_id:, expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get("/rest/api/3/filter/#{filter_id}", params)
              { filter: resp.body }
            end

            def create_filter(name:, jql: nil, description: nil, favourite: nil, **)
              body = { name: name }
              body[:jql] = jql if jql
              body[:description] = description if description
              body[:favourite] = favourite unless favourite.nil?
              resp = connection(**).post('/rest/api/3/filter', body)
              { filter: resp.body }
            end

            def update_filter(filter_id:, name: nil, jql: nil, description: nil, **)
              body = {}
              body[:name] = name if name
              body[:jql] = jql if jql
              body[:description] = description if description
              resp = connection(**).put("/rest/api/3/filter/#{filter_id}", body)
              { filter: resp.body }
            end

            def delete_filter(filter_id:, **)
              resp = connection(**).delete("/rest/api/3/filter/#{filter_id}")
              { deleted: resp.status == 204, filter_id: filter_id }
            end

            def get_filter_share_permissions(filter_id:, **)
              resp = connection(**).get("/rest/api/3/filter/#{filter_id}/permission")
              { permissions: resp.body }
            end

            def add_filter_share_permission(filter_id:, type:, project_id: nil, group_name: nil, **)
              body = { type: type }
              body[:projectId] = project_id if project_id
              body[:groupname] = group_name if group_name
              resp = connection(**).post("/rest/api/3/filter/#{filter_id}/permission", body)
              { permissions: resp.body }
            end

            def delete_filter_share_permission(filter_id:, permission_id:, **)
              resp = connection(**).delete("/rest/api/3/filter/#{filter_id}/permission/#{permission_id}")
              { deleted: resp.status == 204, filter_id: filter_id, permission_id: permission_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
