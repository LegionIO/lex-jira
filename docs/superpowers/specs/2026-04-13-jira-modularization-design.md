# lex-jira Modularization Design

**Date**: 2026-04-13
**Status**: Draft

## Goal

Restructure lex-jira from a flat runner layout (3 modules, ~11 methods) into a nested domain-based module structure covering the Jira REST API v3 and Agile API. Each domain gets its own namespace with runners inside, while the top-level `Client` class includes all runners for a unified interface.

## Module Structure

Ten domain namespaces, 27 runner modules total:

### Issues (11 runners)

| Runner | Namespace | Methods |
|--------|-----------|---------|
| Issues | `Jira::Issues::Runners::Issues` | `create_issue`, `get_issue`, `update_issue`, `delete_issue`, `bulk_create_issues`, `get_issue_changelog` |
| Search | `Jira::Issues::Runners::Search` | `search_issues` (JQL), `pick_issues`, `parse_jql`, `autocomplete_jql` |
| Comments | `Jira::Issues::Runners::Comments` | `get_issue_comments`, `get_comment`, `add_comment`, `update_comment`, `delete_comment` |
| Attachments | `Jira::Issues::Runners::Attachments` | `get_attachments`, `get_attachment`, `add_attachment`, `delete_attachment`, `get_attachment_meta` |
| Worklogs | `Jira::Issues::Runners::Worklogs` | `get_issue_worklogs`, `get_worklog`, `add_worklog`, `update_worklog`, `delete_worklog` |
| Links | `Jira::Issues::Runners::Links` | `create_issue_link`, `get_issue_link`, `delete_issue_link`, `list_link_types`, `get_link_type` |
| RemoteLinks | `Jira::Issues::Runners::RemoteLinks` | `get_remote_links`, `get_remote_link`, `create_remote_link`, `update_remote_link`, `delete_remote_link` |
| Votes | `Jira::Issues::Runners::Votes` | `get_votes`, `add_vote`, `remove_vote` |
| Watchers | `Jira::Issues::Runners::Watchers` | `get_watchers`, `add_watcher`, `remove_watcher` |
| Properties | `Jira::Issues::Runners::Properties` | `get_issue_properties`, `get_issue_property`, `set_issue_property`, `delete_issue_property` |
| Transitions | `Jira::Issues::Runners::Transitions` | `get_transitions`, `transition_issue` |

### Projects (5 runners)

| Runner | Namespace | Methods |
|--------|-----------|---------|
| Projects | `Jira::Projects::Runners::Projects` | `list_projects`, `get_project`, `create_project`, `update_project`, `delete_project`, `search_projects`, `get_project_statuses` |
| Components | `Jira::Projects::Runners::Components` | `list_project_components`, `get_component`, `create_component`, `update_component`, `delete_component` |
| Versions | `Jira::Projects::Runners::Versions` | `list_project_versions`, `get_version`, `create_version`, `update_version`, `delete_version`, `merge_versions`, `move_version` |
| Roles | `Jira::Projects::Runners::Roles` | `list_project_roles`, `get_project_role`, `set_role_actors`, `add_role_actors`, `remove_role_actor` |
| Categories | `Jira::Projects::Runners::Categories` | `list_project_categories`, `get_project_category`, `create_project_category`, `update_project_category`, `delete_project_category` |

### Users (1 runner)

| Runner | Namespace | Methods |
|--------|-----------|---------|
| Users | `Jira::Users::Runners::Users` | `get_user`, `create_user`, `delete_user`, `bulk_get_users`, `find_users`, `find_users_by_query`, `get_myself`, `get_user_columns` |

### Groups (1 runner)

| Runner | Namespace | Methods |
|--------|-----------|---------|
| Groups | `Jira::Groups::Runners::Groups` | `get_group`, `create_group`, `delete_group`, `add_user_to_group`, `remove_user_from_group`, `bulk_get_groups`, `find_groups` |

### Permissions (1 runner)

| Runner | Namespace | Methods |
|--------|-----------|---------|
| Permissions | `Jira::Permissions::Runners::Permissions` | `get_my_permissions`, `get_all_permissions`, `get_permission_schemes`, `get_permission_scheme`, `get_permitted_projects` |

### Dashboards (1 runner)

| Runner | Namespace | Methods |
|--------|-----------|---------|
| Dashboards | `Jira::Dashboards::Runners::Dashboards` | `list_dashboards`, `get_dashboard`, `create_dashboard`, `update_dashboard`, `delete_dashboard`, `copy_dashboard` |

### Filters (1 runner)

| Runner | Namespace | Methods |
|--------|-----------|---------|
| Filters | `Jira::Filters::Runners::Filters` | `list_favorite_filters`, `get_filter`, `create_filter`, `update_filter`, `delete_filter`, `get_filter_share_permissions`, `add_filter_share_permission`, `delete_filter_share_permission` |

### Agile (4 runners)

| Runner | Namespace | Methods |
|--------|-----------|---------|
| Boards | `Jira::Agile::Runners::Boards` | `list_boards`, `get_board`, `get_board_configuration`, `get_board_issues` |
| Sprints | `Jira::Agile::Runners::Sprints` | `get_sprint`, `create_sprint`, `update_sprint`, `delete_sprint`, `get_sprint_issues`, `move_issues_to_sprint` |
| Epics | `Jira::Agile::Runners::Epics` | `get_epic`, `get_epic_issues`, `move_issues_to_epic` |
| Backlogs | `Jira::Agile::Runners::Backlogs` | `move_issues_to_backlog` |

