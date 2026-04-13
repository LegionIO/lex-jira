# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Properties
            include Legion::Extensions::Jira::Helpers::Client

            def get_issue_properties(issue_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/properties")
              { properties: resp.body }
            end

            def get_issue_property(issue_key:, property_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/properties/#{property_key}")
              { property: resp.body }
            end

            def set_issue_property(issue_key:, property_key:, value:, **)
              resp = connection(**).put("/rest/api/3/issue/#{issue_key}/properties/#{property_key}", value)
              { set: [200, 201].include?(resp.status), issue_key: issue_key, property_key: property_key }
            end

            def delete_issue_property(issue_key:, property_key:, **)
              resp = connection(**).delete("/rest/api/3/issue/#{issue_key}/properties/#{property_key}")
              { deleted: resp.status == 204, issue_key: issue_key, property_key: property_key }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
