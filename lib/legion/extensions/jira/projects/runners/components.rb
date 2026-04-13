# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Projects
        module Runners
          module Components
            include Legion::Extensions::Jira::Helpers::Client

            def list_project_components(project_key:, **)
              resp = connection(**).get("/rest/api/3/project/#{project_key}/components")
              { components: resp.body }
            end

            def get_component(component_id:, **)
              resp = connection(**).get("/rest/api/3/component/#{component_id}")
              { component: resp.body }
            end

            def create_component(project_key:, name:, description: nil, lead_account_id: nil, **)
              body = { project: project_key, name: name }
              body[:description] = description if description
              body[:leadAccountId] = lead_account_id if lead_account_id
              resp = connection(**).post('/rest/api/3/component', body)
              { component: resp.body }
            end

            def update_component(component_id:, name: nil, description: nil, lead_account_id: nil, **)
              body = {}
              body[:name] = name if name
              body[:description] = description if description
              body[:leadAccountId] = lead_account_id if lead_account_id
              resp = connection(**).put("/rest/api/3/component/#{component_id}", body)
              { component: resp.body }
            end

            def delete_component(component_id:, move_issues_to: nil, **)
              params = {}
              params[:moveIssuesTo] = move_issues_to if move_issues_to
              resp = connection(**).delete("/rest/api/3/component/#{component_id}") do |req|
                req.params = params
              end
              { deleted: resp.status == 204, component_id: component_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
