# frozen_string_literal: true

RSpec.describe Legion::Extensions::Jira::Client do
  subject(:client) do
    described_class.new(
      url:       'https://acme.atlassian.net',
      email:     'user@example.com',
      api_token: 'secret-token'
    )
  end

  describe '#initialize' do
    it 'stores url in opts' do
      expect(client.opts[:url]).to eq('https://acme.atlassian.net')
    end

    it 'stores email in opts' do
      expect(client.opts[:email]).to eq('user@example.com')
    end

    it 'stores api_token in opts' do
      expect(client.opts[:api_token]).to eq('secret-token')
    end
  end

  describe '#settings' do
    it 'returns a hash with options key' do
      expect(client.settings).to eq({ options: client.opts })
    end
  end

  describe '#connection' do
    it 'returns a Faraday connection' do
      expect(client.connection).to be_a(Faraday::Connection)
    end
  end

  describe '#upload_connection' do
    it 'returns a Faraday connection' do
      expect(client.upload_connection).to be_a(Faraday::Connection)
    end
  end

  describe 'runner inclusion' do
    it 'includes all 27 runner modules' do
      expected_modules = [
        Legion::Extensions::Jira::Issues::Runners::Issues,
        Legion::Extensions::Jira::Issues::Runners::Search,
        Legion::Extensions::Jira::Issues::Runners::Comments,
        Legion::Extensions::Jira::Issues::Runners::Transitions,
        Legion::Extensions::Jira::Issues::Runners::Attachments,
        Legion::Extensions::Jira::Issues::Runners::Worklogs,
        Legion::Extensions::Jira::Issues::Runners::Links,
        Legion::Extensions::Jira::Issues::Runners::RemoteLinks,
        Legion::Extensions::Jira::Issues::Runners::Votes,
        Legion::Extensions::Jira::Issues::Runners::Watchers,
        Legion::Extensions::Jira::Issues::Runners::Properties,
        Legion::Extensions::Jira::Projects::Runners::Projects,
        Legion::Extensions::Jira::Projects::Runners::Components,
        Legion::Extensions::Jira::Projects::Runners::Versions,
        Legion::Extensions::Jira::Projects::Runners::Roles,
        Legion::Extensions::Jira::Projects::Runners::Categories,
        Legion::Extensions::Jira::Users::Runners::Users,
        Legion::Extensions::Jira::Groups::Runners::Groups,
        Legion::Extensions::Jira::Permissions::Runners::Permissions,
        Legion::Extensions::Jira::Dashboards::Runners::Dashboards,
        Legion::Extensions::Jira::Filters::Runners::Filters,
        Legion::Extensions::Jira::Agile::Runners::Boards,
        Legion::Extensions::Jira::Agile::Runners::Sprints,
        Legion::Extensions::Jira::Agile::Runners::Epics,
        Legion::Extensions::Jira::Agile::Runners::Backlogs,
        Legion::Extensions::Jira::Webhooks::Runners::Webhooks,
        Legion::Extensions::Jira::AuditRecords::Runners::AuditRecords
      ]
      expected_modules.each do |mod|
        expect(described_class.ancestors).to include(mod)
      end
    end
  end
end
