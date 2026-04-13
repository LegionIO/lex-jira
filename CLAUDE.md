# lex-jira: Jira Integration for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-other/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that connects LegionIO to Jira via the REST API v3 and Agile API. Provides runners for issue management, project queries, board/sprint operations, users, groups, permissions, dashboards, filters, webhooks, and audit records.

**GitHub**: https://github.com/LegionIO/lex-jira
**License**: MIT
**Version**: 0.2.0

## Architecture

```
Legion::Extensions::Jira
├── Issues/Runners/         # 11 runners: Issues, Search, Comments, Attachments,
│                           #   Links, RemoteLinks, Transitions, Votes, Watchers,
│                           #   Worklogs, Properties
├── Projects/Runners/       # 5 runners: Projects, Categories, Components, Roles, Versions
├── Agile/Runners/          # 4 runners: Boards, Sprints, Epics, Backlogs
├── Users/Runners/          # 1 runner: Users
├── Groups/Runners/         # 1 runner: Groups
├── Permissions/Runners/    # 1 runner: Permissions
├── Dashboards/Runners/     # 1 runner: Dashboards
├── Filters/Runners/        # 1 runner: Filters
├── Webhooks/Runners/       # 1 runner: Webhooks
├── AuditRecords/Runners/   # 1 runner: AuditRecords
├── Helpers/
│   └── Client              # connection() and upload_connection() (Faraday, Basic Auth)
└── Client                  # Standalone client class (includes all runners)
```

## Key Files

| Path | Purpose |
|------|---------|
| `lib/legion/extensions/jira.rb` | Entry point, extension registration |
| `lib/legion/extensions/jira/client.rb` | Standalone Client class (includes all runners) |
| `lib/legion/extensions/jira/helpers/client.rb` | Faraday connection builder: `connection()` and `upload_connection()` |
| `lib/legion/extensions/jira/issues/runners/issues.rb` | Issue CRUD (create, get, update, delete) |
| `lib/legion/extensions/jira/issues/runners/search.rb` | JQL search |
| `lib/legion/extensions/jira/issues/runners/comments.rb` | Comment management |
| `lib/legion/extensions/jira/issues/runners/attachments.rb` | File attachment upload |
| `lib/legion/extensions/jira/issues/runners/transitions.rb` | Issue workflow transitions |
| `lib/legion/extensions/jira/issues/runners/links.rb` | Issue link management |
| `lib/legion/extensions/jira/issues/runners/remote_links.rb` | Remote link management |
| `lib/legion/extensions/jira/issues/runners/votes.rb` | Vote management |
| `lib/legion/extensions/jira/issues/runners/watchers.rb` | Watcher management |
| `lib/legion/extensions/jira/issues/runners/worklogs.rb` | Worklog management |
| `lib/legion/extensions/jira/issues/runners/properties.rb` | Issue property management |
| `lib/legion/extensions/jira/projects/runners/projects.rb` | Project list/get/create/update/delete |
| `lib/legion/extensions/jira/projects/runners/categories.rb` | Project category runners |
| `lib/legion/extensions/jira/projects/runners/components.rb` | Project component runners |
| `lib/legion/extensions/jira/projects/runners/roles.rb` | Project role runners |
| `lib/legion/extensions/jira/projects/runners/versions.rb` | Project version runners |
| `lib/legion/extensions/jira/agile/runners/boards.rb` | Agile board runners |
| `lib/legion/extensions/jira/agile/runners/sprints.rb` | Sprint runners |
| `lib/legion/extensions/jira/agile/runners/epics.rb` | Epic runners |
| `lib/legion/extensions/jira/agile/runners/backlogs.rb` | Backlog runners |
| `lib/legion/extensions/jira/users/runners/users.rb` | User management |
| `lib/legion/extensions/jira/groups/runners/groups.rb` | Group management |
| `lib/legion/extensions/jira/permissions/runners/permissions.rb` | Permission queries |
| `lib/legion/extensions/jira/dashboards/runners/dashboards.rb` | Dashboard runners |
| `lib/legion/extensions/jira/filters/runners/filters.rb` | Filter runners |
| `lib/legion/extensions/jira/webhooks/runners/webhooks.rb` | Webhook management |
| `lib/legion/extensions/jira/audit_records/runners/audit_records.rb` | Audit record queries |

## Authentication

Jira REST API uses HTTP Basic Auth with `email` (Atlassian account email) and `api_token`. Obtain an API token at https://id.atlassian.com/manage-profile/security/api-tokens.

## Dependencies

| Gem | Purpose |
|-----|---------|
| `faraday` (>= 2.0) | HTTP client for Jira REST API |
| `faraday-multipart` | Multipart form support for file attachments |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
