require 'spec_helper'

describe Puppet::Type.type(:sensu_secrets_provider).provider(:sensu_api) do
  let(:provider) { described_class }
  let(:type) { Puppet::Type.type(:sensu_secrets_provider) }
  let(:config) do
    {
      :name => 'vault',
      :client => {
        'address' => 'https://vaultserver.example.com:8200',
        'token' => 'secret',
        'version' => 'v1',
      },
      :provider => 'sensu_api',
    }
  end
  let(:resource) do
    type.new(config)
  end

  describe 'self.instances' do
    let(:opts) do
      {:api_group => 'enterprise/secrets', :api_version => 'v1', :failonfail => false}
    end
    it 'should create instances' do
      allow(provider).to receive(:api_request).with('providers', nil, opts).and_return(JSON.parse(my_fixture_read('list.json')))
      expect(provider.instances.length).to eq(4)
    end

    it 'should return the resource for a auth' do
      allow(provider).to receive(:api_request).with('providers', nil, opts).and_return(JSON.parse(my_fixture_read('list.json')))
      property_hash = provider.instances[1].instance_variable_get("@property_hash")
      expect(property_hash[:name]).to eq('my_vault')
    end
  end

  describe 'create' do
    it 'should create an auth' do
      expected_spec = {
        :spec => {
          :client => {
            'address' => 'https://vaultserver.example.com:8200',
            'token' => 'secret',
            'version' => 'v1',
            'tls' => nil,
            'rate_limiter' => nil,
            'agent_address' => '',
            'max_retries' => 2,
            'timeout' => '60s',
          }
        },
        :metadata => {
          :name => 'vault',
        },
        :api_version => 'secrets/v1',
        :type => 'VaultProvider',
      }
      expect(resource.provider).to receive(:api_request).with('providers/vault', expected_spec, {:api_group => 'enterprise/secrets', :api_version => 'v1', :method => 'put'})
      resource.provider.create
      property_hash = resource.provider.instance_variable_get("@property_hash")
      expect(property_hash[:ensure]).to eq(:present)
    end
  end

  describe 'flush' do
    it 'should update an auth config' do
      expected_spec = {
        :spec => {
          :client => {
            'address' => 'https://vaultserver.example.com:8200',
            'token' => 'secret',
            'version' => 'v1',
            'tls' => nil,
            'rate_limiter' => nil,
            'agent_address' => '',
            'max_retries' => 2,
            'timeout' => '20s',
          }
        },
        :metadata => {
          :name => 'vault',
        },
        :api_version => 'secrets/v1',
        :type => 'VaultProvider',
      }
      config[:client]['timeout'] = '20s'
      expect(resource.provider).to receive(:api_request).with('providers/vault', expected_spec, {:api_group => 'enterprise/secrets', :api_version => 'v1', :method => 'put'})
      resource.provider.client = config[:client]
      resource.provider.flush
    end
  end

  describe 'destroy' do
    it 'should delete an auth' do
      expect(resource.provider).to receive(:api_request).with('providers/vault', nil, {:api_group => 'enterprise/secrets', :api_version => 'v1', :method => 'delete'})
      resource.provider.destroy
      property_hash = resource.provider.instance_variable_get("@property_hash")
      expect(property_hash).to eq({})
    end
  end
end

