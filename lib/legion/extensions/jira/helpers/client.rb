# frozen_string_literal: true

require 'faraday'

module Legion
  module Extensions
    module Jira
      module Helpers
        module Client
          def connection(url: nil, email: nil, api_token: nil, **_opts)
            base_url = url || 'https://your-org.atlassian.net'
            Faraday.new(url: base_url) do |conn|
              conn.request :json
              conn.response :json, content_type: /\bjson$/
              conn.request :authorization, :basic, email, api_token if email && api_token
              conn.adapter Faraday.default_adapter
            end
          end
        end
      end
    end
  end
end
