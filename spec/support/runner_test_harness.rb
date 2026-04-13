# frozen_string_literal: true

module RunnerTestHarness
  def self.build(*runner_modules)
    klass = Class.new do
      include Legion::Extensions::Jira::Helpers::Client

      runner_modules.each { |mod| include mod }

      attr_reader :opts

      def initialize(**opts)
        @opts = opts
      end

      def connection(**override)
        super(**@opts.merge(override))
      end

      def upload_connection(**override)
        super(**@opts.merge(override))
      end
    end
    klass.new(url: 'https://acme.atlassian.net', email: 'user@example.com', api_token: 'secret-token')
  end

  def self.stub_connection
    stubs = Faraday::Adapter::Test::Stubs.new
    conn = Faraday.new(url: 'https://acme.atlassian.net') do |c|
      c.request :json
      c.response :json, content_type: /\bjson$/
      c.adapter :test, stubs
    end
    [stubs, conn]
  end
end
