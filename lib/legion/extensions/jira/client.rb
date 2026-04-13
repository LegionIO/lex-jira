# frozen_string_literal: true

module Legion
  module Extensions
    module Jira
      class Client
        include Helpers::Client

        # Issues
        include Issues::Runners::Issues
        include Issues::Runners::Search
        include Issues::Runners::Comments
        include Issues::Runners::Transitions
        include Issues::Runners::Attachments
        include Issues::Runners::Worklogs
        include Issues::Runners::Links
        include Issues::Runners::RemoteLinks
        include Issues::Runners::Votes
        include Issues::Runners::Watchers
        include Issues::Runners::Properties

        # Projects
        include Projects::Runners::Projects
        include Projects::Runners::Components
        include Projects::Runners::Versions
        include Projects::Runners::Roles
        include Projects::Runners::Categories

        # Users, Groups, Permissions
        include Users::Runners::Users
        include Groups::Runners::Groups
        include Permissions::Runners::Permissions

        # Dashboards & Filters
        include Dashboards::Runners::Dashboards
        include Filters::Runners::Filters

        # Agile
        include Agile::Runners::Boards
        include Agile::Runners::Sprints
        include Agile::Runners::Epics
        include Agile::Runners::Backlogs

        # Admin
        include Webhooks::Runners::Webhooks
        include AuditRecords::Runners::AuditRecords

        attr_reader :opts

        def initialize(url:, email:, api_token:, **extra)
          @opts = { url: url, email: email, api_token: api_token, **extra }
        end

        def settings
          { options: @opts }
        end

        def connection(**override)
          super(**@opts.merge(override))
        end

        def upload_connection(**override)
          super(**@opts.merge(override))
        end
      end
    end
  end
end
