# frozen_string_literal: true

require 'legion/extensions/jira/version'
require 'legion/extensions/jira/helpers/client'
require 'legion/extensions/jira/runners/issues'
require 'legion/extensions/jira/runners/projects'
require 'legion/extensions/jira/runners/boards'
require 'legion/extensions/jira/client'

module Legion
  module Extensions
    module Jira
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
