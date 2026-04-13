# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Webhooks
        module Runners
          module Webhooks
            include Legion::Extensions::Jira::Helpers::Client

            def list_webhooks(start_at: 0, max_results: 100, **)
              params = { startAt: start_at, maxResults: max_results }
              resp = connection(**).get('/rest/api/3/webhook', params)
              { webhooks: resp.body }
            end

            def register_webhooks(webhooks:, url:, **)
              resp = connection(**).post('/rest/api/3/webhook', { webhooks: webhooks, url: url })
              { result: resp.body }
            end

            def delete_webhooks(webhook_ids:, **)
              resp = connection(**).delete('/rest/api/3/webhook') do |req|
                req.body = { webhookIds: webhook_ids }
              end
              { deleted: [200, 202, 204].include?(resp.status) }
            end

            def refresh_webhooks(webhook_ids:, **)
              resp = connection(**).put('/rest/api/3/webhook/refresh', { webhookIds: webhook_ids })
              { result: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
