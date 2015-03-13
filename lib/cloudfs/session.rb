require_relative 'rest_adapter'
require_relative 'account'
require_relative 'user'
require_relative 'filesystem'

module CloudFS
	# Establishes a session with the api server on behalf of an authenticated end-user
	#		
	#	It maintains a RESTful low level api {CloudFS::Client} object 
	#		that provides authenticated access to CloudFS  service end user's 
	#		account and is shared with file system objects linked with this session - 
	#		{FileSystem}, {Container}, {File}, {Folder}, {Share}, {Account}, {User}
	#
	#	@author Mrinal Dhillon
	#	@example
	#		session = CloudFS::Session.new(clientid, secret, host)
	#		session.is_linked?		#=> false
	#		session.autheticate(username, password)
	#		session.is_linked?		#=> true
	#		folder = session.filesystem.root.create_folder(folder_name)
	#		folder.name = newname
	#		folder.save
	#		file = folder.upload(local_filepath)
	#		session.unlink
	class Session
		#	@!attribute [r] filesystem
		# @return [FileSystem] {FileSystem} instance linked with this session
		def filesystem
			@filesystem ||= FileSystem.new(@rest_adapter)
		end

		#	@!attribute [r] user
		# @return [User] profile of end-user linked with this session
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::OperationNotAllowedError]
		def user
			@user ||= get_user 
		end

		#	@!attribute [r] account
		# @return [Account] end-user's account linked with this session
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::OperationNotAllowedError]
		def account
			@account ||= get_account
		end

    #	@see #admin_credentials
    def admin_credentials(admin_client_id, admin_client_secret)
      @admin_credentials[:clientid] = admin_client_id ? admin_client_id : nil
      @admin_credentials[:secret] = admin_client_secret ? admin_client_secret : nil
    end


		# @param clientid [String] account clientid
		# @param secret [String] account secret
		# @param host [String] cloudfs application api server hostname
		#	@param [Hash] http_conf RESTful connection configurations
		#	@option http_conf [Fixnum] :connect_timeout (60) for server handshake
		#	@option http_conf [Fixnum] :send_timeout (0) for send request, 
		#		default is set to never, in order to support large uploads 
		#	@option http_conf [Fixnum] :receive_timeout (120) for read timeout per block 
		#	@option http_conf [Fixnum] :max_retry (3) for http 500 level errors
		#	@option http_conf [#<<] :http_debug (nil) to enable http debugging, 
		#		example STDERR, STDOUT, {::File} object opened with permissions to write
		#	@optimize Configurable chunk size for chunked stream downloads,default is 16KB.
		#		Configurable keep alive timeout for persistent connections in 
		#		connection pool, default is 15 seconds. Async api support
		#	@review optimum default values for http timeouts
		def initialize(clientid, secret, host, **http_conf)
			@http_debug = http_conf[:http_debug]
			@rest_adapter = RestAdapter.new(clientid, secret, host, **http_conf)
			@unlinked = false
			@admin_credentials = {}
      @admin_credentials[:host] = host ? host : "access.bitcasa.com"
		end
	
		# Attempts to log into the end-user's filesystem, links this session to an account
		#
		# @param username [String] end-user's username
		# @param password [String] end-user's password
		#
		# @return [true]
		# @raise [RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::ArgumentError, RestAdapter::Errors::OperationNotAllowedError]
		def authenticate(username, password)
			validate_session
			fail RestAdapter::Errors::OperationNotAllowedError,
				"Cannot re-authenticate, initialize new session instance" if is_linked?
			
			@rest_adapter.authenticate(username, password)
		end

		# @return [Boolean] whether current session is linked to the API server 
		#		and can make authenticated requests	
		def is_linked?
			@rest_adapter.linked?
		end

		# Discards current authentication
		#
		# @note	CloudFS objects remain valid only till session is linked, 
		#		once unlinked all RESTful objects generated through this session 
		#		are expected to raise {RestAdapter::Errors::SessionNotLinked} exception
		#		for any RESTful operation.
		#	@note Session cannot be re-authenticated once unlinked.
		#
		# @return [true]
		def unlink
			@rest_adapter.unlink
			@unlinked = true
		end

		
		# Creates a new end-user account for a Paid CloudFS account
		#
		# @param username [String] username of the end-user, 
		#		must be at least 4 characters and less than 256 characters
		# @param password [String] password of the end-user, 
		#		must be at least 6 characters and has no length limit
		# @param email [String] email of the end-user
		# @param first_name [String] first name of end user
		# @param last_name [String] last name of end user
		# @return [Account] new user account
		#
		# @raise [Client::Errors::ServiceError, Client::Errors::ArgumentError, 
		#		Client::Errors::OperationNotAllowedError]
		#
		# @note Created {Account} is not linked, 
		#		authenticate this session with new account credentials before using it.
		#	@example
		#		Initialize session, create new account and link session with 
		#			created account's credentials
		#
		#		# Set credentials of prototype account	
		#		session = Session.new(clientid, secret, host) 		
		#		# Set credentials of Paid CloudFS admin account	
		#		session.admin_credentials={ clientid: clientid, secret: secret }
		#		# Create account	
		#		account = session.create_account(new_username, new_password)
		#		session.authenticate(new_username, new_password)
		#		account.usage		#=> {Fixnum}
		#
		# @review Does not allow account creation if current session has already been 
		#		authenticated. In such scenario account creation can be made possible 
		#		but returning new {Account} instance with this session's RESTful client 
		#		is not possible since session does not allow re-authentication.
		def create_account(username, password, email: nil, 
				first_name: nil, last_name: nil)
			validate_session
			fail RestAdapter::Errors::OperationNotAllowedError,
				"New account creation with already linked session is not possible, 
						initialize new session instance" if is_linked?

			admin_client = RestAdapter.new(@admin_credentials[:clientid],
					@admin_credentials[:secret], @admin_credentials[:host], 
					http_debug: @http_debug)
			begin
				response = admin_client.create_account(username, password, email: email, 
					first_name: first_name, last_name: last_name)
				Account.new(@rest_adapter, **response)
			ensure
				admin_client.unlink
			end
		end
	
		# @see #account
		def get_account
			validate_session
			response = @rest_adapter.get_profile
			Account.new(@rest_adapter, **response)
		end
	
		#	@see #user
		def get_user
			validate_session
			response = @rest_adapter.get_profile
			User.new(@rest_adapter, **response)
		end

		# Action history lists history of file, folder, and share actions
		#
		# @param start [Fixnum] version number to start listing historical actions from, 
		#		default -10. It can be negative in order to get most recent actions.
		# @param stop [Fixnum] version number to stop listing historical 
		#		actions from (non-inclusive)
		#
		# @return [Array<Hash>] action history items
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::OperationNotAllowedError]
		def action_history(start: -10, stop: nil)
			validate_session
			@rest_adapter.list_history(start: start, stop: stop)
		end
		
		# @raise [RestAdapter::Errors::OperationNotAllowedError]
		def validate_session
			fail RestAdapter::Errors::OperationNotAllowedError,
				"This session has been unlinked, initialize new session instance" if @unlinked
		end
		private :validate_session, :get_user, :get_account
	end
end
