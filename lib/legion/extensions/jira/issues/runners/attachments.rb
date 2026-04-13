# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Attachments
            include Legion::Extensions::Jira::Helpers::Client

            def get_attachments(issue_key:, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}", { fields: 'attachment' })
              { attachments: resp.body.dig('fields', 'attachment') || [] }
            end

            def get_attachment(attachment_id:, **)
              resp = connection(**).get("/rest/api/3/attachment/#{attachment_id}")
              { attachment: resp.body }
            end

            def add_attachment(issue_key:, file:, filename: 'file', content_type: 'application/octet-stream', **)
              payload = { file: Faraday::Multipart::FilePart.new(file, content_type, filename) }
              resp = upload_connection(**).post("/rest/api/3/issue/#{issue_key}/attachments", payload)
              { attachments: resp.body }
            end

            def delete_attachment(attachment_id:, **)
              resp = connection(**).delete("/rest/api/3/attachment/#{attachment_id}")
              { deleted: resp.status == 204, attachment_id: attachment_id }
            end

            def get_attachment_meta(**)
              resp = connection(**).get('/rest/api/3/attachment/meta')
              { meta: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
