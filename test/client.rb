require_relative 'client/authenticate'
require_relative 'client/folder'
require_relative 'client/files'

# Call TestAuthApi#get_client with http_debug: STDERR, STDOUT or ::File object 
#		to enable http debugging


if __FILE__ == $0
	begin
		puts "Test Authenticate********************************************************"
		client = TestAuthApi.get_client(http_debug: nil)
		TestAuthApi.authenticate(client)
		puts "End Test Authenticate****************************************************"
		puts "\nTest Folder Api********************************************************"
		TestFolderApi.api(client)
		puts "\nEnd Test Folder Api****************************************************"
		puts "\nTest File Api********************************************************"
		TestFileApi.api(client)
		puts "\nEnd Test File Api******************************************************"
		puts "\nPassed all test cases"
	rescue Bitcasa::Client::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end
end
