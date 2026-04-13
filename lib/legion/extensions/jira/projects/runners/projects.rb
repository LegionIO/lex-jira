# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Projects
        module Runners
          module Projects
            include Legion::Extensions::Jira::Helpers::Client

            def list_projects(expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get('/rest/api/3/project', params)
              { projects: resp.body }
            end

            def get_project(project_key:, expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get("/rest/api/3/project/#{project_key}", params)
              { project: resp.body }
            end

            def create_project(key:, name:, project_type_key:, lead_account_id:, description: nil, **)
              body = { key: key, name: name, projectTypeKey: project_type_key, leadAccountId: lead_account_id }
              body[:description] = description if description
              resp = connection(**).post('/rest/api/3/project', body)
              { project: resp.body }
            end

            def update_project(project_key:, name: nil, description: nil, lead_account_id: nil, **)
              body = {}
              body[:name] = name if name
              body[:description] = description if description
              body[:leadAccountId] = lead_account_id if lead_account_id
              resp = connection(**).put("/rest/api/3/project/#{project_key}", body)
              { project: resp.body }
            end

            def delete_project(project_key:, **)
              resp = connection(**).delete("/rest/api/3/project/#{project_key}")
              { deleted: resp.status == 204, project_key: project_key }
            end

            def search_projects(query: nil, start_at: 0, max_results: 50, **)
              params = { startAt: start_at, maxResults: max_results }
              params[:query] = query if query
              resp = connection(**).get('/rest/api/3/project/search', params)
              { projects: resp.body }
            end

            def get_project_statuses(project_key:, **)
              resp = connection(**).get("/rest/api/3/project/#{project_key}/statuses")
              { statuses: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
