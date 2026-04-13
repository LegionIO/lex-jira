# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module RemoteLinks
            include Legion::Extensions::Jira::Helpers::Client

            def get_remote_links(issue_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/remotelink")
              { remote_links: resp.body }
            end

            def get_remote_link(issue_key:, link_id:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/remotelink/#{link_id}")
              { remote_link: resp.body }
            end

            def create_remote_link(issue_key:, url:, title:, summary: nil, **)
              body = { object: { url: url, title: title } }
              body[:object][:summary] = summary if summary
              resp = connection(**).post("/rest/api/3/issue/#{issue_key}/remotelink", body)
              { remote_link: resp.body }
            end

            def update_remote_link(issue_key:, link_id:, url:, title:, summary: nil, **)
              body = { object: { url: url, title: title } }
              body[:object][:summary] = summary if summary
              resp = connection(**).put("/rest/api/3/issue/#{issue_key}/remotelink/#{link_id}", body)
              { updated: resp.status == 204, issue_key: issue_key, link_id: link_id }
            end

            def delete_remote_link(issue_key:, link_id:, **)
              resp = connection(**).delete("/rest/api/3/issue/#{issue_key}/remotelink/#{link_id}")
              { deleted: resp.status == 204, issue_key: issue_key, link_id: link_id }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
