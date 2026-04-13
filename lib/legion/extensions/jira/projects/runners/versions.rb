# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Projects
        module Runners
          module Versions
            include Legion::Extensions::Jira::Helpers::Client

            def list_project_versions(project_key:, **)
              resp = connection(**).get("/rest/api/3/project/#{project_key}/versions")
              { versions: resp.body }
            end

            def get_version(version_id:, **)
              resp = connection(**).get("/rest/api/3/version/#{version_id}")
              { version: resp.body }
            end

            def create_version(project_id:, name:, description: nil, released: nil, start_date: nil,
                               release_date: nil, **)
              body = { projectId: project_id, name: name }
              body[:description] = description if description
              body[:released] = released unless released.nil?
              body[:startDate] = start_date if start_date
              body[:releaseDate] = release_date if release_date
              resp = connection(**).post('/rest/api/3/version', body)
              { version: resp.body }
            end

            def update_version(version_id:, name: nil, description: nil, released: nil, **)
              body = {}
              body[:name] = name if name
              body[:description] = description if description
              body[:released] = released unless released.nil?
              resp = connection(**).put("/rest/api/3/version/#{version_id}", body)
              { version: resp.body }
            end

            def delete_version(version_id:, move_fixed_issues_to: nil, move_affected_issues_to: nil, **)
              params = {}
              params[:moveFixIssuesTo] = move_fixed_issues_to if move_fixed_issues_to
              params[:moveAffectedIssuesTo] = move_affected_issues_to if move_affected_issues_to
              resp = connection(**).delete("/rest/api/3/version/#{version_id}") do |req|
                req.params = params
              end
              { deleted: resp.status == 204, version_id: version_id }
            end

            def merge_versions(version_id:, move_issues_to:, **)
              resp = connection(**).put("/rest/api/3/version/#{version_id}/mergeto/#{move_issues_to}")
              { merged: resp.status == 204, version_id: version_id }
            end

            def move_version(version_id:, position: nil, after: nil, **)
              body = {}
              body[:position] = position if position
              body[:after] = after if after
              resp = connection(**).post("/rest/api/3/version/#{version_id}/move", body)
              { version: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
