require_relative 'client/authenticate'
require_relative 'client/folder'
require_relative 'client/files'

# Define creadentials in client/authenticate

if __FILE__ == $0
	begin
		puts "Test Authenticate********************************************************"
		client = TestAuthApi.get_client
		TestAuthApi.authenticate(client)
		puts "End Test Authenticate****************************************************"
		puts "\nTest Folder Api********************************************************"
		TestFolderApi.api(client)
		puts "\nEnd Test Folder Api****************************************************"
		puts "\nTest File Api********************************************************"
		TestFileApi.api(client)
		puts "\nEnd Test File Api******************************************************"
	rescue Bitcasa::Client::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end
end
