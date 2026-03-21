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
end
