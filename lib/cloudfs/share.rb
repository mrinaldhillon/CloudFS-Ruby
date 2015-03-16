require_relative 'rest_adapter'
require_relative 'filesystem_common'

module CloudFS
	# Share class is used to create and manage shares in end-user's account	
	# 
	# @author Mrinal Dhillon
	class Share
		
		# @return [String] share_key
		attr_reader :share_key

    # @return [String] name
    attr_reader :name
		
		# @return [String] type
		attr_reader :type
		
		# @return [String] url
		attr_reader :url
		
		# @return [String] short_url
		attr_reader :short_url
		
		# @return [String] size
		attr_reader :size

    # @return [String] application data
    attr_reader :application_data

		# Set the name of the share\
		# @param new_name [String] new name of the share.
		# @param password [String] current password of the share.
    def set_name(new_name, password=nil)
      FileSystemCommon.validate_share_state(self)
      response = @rest_adapter.alter_share_info(@share_key, current_password: password, name: new_name)
      set_share_info(** response)
      self
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

    #	@!attribute [r] date_content_last_modified
    #	@return [Time] modified time
    def date_content_last_modified
      if @date_content_last_modified
        Time.at(@date_content_last_modified)
      else
        nil
      end
    end

    #	@!attribute [r] date_meta_last_modified
    #	@return [Time] modified time
    def date_meta_last_modified
      if @date_meta_last_modified
        Time.at(@date_meta_last_modified)
      else
        nil
      end
    end

    # @param rest_adapter [RestAdapter] cloudfs RESTful api object
		# @param [Hash] properties metadata of share
		# @option  properties [String] :share_key
		# @option properties [String] :share_type
		# @option properties [String] :share_name
		# @option properties [String] :url
		# @option properties [String] :short_url
		# @option properties [String] :share_size
		# @option properties [Fixnum] :date_created
		def initialize(rest_adapter, **properties)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid RestAdapter, input type must be CloudFS::RestAdapter" unless rest_adapter.is_a?(CloudFS::RestAdapter)
			@rest_adapter = rest_adapter
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

      if params[:single_item]
        @application_data = params[:single_item][:application_data]
        @date_content_last_modified = params[:single_item][:date_content_last_modified]
        @date_meta_last_modified = params[:single_item][:date_meta_last_modified]
      end

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
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::InvalidShareError]
		def list
			FileSystemCommon.validate_share_state(self)
			response = @rest_adapter.browse_share(@share_key).fetch(:items)
			FileSystemCommon.create_items_from_hash_array(response, 
					@rest_adapter, in_share: true)
		end

		# Delete this share
		#	@return [true]
		# @note Subsequent operations shall fail {RestAdapter::Errors::InvalidShareError}
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::InvalidShareError]
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
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::InvalidShareError]
		def set_password(password, current_password: nil)
			FileSystemCommon.validate_share_state(self)
			response = @rest_adapter.alter_share_info(@share_key,
					current_password: current_password, password: password)
			set_share_info(**response)
			self
    end

    # Changes, adds, or removes the share’s password or updates the name.
    #
    # @param [Hash] values metadata of share.
    # @option values [String] :current_password
    # @option values [String] :password
    # @option values [String] :name
    #
    # @param password [String] current password of the share.
    #
    #	@return [Boolean] based on the success or fail status of the action.
    def change_attributes(values, password=nil)
      current_password = values.has_key?('current_password') ? values['current_password'] : password
      new_password = values.has_key?('password') ? values['password'] : nil
      name = values.has_key?('name') ? values['name'] : nil

      response = @rest_adapter.alter_share_info(
          @share_key, current_password: current_password, password: new_password, name: name)

      set_share_info(** response)
      response.has_key?(:share_key)
    end

		# Unlock this share
		# @param password	[String] password for this share
		# @return [Share] return self
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::InvalidShareError]
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
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::InvalidShareError]
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
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::InvalidShareError]
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
		# @note raises RestAdapter::Errors::ServiceError if share is locked,
		#		unlock share if password is set
		#
		#	@return [Share] returns self
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::InvalidShareError]
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
