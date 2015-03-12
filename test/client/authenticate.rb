#!/usr/bin/env ruby
require_relative '../../lib/bitcasa/client'

module TestAuthApi
	extend self
	@clientid = "moEW3ytPj3OQLaw90coxdwc7caE2rLUYG80akd83oCQ"
	@secret = "ta_iaXp0AHF4m0C_re0-HUXrcecU-S87G5rN4kXGGI-ijea8Fydzwn7oDm3--_2g0X1xSnK-237CF9Ir-d7oig"
	@host = "woqmx11zzd.cloudfs.io"
	@username = "mrinal.dhillon@izeltech.com"
	@password = "Pa55w0rd"

	def get_client(http_debug: nil)
    CloudFS::RestAdapter.new(@clientid, @secret, @host, http_debug: http_debug)
	end

	def authenticate(client)
		puts "Authenticating.."
		client.authenticate(@username, @password)
		client.ping
	end

	def get_profile(client)
		puts "\nGet User Profile"
		resp = client.get_profile
		puts resp
	end

	def setup_and_authenticate
		client = get_client
		authenticate(client)
		get_profile(client)
	end

end

if __FILE__ == $0
	begin
		TestAuthApi.setup_and_authenticate
	rescue CloudFS::RestAdapter::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end
end
