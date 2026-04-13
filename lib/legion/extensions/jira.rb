# frozen_string_literal: true

require 'legion/extensions/jira/version'
require 'legion/extensions/jira/helpers/client'

# Issues domain
require 'legion/extensions/jira/issues/runners/issues'
require 'legion/extensions/jira/issues/runners/search'
require 'legion/extensions/jira/issues/runners/comments'
require 'legion/extensions/jira/issues/runners/transitions'
require 'legion/extensions/jira/issues/runners/attachments'
require 'legion/extensions/jira/issues/runners/worklogs'
require 'legion/extensions/jira/issues/runners/links'
require 'legion/extensions/jira/issues/runners/remote_links'
require 'legion/extensions/jira/issues/runners/votes'
require 'legion/extensions/jira/issues/runners/watchers'
require 'legion/extensions/jira/issues/runners/properties'

# Projects domain
require 'legion/extensions/jira/projects/runners/projects'
require 'legion/extensions/jira/projects/runners/components'
require 'legion/extensions/jira/projects/runners/versions'
require 'legion/extensions/jira/projects/runners/roles'
require 'legion/extensions/jira/projects/runners/categories'

# Users, Groups, Permissions
require 'legion/extensions/jira/users/runners/users'
require 'legion/extensions/jira/groups/runners/groups'
require 'legion/extensions/jira/permissions/runners/permissions'

# Dashboards & Filters
require 'legion/extensions/jira/dashboards/runners/dashboards'
require 'legion/extensions/jira/filters/runners/filters'

# Agile
require 'legion/extensions/jira/agile/runners/boards'
require 'legion/extensions/jira/agile/runners/sprints'
require 'legion/extensions/jira/agile/runners/epics'
require 'legion/extensions/jira/agile/runners/backlogs'

# Admin
require 'legion/extensions/jira/webhooks/runners/webhooks'
require 'legion/extensions/jira/audit_records/runners/audit_records'

require 'legion/extensions/jira/client'

module Legion
  module Extensions
    module Jira
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
