#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

require 'shared_server'

describe SoftLayer::VirtualServer do
	let(:sample_server) {
		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")
		allow(mock_client).to receive(:[]) do |service_name|
			service = mock_client.service_named(service_name)
			allow(service).to receive(:call_softlayer_api_with_params)
			service
		end

		SoftLayer::VirtualServer.new(mock_client, { "id" => 12345 })
	}

  it "identifies itself with the SoftLayer_Virtual_Guest service" do
    service = sample_server.service
    expect(service.server_object_id).to eq(12345)
    expect(service.target.service_name).to eq "SoftLayer_Virtual_Guest"
  end

  it "implements softlayer properties inherited from Server" do
		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")

    test_servers = fixture_from_json('test_virtual_servers')
    test_server = SoftLayer::VirtualServer.new(mock_client,test_servers.first)

    expect(test_server.hostname).to eq("test-server-1")
    expect(test_server.domain).to eq("softlayer-api-test.rb")
    expect(test_server.fullyQualifiedDomainName).to eq("test-server-1.softlayer-api-test.rb")
    expect(test_server.datacenter).to eq({"id"=>17936, "longName"=>"Dallas 6", "name"=>"dal06"})
    expect(test_server.primary_public_ip).to eq("198.51.100.121")
    expect(test_server.primary_private_ip).to eq("203.0.113.82")
    expect(test_server.notes).to eq("These are test notes")
  end

	it_behaves_like "server with port speed" do
		let (:server) { sample_server }
	end

  it_behaves_like "server with mutable hostname" do
		let (:server) { sample_server }
  end

  describe "component upgrades" do
    let(:mock_client) do
  		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")
      virtual_guest_service = mock_client[:Virtual_Guest]

      allow(virtual_guest_service).to receive(:call_softlayer_api_with_params) do |api_method, parameters, api_arguments|
        api_return = nil

        case api_method
        when :getUpgradeItemPrices
          api_return = fixture_from_json('virtual_server_upgrade_options')
        else
          fail "Unexpected call to the SoftLayer_Virtual_Guest service"
        end

        api_return
      end

      mock_client
    end

    it "retrieves the item upgrades for a server from the API once" do
      fake_virtual_server = SoftLayer::VirtualServer.new(mock_client, {"id" => 12345})
      expect(fake_virtual_server.upgrade_options).to eq fixture_from_json('virtual_server_upgrade_options')

      # once we've retrieve the options once, we shouldn't be calling back into the service to get them again
      expect(mock_client[:Virtual_Guest]).to_not receive(:call_softlayer_api_with_params)
      fake_virtual_server.upgrade_options
    end
  end
end