# lex-jira: Jira Integration for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-other/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that connects LegionIO to Jira via the REST API v3 and Agile API. Provides runners for issue management, project queries, and board/sprint operations.

**GitHub**: https://github.com/LegionIO/lex-jira
**License**: MIT
**Version**: 0.1.0

## Architecture

```
Legion::Extensions::Jira
├── Runners/
│   ├── Issues    # create_issue, get_issue, update_issue, search_issues, transition_issue, add_comment
│   ├── Projects  # list_projects, get_project
│   └── Boards    # list_boards, get_board, get_sprints
├── Helpers/
│   └── Client    # Faraday connection (Jira REST API v3, Basic Auth)
└── Client        # Standalone client class (includes all runners)
```

## Key Files

| Path | Purpose |
|------|---------|
| `lib/legion/extensions/jira.rb` | Entry point, extension registration |
| `lib/legion/extensions/jira/runners/issues.rb` | Issue CRUD, search, transitions, comments |
| `lib/legion/extensions/jira/runners/projects.rb` | Project list/get runners |
| `lib/legion/extensions/jira/runners/boards.rb` | Board and sprint runners (Jira Software Agile API) |
| `lib/legion/extensions/jira/helpers/client.rb` | Faraday connection builder (HTTP Basic Auth: email + API token) |
| `lib/legion/extensions/jira/client.rb` | Standalone Client class |

## Authentication

Jira REST API uses HTTP Basic Auth with `email` (Atlassian account email) and `api_token`. Obtain an API token at https://id.atlassian.com/manage-profile/security/api-tokens.

## Dependencies

| Gem | Purpose |
|-----|---------|
| `faraday` (>= 2.0) | HTTP client for Jira REST API |

## Development

16 specs total.

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
