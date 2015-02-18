#!/usr/bin/env ruby
require_relative '../lib/cloudfs'

CLIENT_ID = ''
CLIENT_SECRET = ''
BASE_URL = ''

TEST_USERNAME = ''
TEST_USER_PASSWORD = ''

if __FILE__ == $0
	begin
	# Initialize Session
	session = CloudFS::Session.new(CLIENT_ID, CLIENT_SECRET, BASE_URL)
	session.is_linked?		#=> false

	# Authenticate session with test user credentials
	session.authenticate(TEST_USERNAME, TEST_USER_PASSWORD)
	session.is_linked?		#=> true
	
	# Access Filesystem and list root
	fs = session.filesystem
	puts "List items under root #{fs.root.list}"
	
	# Create folder under root
	folder = fs.root.create_folder("My First Folder", exists: 'OVERWRITE')

	# Upload file in our new folder with string contents
	file = folder.upload("Hello World!", name: "Hello.txt", exists: "OVERWRITE", 
			upload_io: true)

	# Read file contents
	file.tell	#=> 0
	puts "Read file content: #{file.read}"

	# List folder
	puts "List folder #{folder.list}"

	# List root
	puts "List items under root #{fs.root.list}"

	# Permanently delete the folder that we created and file in it
	folder.delete(commit: true, force: true)

	# Unlink session
	session.unlink
	rescue CloudFS::Client::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end
end
