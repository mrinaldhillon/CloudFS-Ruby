require_relative 'version'
require_relative 'client/connection'
require_relative 'client/constants'
require_relative 'client/utils'
require_relative 'client/error'

module CloudFS
	# Provides low level mapping apis to Bitcasa CloudFS Service
	#
	#	@author Mrinal Dhillon
	#	Maintains an instance of RESTful {Client::Connection}, 
	#		since Client::Connection instance is MT-safe 
	#		and can be called from several threads without synchronization 
	#		after setting up an instance, same behaviour is expected from Client class. 
	#		Should use single instance for all calls per remote server accross 
	#		multiple threads for performance.
	#
	#	@note
	#		path, destination as input parameter expects absolute path (url) of
	#		object in end-user's account.
	#
	# @example
	#		Authenticate
	#		client = CloudFS::Client.new(clientid, secret, host)
	#		client.authenticate(username, password)
	#		client.ping
	#	@example Upload file
	#		::File.open(local_file_path, "r") do |file|
	#			client.upload(path, file, 
	#					name: 'somename', exists: 'FAIL')
	#		end
	#	@example Download file
	#		Download into buffer
	#		buffer = client.download(path, startbyte: 0, bytecount: 1000)
	#
	#		Streaming download i.e. chunks are synchronously returned as soon as available
	#			preferable for large files download:
	#
	#		::File.open(local_filepath, 'wb') do |file|
	#				client.download(path) { |buffer| file.write(buffer) }
	#		end
	#	
	# @optimize Support async requests, 
	#		blocker methods like wait for async operations,
	#		chunked/streaming upload i.e. chunked upload(not sure if server supports), 
	#		StringIO, String upload, debug
	class Client

		# Creates Client instance that manages rest api calls to CloudFS service
		#
		# @param clientid [String] application clientid
		# @param secret [String] application secret
		# @param host [String] server address
		#	@param [Hash] params RESTful connection configurations
		#	@option params [Fixnum] :connect_timeout (60) for server handshake
		#	@option params [Fixnum] :send_timeout (0) for send request, 
		#		default is set to never, in order to support large uploads 
		#	@option params [Fixnum] :receive_timeout (120) for read timeout per block 
		#	@option params [Fixnum] :max_retry (3) for http 500 level errors
		#	@option params [#<<] :http_debug (nil) to enable http debugging, 
		#		example STDERR, STDOUT, {::File} object opened with permissions to write
		#
		#	@raise [Errors::ArgumentError]	
		#	@optimize Configurable chunk size for chunked stream downloads,default is 16KB.
		#		Configurable keep alive timeout for persistent connections in 
		#		connection pool, default is 15 seconds.
		#		Async api support
		# @review optimum default values for send and receive timeouts
		def initialize(clientid, secret, host, **params)
			fail Errors::ArgumentError, 
				"Invalid argument provided" if ( Utils.is_blank?(clientid) || 
						Utils.is_blank?(secret) || Utils.is_blank?(host) )
			
			@clientid = "#{clientid}"
			@secret = "#{secret}"
			@host = /https:\/\// =~ host ? "#{host}" : 
					"#{Constants::URI_PREFIX_HTTPS}#{host}"
			@access_token = nil

			connect_timeout, send_timeout, receive_timeout, max_retries, http_debug = 
						params.values_at(:connect_timeout, :send_timeout, :receive_timeout, 
								:max_retries, :http_debug)
			connect_timeout ||= 60
			send_timeout ||= 0
			receive_timeout ||= 120
			max_retries ||= 3

			@http_connection = Connection.new(connect_timeout: connect_timeout, 
					send_timeout: send_timeout, receive_timeout: receive_timeout, 
					max_retries: max_retries, debug_dev: http_debug,
					agent_name: "#{Constants::HTTP_AGENT_NAME} (#{CloudFS::VERSION})") 
		end

		# @return [Boolean] whether client can make authenticated 
		#		requests to cloudfs service
		# @raise [Errors::ServiceError]
		def linked?
			ping
			true
			rescue Errors::SessionNotLinked
				false
		end

		# Unlinks this client object from cloudfs user's account
		# @note this will disconnect all keep alive connections and internal sessions
		def unlink
			if @access_token
				@access_token = ''
				@http_connection.unlink
			end
			true
		end

		#	Obtains an OAuth2 access token that authenticates an end-user for this client
		# @param username [String] username of the end-user
		# @param password [String] password of the end-user
		# @return [true]
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def authenticate(username, password)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass username" if Utils.is_blank?(username)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass password" if Utils.is_blank?(password)

			date = Time.now.utc.strftime(Constants::DATE_FORMAT)
			form = {
				Constants::PARAM_GRANT_TYPE => Constants::PARAM_PASSWORD, 
				Constants::PARAM_PASSWORD => password, 
				Constants::PARAM_USER => username
			}
		
			headers = {
				Constants::HEADER_CONTENT_TYPE =>
					Constants::CONTENT_TYPE_APP_URLENCODED, 
				Constants::HEADER_DATE => date
			}	

			uri = { endpoint: Constants::ENDPOINT_OAUTH }
			signature = Utils.generate_auth_signature(Constants::ENDPOINT_OAUTH, 
					form, headers, @secret)
			headers[Constants::HEADER_AUTHORIZATION] = 
				"#{Constants::HEADER_AUTH_PREFIX_BCS} #{@clientid}:#{signature}"
			
			access_info = request('POST', uri: uri, header: headers, body: form)
			@access_token = access_info.fetch(:access_token)
			true
		end

		# Ping cloudfs server to verifies the end-user’s access token
		# @return [true]
		# @raise [Errors::SessionNotLinked, Errors::ServiceError]
		def ping
			request('GET', uri: { endpoint: Constants::ENDPOINT_PING }, 
				 	header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
			true
		end

		# Creates a new end-user account for a Paid CloudFS (developer’s) account
		#
		# @param username [String] username of the end-user.
		# @param password [String] password of the end-user.
		# @param email [String] email of the end-user
		# @param first_name [String] first name of the end-user
		# @param last_name [String] last name of the end-user
		#
		# @return [Hash] end-user's attributes
		# @raise [Errors::ServiceError, Errors::ArgumentError]
		def create_account(username, password, email: nil, 
				first_name: nil, last_name: nil)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass username" if Utils.is_blank?(username)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass password" if Utils.is_blank?(password)

			date = Time.now.utc.strftime(Constants::DATE_FORMAT)
			form = {
				Constants::PARAM_PASSWORD => password, 
				Constants::PARAM_USER  => username
			}
	
			form[Constants::PARAM_EMAIL] = email unless Utils.is_blank?(email)
			form[Constants::PARAM_FIRST_NAME] = 
				first_name unless Utils.is_blank?(first_name)
			form[Constants::PARAM_LAST_NAME] = 
				last_name unless Utils.is_blank?(last_name)
			
			headers = {
				Constants::HEADER_CONTENT_TYPE =>
					Constants::CONTENT_TYPE_APP_URLENCODED , 
				Constants::HEADER_DATE => date
			}	
			uri = { endpoint: Constants::ENDPOINT_CUSTOMERS }
			signature = Utils.generate_auth_signature(Constants::ENDPOINT_CUSTOMERS, 
					form, headers, @secret)
			headers[Constants::HEADER_AUTHORIZATION] = 
				"#{Constants::HEADER_AUTH_PREFIX_BCS} #{@clientid}:#{signature}"
			
			request('POST', uri: uri, header: headers,	body: form)
		end	

		# Get cloudfs end-user profile information
		#
		# @return [Hash] account metadata for the authenticated user		
		# @raise [Errors::SessionNotLinked, Errors::ServiceError]
		def get_profile
			uri = { endpoint: Constants::ENDPOINT_USER_PROFILE }
			
			request('GET', uri: uri, 
					header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end

		# Create folder at specified destination path in end-user's account
		#
		# @param name [Sting] name of folder to create
		#	@param path [String] default: root, absolute path to destination folder
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME', 'REUSE')
		#
		# @return [Hash] metadata of created folder
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		# @review why this api returns an array of items
		def create_folder(name, path: nil, exists: 'FAIL')
			fail Errors::ArgumentError, 
				"Invalid argument, must pass name" if Utils.is_blank?(name)
			exists = Constants::EXISTS.fetch(exists.to_sym) { 
				fail Errors::ArgumentError, "Invalid value for exists" }
		
			uri = set_uri_params(Constants::ENDPOINT_FOLDERS, name: path)
			query = { operation: Constants::QUERY_OPS_CREATE }
			form = {name: name, exists: exists}

			response = request('POST', uri: uri, query: query, body: form)
			items = response.fetch(:items)
			items.first
		end
		
		# @param path [String] defaults: root, folder path to list
		# @param depth [Fixnum] default: nil, levels to recurse, 0 - infinite depth 
		# @param filter [String]
		# @param strict_traverse [Boolean] traversal based on success of filters 
		#		and possibly the depth parameters
		#
		# @return [Array<Hash>] metadata of files and folders under listed folder
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		#	@todo accept filter array, return { meta: Hash, items: Array<Hash> }
		def list_folder(path: nil, depth: nil, filter: nil, strict_traverse: false)
			fail Errors::ArgumentError, 
				"Invalid argument must pass strict_traverse of type boolean" unless !!strict_traverse == strict_traverse

			uri = set_uri_params(Constants::ENDPOINT_FOLDERS, name: path)
			query = {}
			query = { depth: depth } if depth
			unless Utils.is_blank?(filter)
				query[:filter] = filter
				query[:'strict-traverse'] = "#{strict_traverse}"
			end

			response = request('GET', uri: uri, query: query)
			response.fetch(:items)
		end

		# Delete folder
		#
		# @param path [String] folder path
		# @param commit [Boolean]
		#		set true to remove folder permanently, else will be moved to trash  
		# @param force [Boolean] set true to delete non-empty folder 
		#
		# @return [Hash] hash with key for success and deleted folder's last version
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def delete_folder(path, commit: false, force: false)
				delete(Constants::ENDPOINT_FOLDERS, path, commit: commit, force: force)
		end

		# Delete file
		#
		# @param path [String] file path
		# @param commit [Boolean]
		#		set true to remove file permanently, else will be moved to trash  
		#
		# @return [Hash] hash with key for success and deleted file's last version
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def delete_file(path, commit: false)
				delete(Constants::ENDPOINT_FILES, path, commit: commit)
		end

		# Delete private common method for file and folder
		#
		# @param endpoint [String] CloudFS endpoint for file/folder
		# @param path [String] file/folder path
		# @param commit [Boolean] 
		#		set true to remove file/folder permanently, else will be moved to trash  
		# @param force [Boolean] set true to delete non-empty folder 
		#
		# @return [Hash] hash with key for success and deleted file/folder's last version
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def delete(endpoint, path, commit: false, force: false)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass endpoint" if Utils.is_blank?(endpoint)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass path" if Utils.is_blank?(path)			
			fail Errors::ArgumentError, 
				"Invalid argument must pass commit of type boolean" unless !!commit == commit
			fail Errors::ArgumentError, 
				"Invalid argument must pass force of type boolean" unless !!force == force
			
			uri = set_uri_params(endpoint, name: path)
			query = { commit: "#{commit}" }
			query[:force] = "#{force}" if force == true

			request('DELETE', uri: uri, query: query)
		end
		
		#	Copy folder to specified destination folder
		#
		# @param path [String] source folder path
		# @param destination [String] destination folder path
		# @param name [String] new name of copied folder
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder
		#		An unused integer is appended to folder name if exists: RENAME
		#
		# @return [Hash] metadata of new folder
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def copy_folder(path, destination, name, exists: 'FAIL')
			copy(Constants::ENDPOINT_FOLDERS, path, destination, name, exists: exists)
		end
		
		#	Copy file to specified destination folder
		#
		# @param path [String] source file path
		# @param destination [String] destination folder path
		# @param name [String] new name of copied file
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing file
		#		An unused integer is appended to file name if exists: RENAME
		#
		# @return [Hash] metadata of new file
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def copy_file(path, destination, name, exists: 'RENAME')
			copy(Constants::ENDPOINT_FILES, path, destination, name, exists: exists)
		end

		#	Copy private common function for folder/file
		#
		# @param endpoint [String] folder/file server endpoint
		# @param path [String] source folder/file path
		# @param destination [String] destination folder path
		# @param name [String] name of copied folder/file, 
		#		default is source folder/file's name
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder/file
		#		An unused integer is appended to folder/file name if exists: RENAME
		#
		# @return [Hash] metadata of new folder/file
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def copy(endpoint, path, destination, name, exists: 'FAIL')
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid name" if Utils.is_blank?(name)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid destination" if Utils.is_blank?(destination)
			exists = Constants::EXISTS.fetch(exists.to_sym) { 
				raise Errors::ArgumentError, "Invalid value for exists" }
	
			destination = prepend_path_with_forward_slash(destination)
			uri = set_uri_params(endpoint, name: path)
			query = { operation: Constants::QUERY_OPS_COPY }
			form = {to: destination, name: name, exists: exists}

			response = request('POST', uri: uri, query: query, body: form)
			response.fetch(:meta, response)
		end

		#	Move folder to specified destination folder
		#
		# @param path [String] source folder path
		# @param destination [String] destination folder path
		# @param name [String] new name of moved folder
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder
		#		An unused integer is appended to folder name if exists: RENAME
		#
		# @return [Hash] metadata of moved folder
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def move_folder(path, destination, name, exists: 'FAIL')
			move(Constants::ENDPOINT_FOLDERS, path, destination, name, exists: exists)
		end
	
		#	Move file to specified destination folder
		#
		# @param path [String] source file path
		# @param destination [String] destination folder path
		# @param name [String] name of moved file
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing file
		#		An unused integer is appended to file name if exists: RENAME
		#
		# @return [Hash] metadata of moved file
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def move_file(path, destination, name, exists: 'RENAME')
			move(Constants::ENDPOINT_FILES, path, destination, name, exists: exists)
		end

		#	Move folder/file private common method
		#
		# @param endpoint [String] file/folder server endpoint
		# @param path [String] source folder/file path
		# @param destination [String] destination folder path
		# @param name [String] name of moved folder/file
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder/file
		#		An unused integer is appended to folder/file name if exists: RENAME
		#
		# @return [Hash] metadata of moved folder/file
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		# @review according to cloudfs rest api docs of move folder, 
		#		path default is root i.e. root is moved!
		def move(endpoint, path, destination, name, exists: 'FAIL')
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid name" if Utils.is_blank?(name)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid destination" if Utils.is_blank?(destination)
			exists = Constants::EXISTS.fetch(exists.to_sym) { 
				fail Errors::ArgumentError, "Invalid value for exists" }

			destination = prepend_path_with_forward_slash(destination)
			uri = set_uri_params(endpoint, name: path)
			query = { operation: Constants::QUERY_OPS_MOVE }
			form = { to: destination, exists: exists, name: name}

			response = request('POST', uri: uri, query: query, body: form)
			response.fetch(:meta, response)
		end
	
		# Get folder meta
		#
		# @param path [String] folder path
		#
		# @return [Hash] metadata of folder
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def get_folder_meta(path)
				get_meta(Constants::ENDPOINT_FOLDERS, path)
		end

		# Get file meta
		#
		# @param path [String] file path
		#
		# @return [Hash] metadata of file
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def get_file_meta(path)
				get_meta(Constants::ENDPOINT_FILES, path)
		end
		
		# Get folder/file meta private common method
		#
		# @param endpoint [String] file/folder server endpoint
		# @param path [String] file/folder path
		#
		# @return [Hash] metadata of file/folder
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def get_meta(endpoint, path)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)

			uri = set_uri_params(endpoint, name: path, operation: "meta")
			
			response = request('GET', uri: uri)
			response.fetch(:meta, response)
		end

		# Alter folder metadata
		#
		# @param path [String] folder path
		# @param version [Fixnum] version number of folder
		# @param version_conflict [String] ('FAIL', 'IGNORE') action to take 
		#		if the version on the client does not match the version on the server
		#
		#	@param [Hash] properties
		# @option properties [String] :name (nil) new name
		# @option properties [Fixnum] :date_created (nil) timestamp
		# @option properties [Fixnum] :date_meta_last_modified (nil) timestamp
		# @option properties [Fixnum] :date_content_last_modified (nil) timestamp
		# @option properties [Hash] :application_data({}) will be merged 
		#		with existing application data
		#
		# @return [Hash] updated metadata of folder
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def alter_folder_meta(path, version, version_conflict: 'FAIL', **properties)
			alter_meta(Constants::ENDPOINT_FOLDERS, path, version, 
					version_conflict: version_conflict, **properties)
		end

		# Alter file metadata
		#
		# @param path [String] file path
		# @param version [Fixnum] version number of file
		# @param version_conflict [String] ('FAIL', 'IGNORE') action to take 
		#		if the version on client does not match the version on server
		#
		#	@param [Hash] properties
		# @option properties [String] :name (nil) new name
		# @option properties [Fixnum] :date_created (nil) timestamp
		# @option properties [Fixnum] :date_meta_last_modified (nil) timestamp
		# @option properties [Fixnum] :date_content_last_modified (nil) timestamp
		# @option properties [Hash] :application_data ({}) will be merged 
		#		with existing application data
		#
		# @return [Hash] updated metadata of file
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def alter_file_meta(path, version, version_conflict: 'FAIL', **properties)
			alter_meta(Constants::ENDPOINT_FILES, path, version, 
					version_conflict: version_conflict, **properties)
		end

		# Alter file/folder meta common private method
		#
		# @param endpoint [String] file/folder server endpoint
		# @param path [String] file/folder path
		# @param version [String, Fixnum] version number of file/folder
		# @param version_conflict [String] ('FAIL', 'IGNORE') action to take 
		#		if the version on the client does not match the version on the server
		#
		#	@param [Hash] properties
		# @option properties [String] :name (nil) new name
		# @option properties [Fixnum] :date_created (nil) timestamp
		# @option properties [Fixnum] :date_meta_last_modified (nil) timestamp
		# @option properties [Fixnum] :date_content_last_modified (nil) timestamp
		# @option properties [Hash] :application_data ({}) will be merged 
		#		with existing application data
		#
		# @return [Hash] updated metadata of file/folder
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		# @review does not suppress multi_json exception for application data
		def alter_meta(endpoint, path, version, version_conflict: 'FAIL', **properties)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass path" if Utils.is_blank?(path)
			
			version_conflict = 
			Constants::VERSION_CONFLICT.fetch(version_conflict.to_sym) {
			 		fail Errors::ArgumentError, "Invalid value for version-conflict" }
			uri = set_uri_params(endpoint, name: path, operation: "meta")
			
			req_properties = {}
			req_properties = properties.dup unless properties.empty?
			application_data = req_properties[:application_data]
			req_properties[:application_data] = 
				Utils.hash_to_json(application_data) unless Utils.is_blank?(application_data)
			req_properties[:'version'] = "#{version}"
			req_properties[:'version-conflict'] = version_conflict

			response = request('POST', uri: uri, body: req_properties)
			response.fetch(:meta, response)
		end

		# Upload file
		# @param path [String] path to upload file to 
		# @param source [#read&#pos&#pos=, String] any object that 
		#		responds to first set of methods or is an in-memory string
		# @param name [String] name of uploaded file, must be set 
		#		if source does not respond to #path
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME', 'REUSE') 
		#		action to take if the filename of the file being uploaded conflicts 
		#		with an existing file
		#
		# @return [Hash] metadata of uploaded file
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		# @example
		#		Upload file
		# 		::File.open(local_file_path, "r") do |file|
		#				client.upload(path, file, name: "testfile.txt")
		#			end
		#	@example
		#		Upload string
		#			client.upload(path, "This is upload string", name: 'testfile.txt')
		#		Upload stream
		#			io = StringIO.new
		#			io.write("this is test stringio")
		#			client.upload(path, io, name: 'testfile.txt')
		#			io.close
		#	@note	name must be set if source does not respond to #path
		# @todo reuse fallback and reuse attributes
		def upload(path, source, name: nil, exists: 'FAIL')
			exists = Constants::EXISTS.fetch(exists.to_sym) { 
				fail Errors::ArgumentError, "Invalid value for exists" }

			if source.respond_to?(:path)
						name ||= ::File.basename(source.path)
			elsif Utils.is_blank?(name)
				fail Errors::ArgumentError, "Invalid argument, custom name is required if source does not respond to path"
			end

			if source.respond_to?(:pos) && source.respond_to?(:pos=)
				original_pos = source.pos
				# Setting source offset to start of stream
				source.pos=0
			end

			uri = set_uri_params(Constants::ENDPOINT_FILES, name: path) 
			form = {file: source, exists: exists}
			form[:name] = name
			
			headers = {
				Constants::HEADER_CONTENT_TYPE => 
					Constants::CONTENT_TYPE_MULTI 
			}	
			begin
				request('POST', uri: uri, header: headers,	body: form)
			ensure
				# Reset source offset to original position
				source.pos=original_pos if source.respond_to?(:pos=)
			end
		end

		# Download file
		#
		# @param path [String] path of file in end-user's account
		# @param startbyte [Fixnum] starting byte (offset) in file
		# @param bytecount [Fixnum] number of bytes to download
		#
		# @yield [String] chunk of data as soon as available, 
		#		chunksize size may vary each time
		# @return [String] file data is returned if no block given
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		#	@example
		#		Download into buffer
		#		buffer = client.download(path, startbyte: 0, bytecount: 1000)
		#
		#		Streaming download i.e. chunks are synchronously returned as soon as available
		#			preferable for large files download:
		#
		#		::File.open(local_filepath, 'wb') do |file|
		#				client.download(path) { |buffer| file.write(buffer) }
		#		end
		def download(path, startbyte: 0, bytecount: 0, &block)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass path" if Utils.is_blank?(path)
			fail Errros::ArgumentError, 
				"Size must be positive" if (bytecount < 0 || startbyte < 0)

			uri = set_uri_params(Constants::ENDPOINT_FILES, name: path) 
			header = Constants::HEADER_CONTENT_TYPE_APP_URLENCODED.dup
			
			unless startbyte == 0 && bytecount == 0
				if bytecount == 0
					header[:Range] = "bytes=#{startbyte}-"
				else
					header[:Range] = "bytes=#{startbyte}-#{startbyte + bytecount - 1}"
				end
			end

			request('GET', uri: uri, header: header, &block)
		end

		# List specified version of file
		#
		# @param path [String] file path
		# @param version [Fixnum] desired version of the file referenced by path
		#
		# @return [Hash] metatdata passed version of file
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		# @review  If current version of file is passed, CloudFS Server 
		#		returns unspecified error 9999, works for pervious file versions.
		def list_single_file_version(path, version)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" unless version.is_a?(Fixnum)
			
			uri = set_uri_params(Constants::ENDPOINT_FILES, name: path, 
					operation: "versions/#{version}")

			request('GET', uri: uri, 
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end
	
		# Given a specified version, set that version’s metadata to 
		#		current metadata for the file, creating a new version in the process
		#
		# @param path [String] file path
		# @param version [Fixnum] version of file specified by path
		#
		# @return [Hash] update metadata with new version number
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def promote_file_version(path, version)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid version" unless version.is_a?(Fixnum)
			
			uri = set_uri_params(Constants::ENDPOINT_FILES, name: path, 
					operation: "versions/#{version}")
			query = { operation: Constants::QUERY_OPS_PROMOTE }
			
			request('POST', uri: uri, query: query)
		end

		# List versions of file
		#
		# @param path [String] file path
		# @param start_version [Fixnum] version number to begin listing file versions
		# @param stop_version [Fixnum] version number from which to stop 
		#		listing file versions
		# @param limit [Fixnum] how many versions to list in the result set. 
		#		It can be negative.
		#
		# @return [Array<Hash>] hashes representing metadata for selected versions 
		#		of the file as recorded in the History
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		# @review Returns empty items array if file has no old version
		def list_file_versions(path, start_version: 0, stop_version: nil, limit: 10)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			
			uri = set_uri_params(Constants::ENDPOINT_FILES, name: path, 
					operation: "versions")

			query = {
				:'start-version' => start_version, :'limit' => limit
			}
			query[:'stop-version'] = stop_version if stop_version
			
			request('GET', uri: uri, query: query,
					header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end
	
		# Creates a share of locations specified by the passed list of paths
		#
		# @param paths [Array<String>] array of file/folder paths in end-user's account
		#
		# @return [Hash] metadata of share
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		#	@review according to cloudfs rest doc: If the share points to a single item, 
		#		only the share data is returned (not the item’s metadata).
		#		Observed only share data returned even when share points to multiple paths?
		def create_share(paths)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid list of paths" if Utils.is_blank?(paths)
		
			body = Array(paths).map{ |path|
				path = prepend_path_with_forward_slash(path)
				"path=#{Utils.urlencode(path)}"}.join("&")
			
			uri = { endpoint: Constants::ENDPOINT_SHARES }
			
			request('POST', uri: uri, body: body)
		end

		# Deletes the user created share
		#
		# @param share_key [String] id of the share to be deleted
		#
		# @return [Hash] hash containing success string
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def delete_share(share_key)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid share key" if Utils.is_blank?(share_key)

			uri = set_uri_params(Constants::ENDPOINT_SHARES, name: "#{share_key}/")

			request('DELETE', uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end
	
		# List files and folders in a share	
		#
		# @param share_key [String] id of the share
		# @param path [String] path to any folder in share, default is root of share
		#
		# @return [Hash] metadata of browsed path in share defaults share, 
		#		share's metadata and array of hashes representing list of items 
		#		under browsed item if folder - { :meta => Hash, share: Hash, :items => Array<Hash> }
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def browse_share(share_key, path: nil)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(share_key)

			uri = set_uri_params(Constants::ENDPOINT_SHARES, 
					name: "#{share_key}#{path}", operation: "meta")

			request('GET', uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end
	
		# Lists the metadata of the shares the authenticated user has created 
		#
		# @return [Array<Hash>] metatdata of user's shares
		# @raise [Errors::SessionNotLinked, Errors::ServiceError]
		def list_shares
			uri = { endpoint: Constants::ENDPOINT_SHARES }
			
			request('GET', uri: uri,
					header: Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end

		# Add contents of share to user's filesystem
		#
		# @param share_key [String] id of the share
		# @param path [String] default root, path in user's account to receive share at
		# @param exists [String] ('RENAME', 'FAIL', 'OVERWRITE']
		#
		# @return [Array<Hash>] metadata of files and folders in share
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def receive_share(share_key, path: nil, exists: 'RENAME')
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid share key" if Utils.is_blank?(share_key)
			exists = Constants::EXISTS.fetch(exists.to_sym) { 
				fail Errors::ArgumentError, "Invalid value for exists" }

			uri = set_uri_params(Constants::ENDPOINT_SHARES, name: "#{share_key}/")
			form = { exists: exists }
			form[:path] = path unless Utils.is_blank?(path)

			request('POST', uri: uri, body: form)
		end
			
		# Unlock share
		#
		# @param share_key [String] id of the share
		# @param password [String] password of share
		#
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def unlock_share(share_key, password)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(share_key)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(password)
			
			uri = set_uri_params(Constants::ENDPOINT_SHARES, name: share_key, 
					operation: "unlock")
			form = { password: password }
			
			request('POST', uri: uri, body: form)
		end
		
		# Alter share info
		# 	changes, adds, or removes the share’s password or updates the name
		#
		# @param share_key [String] id of the share whose attributes are to be changed
		#	@param current_password [String] current password for this share,
		#		if has been set, it is necessary even if share has been unlocked
		# @param password [String] new password of share
		# @param name [String] new name of share
		#
		# @return [Hash] updated metadata of share
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		#	@review remove password has not been tested
		def alter_share_info(share_key, current_password: nil, 
				password: nil, name: nil)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(share_key)
			
			uri = set_uri_params(Constants::ENDPOINT_SHARES, name: share_key, 
					operation: "info")
			form = {}
			form[:current_password] = current_password if current_password			
			form[:password] = password if password
			form[:name] = name unless Utils.is_blank?(name)

			request('POST', uri: uri, body: form)
		end

		# List the history of file, folder, and share actions
		#
		# @param start [Fixnum] version number to start listing historical actions from, 
		#		default -10. It can be negative in order to get most recent actions.
		# @param stop [Fixnum] version number to stop listing historical actions from (non-inclusive)
		#
		# @return [Array<Hash>] history items
		# @raise [Errors::SessionNotLinked, Errors::ServiceError]
		def list_history(start: -10, stop: nil)
			uri = { endpoint: Constants::ENDPOINT_HISTORY }
			query = { start: start }
			query[:stop] = stop if stop
			
			request('GET', uri: uri, query: query,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end

		# List files and folders in trash at specified path
		#
		# @param path [String] path to location in user's trash, defaults to root of trash
		#
		# @return [Hash] metadata of browsed trash item 
		#		and array of hashes representing list of items under browsed item if folder -
		#		 { :meta => Hash, :items => <Hash> }
		# @raise [Errors::SessionNotLinked, Errors::ServiceError]
		def browse_trash(path: nil)
			uri = set_uri_params(Constants::ENDPOINT_TRASH, name: path)
			request('GET', uri: uri,
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end

		# Delete trash item
		#
		# @param path [String] default: trash root, path to location in user's trash, 
		#		default all trash items are deleted
		#
		# @return [Hash] containing success: true
		# @raise [Errors::SessionNotLinked, Errors::ServiceError]
		# @review CloudFS Server returns Unspecified Error 9999 if no path provided, 
		#		expected behaviour is to delete all items in trash
		def delete_trash_item(path: nil)
			uri = set_uri_params(Constants::ENDPOINT_TRASH, name: path)
			request('DELETE', uri: uri, 
					header:  Constants::HEADER_CONTENT_TYPE_APP_URLENCODED)
		end

		# Recover trash item
		#
		# @param path [String] path to location in user's trash
		# @param restore [String] ('FAIL', 'RESCUE', 'RECREATE') action to take 
		#		if recovery operation encounters issues
		# @param destination [String] rescue (default root) or recreate(named path) 
		#		path depending on exists option to place item into if the original 
		#		path does not exist
		#
		# @raise [Errors::SessionNotLinked, Errors::ServiceError, Errors::ArgumentError]
		def recover_trash_item(path, restore: 'FAIL', destination: nil)
			fail Errors::ArgumentError, 
				"Invalid argument, must pass valid path" if Utils.is_blank?(path)
			restore = Constants::RESTORE.fetch(restore.to_sym) { 
				fail Errors::ArgumentError, "Invalid value for restore" }
			
			uri = set_uri_params(Constants::ENDPOINT_TRASH, name: path)
			
			form = { :'restore' => restore }
			if restore == Constants::RESTORE[:RESCUE]
				unless Utils.is_blank?(destination)
					destination = prepend_path_with_forward_slash(destination)
					form[:'rescue-path'] = destination
				end
			elsif restore == Constants::RESTORE[:RECREATE]
					unless Utils.is_blank?(destination)
					destination = prepend_path_with_forward_slash(destination)
					form[:'recreate-path'] = destination
					end
			end
				
			request('POST', uri: uri, body: form)
		end

		# Common private method to send http request to cloudfs service
		#
		# @param method [String, Symbol] ('GET', 'POST', 'DELETE') http verb
		#
		# @param uri [Hash] containing endpoint and name that is endpoint suffix
		#		uri: { :endpoint => "/v2/folders", :name => "{ path }/meta" }
		# @param header [Hash] containing key:value pairs for request header
		# @param query [Hash] containing key:value pairs of query
		# @param body [Hash, String] containing key:value pairs for post forms-
		#		body: { :grant_type => "password", :password => "xyz" },
		#		body: { :file => (File,StringIO), :name => "name" }
		#		body: "path=pathid&path=pathdid&path=pathid"
		#
		# @return [Hash, String] containing result from cloudfs sevice or file data
		# @raise [Errors::SessionNotLinked, Errors::ServiceError]
		def request(method, uri: {}, header: {}, query: {}, body: {}, &block)
			header = {
				Constants::HEADER_AUTHORIZATION => "Bearer #{@access_token}"
			}.merge(header)
				
			unless (uri[:endpoint] == Constants::ENDPOINT_OAUTH ||
						uri[:endpoint] == Constants::ENDPOINT_CUSTOMERS) 
				fail Errors::SessionNotLinked if Utils.is_blank?(@access_token)
			end

			url = create_url(@host, endpoint: uri[:endpoint], name: uri[:name])
			body = set_multipart_upload_body(body)
			response = @http_connection.request(method, url, query: query, 
						header: header, body: body, &block)
			parse_response(response)
			rescue Errors::ServerError
					Errors::raise_service_error($!)
		end
		
		# Set multipart body for file upload
		# @param body [Hash]
		# @return [Array<Hash>] mutipart upload forms
		def set_multipart_upload_body(body={})
			return body unless body.is_a?(Hash) && body.key?(:file)

			file = body[:file]
			exists = body[:exists]	
			
			if Utils.is_blank?(body[:name])
				path = file.respond_to?(:path) ? file.path : ''
				filename = ::File.basename(path)
			else
				filename = body[:name]
			end

			multipart_body = []
			multipart_body << { 'Content-Disposition' => 'form-data; name="exists"', 
							:content => exists } if exists
			multipart_body << {'Content-Disposition' => 
						"form-data; name=\"file\"; filename=\"#{filename}\"", 
						"Content-Type" => "application/octet-stream", 
							:content => file }
			multipart_body
		end

		# Create url
		#		appends endpoint and name prefix to host
		#
		#	@param host [String] server address
		#	@param endpoint [String] server endpoint
		# @param name [String] name prefix
		#
		# @return [String] url
		def create_url(host, endpoint: nil, name: nil)
			"#{host}#{endpoint}#{name}"
		end

		# Create response
		#		parses cloudfs service response into hash
		#
		# @param response [Hash]
		#		@see CloudFS::Client::Connection#request
		#
		# @return [Hash] response from cloudfs service
		def parse_response(response)
			if response[:content_type] && 
				response[:content_type].include?("application/json")

				resp = Utils.json_to_hash(response.fetch(:content))
				resp.fetch(:result, resp)
			else
		 		response.fetch(:content) 			
			end	
		end

		# Prepend path with '/'
		#
		# @param [String, nil] path
		#
		# @return [String] path
		def prepend_path_with_forward_slash(path)
			if Utils.is_blank?(path)
					path = "/"
			elsif path[0] != '/'
				path = "#{path}".insert(0, '/')
			end
			path
		end
		
		# Set uri params
		#
		# @param endpoint [String] server endpoint
		# @param name [String] path prefix
		# @param operation [String] path prefix 
		#
		# @return [Hash] uri { :endpoint => "/v2/xyz", :name => "/abc/meta" }
		# @optimize clean this method
		def set_uri_params(endpoint, name: nil, operation: nil)
			uri = { endpoint: endpoint }
			delim = nil
			# removing new line and spaces from end and begining of name
			unless Utils.is_blank?(name)
				name = name.strip
				delim =	'/' unless name[-1] == '/'
			end
			# append to name with delim if operation is given
			name = "#{name}#{delim}#{operation}" unless Utils.is_blank?(operation)
			unless Utils.is_blank?(name)
				if endpoint.to_s[-1] == '/' && name[0] == '/'
					# remove leading / from name if endpoint has traling /
					name = name[1..-1]
				elsif endpoint.to_s[-1] != '/' && name.to_s[0] != '/'
					# insert leading / to name
					name =  "#{name}".insert(0, '/')
				end
				uri[:name] = name
			end
			uri
		end	 

		private :delete, :copy, :move, :get_meta, :alter_meta, :request,
		 :set_multipart_upload_body, :parse_response, :create_url, 
		 :prepend_path_with_forward_slash, :set_uri_params

	end
end
