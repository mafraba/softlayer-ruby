#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  # A client is responsible for storing authentication information for API calls and
  # it serves as a centeral repository for the Service instances that call into the
  # network API.
  #
  # When you create a client, you pass in hash arguments specifying how the client
  # should access the SoftLayer API.
  #
  # The following symbols are the keys for options you pass to the constructor:
  # - +:username+ - a non-empty string providing the username to use for requests to the client
  # - +:api_key+ - a non-empty string providing the api key to use for requests to the client
  # - +:endpoint_url+ - a non-empty string providing the endpoint URL to use for requests to the client
  #
  # If any of these are missing then the Client class will look to the SoftLayer::Config
  # class to provide the missing information.  Please see that class for details.
  #
  class Client
    # A username passed as authentication for each request. Cannot be emtpy or nil.
    attr_reader :username

    # An API key passed as part of the authentication of each request. Cannot be emtpy or nil.
    attr_reader :api_key

    # The base URL for requests that are passed to the server. Cannot be emtpy or nil.
    attr_reader :endpoint_url

    # A string passsed as the value for the User-Agent header when requests are sent to SoftLayer API.
    attr_accessor :user_agent

    # An integer value (in seconds). The number of seconds to wait for HTTP requests to the network API
    # until they timeout. This value can be nil in which case the timeout will be the default value for
    # the library handling network communication (often 30 seconds)
    attr_reader :network_timeout

    ##
    # The client class maintains an (optional) default client. The default client
    # will be used by many methods if you do not provide an explicit client.
    @@default_client = nil

    ##
    # :attr_accessor:
    # The client class can maintain a single instance of Client as the "default client"
    # Other parts of the library that accept a client as part of their calling sequence
    # will look for the default client if one is not provided in the call
    #
    # This routine returns the client set as the default client.  It can be nil
    def self.default_client
      return @@default_client
    end

    def self.default_client=(new_default)
      @@default_client = new_default
    end

    ##
    #
    # Clients are built with a number of settings:
    # * <b>+:username+</b> - The username of the account you wish to access through the API
    # * <b>+:api_key+</b> - The API key used to authenticate the user with the API
    # * <b>+:enpoint_url+</b> - The API endpoint the client should connect to.  This defaults to API_PUBLIC_ENDPOINT
    # * <b>+:user_agent+</b> - A string that is passed along as the user agent when the client sends requests to the server
    # * <b>+:timeout+</b> - An integer number of seconds to wait until network requests time out.  Corresponds to the network_timeout property of the client
    #
    # If these arguments are not provided then the client will try to locate them using other
    # sources including global variables, and the SoftLayer config file (if one exists)
    #
    def initialize(options = {})
      @services = { }

      settings = Config.client_settings(options)

      # pick up the username from the options, the global, or assume no username
      @username = settings[:username] || ""

      # do a similar thing for the api key
      @api_key = settings[:api_key] || ""

      # and the endpoint url
      @endpoint_url = settings[:endpoint_url] || API_PUBLIC_ENDPOINT

      # set the user agent to the one provided, or set it to a default one
      @user_agent = settings[:user_agent] || "softlayer_api gem/#{SoftLayer::VERSION} (Ruby #{RUBY_PLATFORM}/#{RUBY_VERSION})"

      # and assign a time out if the settings offer one
      @network_timeout = settings[:timeout] if settings.has_key?(:timeout)

      raise "A SoftLayer Client requires a username" if !@username || @username.empty?
      raise "A SoftLayer Client requires an api_key" if !@api_key || @api_key.empty?
      raise "A SoftLayer Clietn requires an enpoint URL" if !@endpoint_url || @endpoint_url.empty?
    end

    # return a hash of the authentication headers for the client
    def authentication_headers
      {
        "authenticate" => {
          "username" => @username,
          "apiKey" => @api_key
        }
      }
    end

    # Returns a service with the given name.
    #
    # If a service has already been created by this client that same service
    # will be returned each time it is called for by name. Otherwise the system
    # will try to construct a new service object and return that.
    #
    # If the service has to be created then the service_options will be passed
    # along to the creative function. However, when returning a previously created
    # Service, the service_options will be ignored.
    #
    # If the service_name provided does not start with 'SoftLayer_' that prefix
    # will be added
    def service_named(service_name, service_options = {})
      raise ArgumentError,"Please provide a service name" if service_name.nil? || service_name.empty?

      # Strip whitespace from service_name and ensure that it starts with "SoftLayer_".
      # If it does not, then add the prefix.
      full_name = service_name.to_s.strip
      if not full_name =~ /\ASoftLayer_/
        full_name = "SoftLayer_#{service_name}"
      end

      # if we've already created this service, just return it
      # otherwise create a new service
      service_key = full_name.to_sym
      if !@services.has_key?(service_key)
        @services[service_key] = SoftLayer::Service.new(full_name, {:client => self}.merge(service_options))
      end

      @services[service_key]
    end

    def [](service_name)
      service_named(service_name)
    end
  end
end
