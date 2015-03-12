require_relative 'rest_adapter'
require_relative 'filesystem_common'

module CloudFS
	# Share class is used to create and manage shares in end-user's account	
	# 
	# @author Mrinal Dhillon
	class Share
		
		# @return [String] share_key
		attr_reader :share_key
		
		# @return [String] type
		attr_reader :type
		
		# @return [String] url
		attr_reader :url
		
		# @return [String] short_url
		attr_reader :short_url
		
		# @return [String] size
		attr_reader :size
		
		#	@!attribute [rw] name
		# name of share	
		# @overload name
		# 	@return [String] name of share
		# @overload name=(value)
		# 	@param value [String]
		# 	@raise [Client::Errors::InvalidShareError]
		def name=(value)
			FileSystemCommon.validate_share_state(self)
			@name = value
			@changed_properties[:name] = value
		end

		def name
			@name
		end

		#	@!attribute [r] date_created
		#	@return [Time] creation time
		def date_created
			if @date_created
				Time.at(@date_created)
			else
				nil
			end
		end

    # @param client [RestAdapter] cloudfs RESTful api object
		# @param [Hash] properties metadata of share
		# @option  properties [String] :share_key
		# @option properties [String] :share_type
		# @option properties [String] :share_name
		# @option properties [String] :url
		# @option properties [String] :short_url
		# @option properties [String] :share_size
		# @option properties [Fixnum] :date_created
		def initialize(client, **properties)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid client, input type must be CloudFS::Client" unless client.is_a?(CloudFS::RestAdapter)
			@rest_adapter = client
			set_share_info(**properties)
		end

		# @see #initialize
		def set_share_info(**params)
			@share_key = params.fetch(:share_key) { fail RestAdapter::Errors::ArgumentError,
				"missing parameter, share_key must be defined" }
			@type = params[:share_type]
			@name = params[:share_name]
			@url = params[:url]
			@short_url = params[:short_url]
			@size = params[:share_size]
			@date_created = params[:date_created]
			@exists = true
			changed_properties_reset
		end

		# Reset changed properties
		def changed_properties_reset
			@changed_properties = {}
		end
	
		#	@return [Boolean] whether the share exists, 
		#		false only if it has been deleted
		def exists?
			@exists
		end

		
		# List items in this share
		# @return [Array<File, Folder>] list of items
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def list
			FileSystemCommon.validate_share_state(self)
			response = @rest_adapter.browse_share(@share_key).fetch(:items)
			FileSystemCommon.create_items_from_hash_array(response, 
					@rest_adapter, in_share: true)
		end

		# Delete this share
		#	@return [true]
		# @note Subsequent operations shall fail {Client::Errors::InvalidShareError}
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def delete
			FileSystemCommon.validate_share_state(self)
			@rest_adapter.delete_share(@share_key)
			@exists = false
			true
		end
	
		# Change password of this share
		#
		# @param password	[String] new password for this share
		# @param current_password [String] is required if password is already set for this share
		# @return [Share] return self
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def set_password(password, current_password: nil)
			FileSystemCommon.validate_share_state(self)
			response = @rest_adapter.alter_share_info(@share_key,
					current_password: current_password, password: password)
			set_share_info(**response)
			self
		end

		# Unlock this share
		# @param password	[String] password for this share
		# @return [Share] return self
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def unlock(password)
			FileSystemCommon.validate_share_state(self)
			@rest_adapter.unlock_share(@share_key, password)
			self
		end


		# Save this share's current state.
		#		Only name, is commited to this share in user's account
		# @param password [String] current password for this share,
		#		if has been set, it is necessary even if share has been unlocked
		# @return [Share] returns self
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def save(password: nil)
			FileSystemCommon.validate_share_state(self)
			if @changed_properties[:name]
				response = @rest_adapter.alter_share_info(@share_key,
					current_password: password, name: @changed_properties[:name])
				set_share_info(**response)
			end
			self
		end

		# Receive contents of this share at specified path in user's filesystem.
		#		All items found in share are copied to given location.
		#
		# @param path [String] path in user's account to receive share at, default is "/" root
		# @param exists [String] ('RENAME', 'FAIL', 'OVERWRITE') action to take in 
		#		case of conflict with existing items at path
		#
		# @return [Array<File, Folder>] items
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def receive(path: nil, exists: 'RENAME')
			FileSystemCommon.validate_share_state(self)
			response = @rest_adapter.receive_share(@share_key,
					path: path, exists: exists)
			FileSystemCommon.create_items_from_hash_array(response, 
					@rest_adapter, parent: path)
		end

		# Refresh this share to latest state
		#	@note Locally changed properties i.e. name get discarded
		#
		# @note raises Client::Errors::ServiceError if share is locked, 
		#		unlock share if password is set
		#
		#	@return [Share] returns self
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidShareError]
		def refresh
			FileSystemCommon.validate_share_state(self)
			response = @rest_adapter.browse_share(share_key).fetch(:share)
			set_share_info(**response)
			self
		end
		
		#	@return [String]
		#	@!visibility private
		def to_s
			"#{self.class}: name: #{@name}, size: #{@size}bytes"
		end

		alias inspect to_s

		private :set_share_info, :changed_properties_reset
	end	
end
