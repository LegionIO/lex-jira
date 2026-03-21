# frozen_string_literal: true

module Legion
  module Extensions
    module Jira
      module Runners
        module Projects
          def list_projects(**)
            resp = connection(**).get('/rest/api/3/project')
            { projects: resp.body }
          end

          def get_project(project_key:, **)
            resp = connection(**).get("/rest/api/3/project/#{project_key}")
            { project: resp.body }
          end
        end
      end
    end
  end
end
