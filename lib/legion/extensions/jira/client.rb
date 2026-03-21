# frozen_string_literal: true

require_relative 'helpers/client'
require_relative 'runners/issues'
require_relative 'runners/projects'
require_relative 'runners/boards'

module Legion
  module Extensions
    module Jira
      class Client
        include Helpers::Client
        include Runners::Issues
        include Runners::Projects
        include Runners::Boards

        attr_reader :opts

        def initialize(url:, email:, api_token:, **extra)
          @opts = { url: url, email: email, api_token: api_token, **extra }
        end

        def settings
          { options: @opts }
        end

        def connection(**override)
          super(**@opts, **override)
        end
      end
    end
  end
end
