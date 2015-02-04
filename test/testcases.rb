#!/usr/bin/env ruby
require_relative './session'
require_relative './file'
require_relative './folder'
require_relative './filesystem'

# Define credentials in ./session.rb
# Run ./client.rb to test low level apis

if __FILE__ == $0
	begin
		puts "Test Session Api ****************************************************"
		session = TestSession.sessionapi
		puts "End Test Session Api ****************************************************"
		puts "Test File Api ****************************************************"
		TestFile.api(session)
		puts "End Test File Api ****************************************************"
		# No need to test folder though since most of testcases 
		#	are covered in file and filesystem	
		puts "Test Folder Api ****************************************************"
		TestFolder.api(session)	
		puts "End Test Folder Api ****************************************************"
		puts "Test Filesytem Api ****************************************************"
		TestFileSystem.api(session)
		puts "End Test Filesytem Api ***************************************************"
	rescue Bitcasa::Client::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end

end
