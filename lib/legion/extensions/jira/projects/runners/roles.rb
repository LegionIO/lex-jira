# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Projects
        module Runners
          module Roles
            include Legion::Extensions::Jira::Helpers::Client

            def list_project_roles(project_key:, **)
              resp = connection(**).get("/rest/api/3/project/#{project_key}/role")
              { roles: resp.body }
            end

            def get_project_role(project_key:, role_id:, **)
              resp = connection(**).get("/rest/api/3/project/#{project_key}/role/#{role_id}")
              { role: resp.body }
            end

            def set_role_actors(project_key:, role_id:, user_account_ids: [], group_names: [], **)
              body = {}
              body['atlassian-user-role-actor'] = user_account_ids unless user_account_ids.empty?
              body['atlassian-group-role-actor'] = group_names unless group_names.empty?
              resp = connection(**).put("/rest/api/3/project/#{project_key}/role/#{role_id}",
                                        { categorisedActors: body })
              { role: resp.body }
            end

            def add_role_actors(project_key:, role_id:, user_account_ids: [], group_names: [], **)
              body = {}
              body[:user] = user_account_ids unless user_account_ids.empty?
              body[:group] = group_names unless group_names.empty?
              resp = connection(**).post("/rest/api/3/project/#{project_key}/role/#{role_id}", body)
              { role: resp.body }
            end

            def remove_role_actor(project_key:, role_id:, user: nil, group: nil, **)
              resp = connection(**).delete("/rest/api/3/project/#{project_key}/role/#{role_id}") do |req|
                req.params['user'] = user if user
                req.params['group'] = group if group
              end
              { removed: resp.status == 204, project_key: project_key, role_id: role_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
