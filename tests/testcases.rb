#!/usr/bin/env ruby
require_relative './session'
require_relative './file'
require_relative './folder'
require_relative './filesystem'

# Define credentials in ./session.rb
# Run ./rest_adapter.rb to test low level apis
# Call TestSession#sessionapi with http_debug: STDERR, STDOUT or ::File object 
#		to enable http wire trace
#	set test_debug: true in each api to enable test cases to be descriptive

if __FILE__ == $0
	begin
		test_debug = false
		puts "Test Session Api ****************************************************"
		session = TestSession.sessionapi(http_debug: nil)
		puts "End Test Session Api ****************************************************"
		puts "Test File Api ****************************************************"
		TestFile.api(session, test_debug: test_debug)
		puts "End Test File Api ****************************************************"
		# No need to test folder though since most of testcases 
		#	are covered in file and filesystem	
		puts "Test Folder Api ****************************************************"
		TestFolder.api(session, test_debug: test_debug)	
		puts "End Test Folder Api ****************************************************"
		puts "Test Filesytem Api ****************************************************"
		TestFileSystem.api(session, test_debug: test_debug)
		puts "End Test Filesytem Api ***************************************************"
		puts "\nPassed all test cases"
	rescue CloudFS::RestAdapter::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end

end
