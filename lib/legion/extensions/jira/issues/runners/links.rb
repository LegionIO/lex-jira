# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Links
            include Legion::Extensions::Jira::Helpers::Client

            def create_issue_link(type_name:, inward_issue:, outward_issue:, comment: nil, **)
              body = {
                type:         { name: type_name },
                inwardIssue:  { key: inward_issue },
                outwardIssue: { key: outward_issue }
              }
              body[:comment] = { body: comment } if comment
              resp = connection(**).post('/rest/api/3/issueLink', body)
              { created: resp.status == 201 }
            end

            def get_issue_link(link_id:, **)
              resp = connection(**).get("/rest/api/3/issueLink/#{link_id}")
              { link: resp.body }
            end

            def delete_issue_link(link_id:, **)
              resp = connection(**).delete("/rest/api/3/issueLink/#{link_id}")
              { deleted: resp.status == 204, link_id: link_id }
            end

            def list_link_types(**)
              resp = connection(**).get('/rest/api/3/issueLinkType')
              { link_types: resp.body }
            end

            def get_link_type(link_type_id:, **)
              resp = connection(**).get("/rest/api/3/issueLinkType/#{link_type_id}")
              { link_type: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
