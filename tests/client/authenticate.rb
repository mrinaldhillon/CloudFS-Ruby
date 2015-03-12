#!/usr/bin/env ruby
require_relative '../../lib/cloudfs/rest_adapter'

module TestAuthApi
	extend self
	@clientid = '84R2MXW09PT-oVzuz2w42E325mvQXQccJKVWFalznU4'
	@secret = 'ebG9-6CKI6qjtJsFtChUwsiN9-Hf7xd6_u_Br0A5KP-4EDiqKX2gQ0ju-RJr0BdSJpzGmM6COI-Fdjgi7pNblw'
	@host = 'b796hixubr.cloudfs.io'
	@username = 'gihand@calcey.com'
	@password = 'user@123'

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
