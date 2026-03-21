# Changelog

## [0.1.0] - 2026-03-21

### Added
- Initial release
- `Helpers::Client` — Faraday connection builder with Basic auth (email + API token)
- `Runners::Issues` — create_issue, get_issue, update_issue, search_issues, transition_issue, add_comment
- `Runners::Projects` — list_projects, get_project
- `Runners::Boards` — list_boards, get_board, get_sprints
- Standalone `Client` class for use outside the Legion framework
