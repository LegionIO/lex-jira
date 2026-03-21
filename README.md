# lex-jira

LegionIO extension for Jira integration via the Jira REST API v3 and Agile API.

## Installation

Add to your Gemfile:

```ruby
gem 'lex-jira'
```

## Standalone Usage

```ruby
require 'legion/extensions/jira'

client = Legion::Extensions::Jira::Client.new(
  url:       'https://your-org.atlassian.net',
  email:     'user@example.com',
  api_token: 'your-api-token'
)

# Issues
client.create_issue(project_key: 'PROJ', summary: 'New bug', issue_type: 'Bug')
client.get_issue(issue_key: 'PROJ-1')
client.update_issue(issue_key: 'PROJ-1', summary: 'Updated summary')
client.search_issues(jql: 'project = PROJ AND status = Open')
client.transition_issue(issue_key: 'PROJ-1', transition_id: '31')
client.add_comment(issue_key: 'PROJ-1', body: 'Work in progress')

# Projects
client.list_projects
client.get_project(project_key: 'PROJ')

# Boards (Jira Software)
client.list_boards
client.get_board(board_id: 1)
client.get_sprints(board_id: 1)
```

## Authentication

Jira REST API uses HTTP Basic Auth with your email address and an API token.
Generate an API token at: https://id.atlassian.com/manage-profile/security/api-tokens

## License

MIT
