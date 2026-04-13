# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Dashboards
        module Runners
          module Dashboards
            include Legion::Extensions::Jira::Helpers::Client

            def list_dashboards(start_at: 0, max_results: 20, filter: nil, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:filter] = filter if filter
              resp = connection(**).get('/rest/api/3/dashboard', params)
              { dashboards: resp.body }
            end

            def get_dashboard(dashboard_id:, **)
              resp = connection(**).get("/rest/api/3/dashboard/#{dashboard_id}")
              { dashboard: resp.body }
            end

            def create_dashboard(name:, description: nil, share_permissions: nil, **)
              body = { name: name }
              body[:description] = description if description
              body[:sharePermissions] = share_permissions if share_permissions
              resp = connection(**).post('/rest/api/3/dashboard', body)
              { dashboard: resp.body }
            end

            def update_dashboard(dashboard_id:, name: nil, description: nil, share_permissions: nil, **)
              body = {}
              body[:name] = name if name
              body[:description] = description if description
              body[:sharePermissions] = share_permissions if share_permissions
              resp = connection(**).put("/rest/api/3/dashboard/#{dashboard_id}", body)
              { dashboard: resp.body }
            end

            def delete_dashboard(dashboard_id:, **)
              resp = connection(**).delete("/rest/api/3/dashboard/#{dashboard_id}")
              { deleted: resp.status == 204, dashboard_id: dashboard_id }
            end

            def copy_dashboard(dashboard_id:, name:, description: nil, share_permissions: nil, **)
              body = { name: name }
              body[:description] = description if description
              body[:sharePermissions] = share_permissions if share_permissions
              resp = connection(**).post("/rest/api/3/dashboard/#{dashboard_id}/copy", body)
              { dashboard: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
