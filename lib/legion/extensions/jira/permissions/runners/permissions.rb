# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Permissions
        module Runners
          module Permissions
            include Legion::Extensions::Jira::Helpers::Client

            def get_my_permissions(permissions: nil, project_key: nil, issue_key: nil, **)
              params = {}
              params[:permissions] = permissions if permissions
              params[:projectKey] = project_key if project_key
              params[:issueKey] = issue_key if issue_key
              resp = connection(**).get('/rest/api/3/mypermissions', params)
              { permissions: resp.body }
            end

            def get_all_permissions(**)
              resp = connection(**).get('/rest/api/3/permissions')
              { permissions: resp.body }
            end

            def list_permission_schemes(expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get('/rest/api/3/permissionscheme', params)
              { schemes: resp.body }
            end

            def get_permission_scheme(scheme_id:, expand: nil, **)
              params = {}
              params[:expand] = expand if expand
              resp = connection(**).get("/rest/api/3/permissionscheme/#{scheme_id}", params)
              { scheme: resp.body }
            end

            def check_permissions(project_permissions:, account_id: nil, **)
              body = { projectPermissions: project_permissions }
              body[:accountId] = account_id if account_id
              resp = connection(**).post('/rest/api/3/permissions/check', body)
              { permissions: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
