#!/usr/bin/env ruby
require_relative '../../lib/cloudfs/client'

module TestAuthApi
	extend self
	@clientid = ''
	@secret = ''
	@host = ''
	@username = ''
	@password = ''

	def get_client(http_debug: nil)
		CloudFS::Client.new(@clientid, @secret, @host, http_debug: http_debug)
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
	rescue CloudFS::Client::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end
end