### Webhooks (1 runner)

| Runner | Namespace | Methods |
|--------|-----------|---------|
| Webhooks | `Jira::Webhooks::Runners::Webhooks` | `list_webhooks`, `register_webhooks`, `delete_webhooks`, `refresh_webhooks` |

### AuditRecords (1 runner)

| Runner | Namespace | Methods |
|--------|-----------|---------|
| AuditRecords | `Jira::AuditRecords::Runners::AuditRecords` | `get_audit_records` |

## File Layout

```
lib/legion/extensions/jira/
├── helpers/
│   └── client.rb
├── issues/
│   └── runners/
│       ├── issues.rb
│       ├── search.rb
│       ├── comments.rb
│       ├── attachments.rb
│       ├── worklogs.rb
│       ├── links.rb
│       ├── remote_links.rb
│       ├── votes.rb
│       ├── watchers.rb
│       ├── properties.rb
│       └── transitions.rb
├── projects/
│   └── runners/
│       ├── projects.rb
│       ├── components.rb
│       ├── versions.rb
│       ├── roles.rb
│       └── categories.rb
├── users/
│   └── runners/
│       └── users.rb
├── groups/
│   └── runners/
│       └── groups.rb
├── permissions/
│   └── runners/
│       └── permissions.rb
├── dashboards/
│   └── runners/
│       └── dashboards.rb
├── filters/
│   └── runners/
│       └── filters.rb
├── agile/
│   └── runners/
│       ├── boards.rb
│       ├── sprints.rb
│       ├── epics.rb
│       └── backlogs.rb
├── webhooks/
│   └── runners/
│       └── webhooks.rb
├── audit_records/
│   └── runners/
│       └── audit_records.rb
├── client.rb
├── version.rb
└── jira.rb (entry point)
```

## Helpers::Client

Single `connection` method shared by all runners. Same base URL, same Basic Auth. Runners specify their own API path prefix (`/rest/api/3/` or `/rest/agile/1.0/`).

```ruby
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
```

## Client Class

Top-level client includes all 27 runner modules. Stores credentials in `@opts` and overrides `connection` to merge them.

```ruby
module Legion
  module Extensions
    module Jira
      class Client
        include Helpers::Client
        include Issues::Runners::Issues
        include Issues::Runners::Search
        include Issues::Runners::Comments
        include Issues::Runners::Attachments
        include Issues::Runners::Worklogs
        include Issues::Runners::Links
        include Issues::Runners::RemoteLinks
        include Issues::Runners::Votes
        include Issues::Runners::Watchers
        include Issues::Runners::Properties
        include Issues::Runners::Transitions
        include Projects::Runners::Projects
        include Projects::Runners::Components
        include Projects::Runners::Versions
        include Projects::Runners::Roles
        include Projects::Runners::Categories
        include Users::Runners::Users
        include Groups::Runners::Groups
        include Permissions::Runners::Permissions
        include Dashboards::Runners::Dashboards
        include Filters::Runners::Filters
        include Agile::Runners::Boards
        include Agile::Runners::Sprints
        include Agile::Runners::Epics
        include Agile::Runners::Backlogs
        include Webhooks::Runners::Webhooks
        include AuditRecords::Runners::AuditRecords

        attr_reader :opts

        def initialize(url:, email:, api_token:, **extra)
          @opts = { url: url, email: email, api_token: api_token, **extra }
        end

        def connection(**override)
          super(**@opts.merge(override))
        end
      end
    end
  end
end
```

## Runner Pattern

Every runner follows this template:

```ruby
# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module Issues
        module Runners
          module Comments
            include Legion::Extensions::Jira::Helpers::Client

            def get_issue_comments(issue_key:, start_at: 0, max_results: 50, **)
              resp = connection(**).get("/rest/api/3/issue/#{issue_key}/comment",
                                       startAt: start_at, maxResults: max_results)
              { comments: resp.body }
            end

            def add_comment(issue_key:, body:, **)
              payload = { body: body }
              resp = connection(**).post("/rest/api/3/issue/#{issue_key}/comment", payload)
              { comment: resp.body }
            end

            # ...

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                         Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
```

Agile runners use `/rest/agile/1.0/` prefix instead:

```ruby
def list_boards(project_key: nil, start_at: 0, max_results: 50, **)
  params = { startAt: start_at, maxResults: max_results }
  params[:projectKeyOrId] = project_key if project_key
  resp = connection(**).get('/rest/agile/1.0/board', params)
  { boards: resp.body }
end
```

## Testing

Each runner module gets its own spec file mirroring the source layout:

```
spec/legion/extensions/jira/
├── issues/runners/issues_spec.rb
├── issues/runners/comments_spec.rb
├── issues/runners/search_spec.rb
├── ...
├── agile/runners/boards_spec.rb
├── agile/runners/sprints_spec.rb
├── ...
└── client_spec.rb
```

Specs use Faraday test adapter stubs (matching the existing pattern). Tests exercise the runner method, verify the HTTP verb + path + params, and check the return shape.

## Scope Summary

- **10 domains**: Issues, Projects, Users, Groups, Permissions, Dashboards, Filters, Agile, Webhooks, AuditRecords
- **27 runner modules**
- **~130 methods** total across all runners
- **Skipped**: Configuration & Metadata (Workflows, IssueTypes, Fields, Priorities, Resolutions, Statuses, Screens, NotificationSchemes, SecuritySchemes), Labels, Avatars, ServerInfo, TimeTracking
