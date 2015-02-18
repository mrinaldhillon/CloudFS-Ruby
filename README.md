# CloudFS-Ruby SDK for ruby

##	Synopsis

* This sdk provides a simple filesystem like interface to Bitcasa CloudFS service.
* It enables application to create authenticated RESTful interfaces 
	to filesystem objects in end-user's CloudFS account.

##	Features

* Supports current set of CloudFS rest apis except following features.

##	Not Supported
*	File upload does not support reuse exists option.
*	Cannot set application_data and properties on files or folders at creation time.

##	Installation

	$ gem install cloudfs_sdk

## Usage

```ruby
# in Gemfile
	gem 'cloudfs_sdk'

# in application
	require 'cloudfs'
```

##	Configuration
*	Session:
		You need to initailize session with clientid, secret and api server 
		host given in your CloudFS account.

```ruby
		session = CloudFS::Session.new(clientid, secret, host)
```

*	Connection Configurations:
		Http connection configuration options are provided to support varied 
		environment and usage scenarios: connect_timeout, receive_timeout, 
		send_timeout, max_retries(http 500 level errors).

```ruby
		session = CloudFS::Session.new(clientid, secret, host, connect_timeout: 60, 
			receive_timeout: 120, send_timeout: 240, max_retries: 3)
```

*	Authenticate:
		Authenticate the session with username and password of your CloudFS application.

```ruby	
		session.authenticate(username, password)
```


##	Debug
*	In order to log http wire trace initialize session with http_debug option 
	with an object that responds to #<<. For example STDERR, STDOUT, File etc.

```ruby
		session = CloudFS::Session.new(clientid, secret, host, http_debug: STDERR)
```

## Hello World

```ruby
	# tests/hello_world.rb

	require 'cloudfs'

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
```
