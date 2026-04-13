# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Projects
        module Runners
          module Categories
            include Legion::Extensions::Jira::Helpers::Client

            def list_project_categories(**)
              resp = connection(**).get('/rest/api/3/projectCategory')
              { categories: resp.body }
            end

            def get_project_category(category_id:, **)
              resp = connection(**).get("/rest/api/3/projectCategory/#{category_id}")
              { category: resp.body }
            end

            def create_project_category(name:, description: nil, **)
              body = { name: name }
              body[:description] = description if description
              resp = connection(**).post('/rest/api/3/projectCategory', body)
              { category: resp.body }
            end

            def update_project_category(category_id:, name: nil, description: nil, **)
              body = {}
              body[:name] = name if name
              body[:description] = description if description
              resp = connection(**).put("/rest/api/3/projectCategory/#{category_id}", body)
              { category: resp.body }
            end

            def delete_project_category(category_id:, **)
              resp = connection(**).delete("/rest/api/3/projectCategory/#{category_id}")
              { deleted: resp.status == 204, category_id: category_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
