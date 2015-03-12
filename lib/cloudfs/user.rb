require_relative 'rest_adapter'

module CloudFS
	# User class maintains user profile information
	#
	# @author Mrinal Dhillon
	class User
		
		#	@!attribute [r] id
		# @return [String] internal id of user
		def id
			@properties[:id]
		end

		#	@!attribute [r] username
		# @return [String] end-user's username
		def username
			@properties[:username]
		end

		#	@!attribute [r]	first_name
		# @return [String] first name of user
		def first_name
			@properties[:first_name]
		end

		#	@!attribute [r] last_name
		# @return [String] last name of user
		def last_name
			@properties[:last_name]
		end

		#	@!attribute [r]	email
		# @return [String] email id of user
		def email
			@properties[:email]
		end

		#	@!attribute [r] created_at
		# @return [Time] account creation time
		def created_at
			if @properties[:created_at]
				Time.at(@properties[:created_at]/1000.0)
			else
				nil
			end
		end

		#	@!attribute [r] last_login
		# @return [Time] last login time
		def last_login
			if @properties[:last_login]
				Time.at(@properties[:last_login]/1000.0)
			else
				nil
			end
		end

    # @param client [RestAdapter] cloudfs RESTful api object
		# @param [Hash] properties metadata of user
		# @option properties [String] :username
		# @option properties [Fixnum] :created_at in milliseconds since epoch
		# @option properties [String] :first_name
		# @option properties [String] :last_name
		# @option properties [String] :email
		# @option properties [Fixnum] :last_login in milliseconds since epoch
		# @option properties [String] :id
		def initialize(client, **properties)
			fail RestAdapter::Errors::ArgumentError,
				"invalid client type #{client.class}, expected CloudFS::Client" unless client.is_a?(CloudFS::RestAdapter)

			@rest_adapter = client
			set_user_info(**properties)
		end

		# @see #initialize
		# @review required parameters
		def set_user_info(**properties)
			properties.fetch(:username) { fail RestAdapter::Errors::ArgumentError,
				"Missing required username" }
			properties.fetch(:id) { fail RestAdapter::Errors::ArgumentError,
				"Missing required id" }
			@properties = properties
		end

		# Refresh this user's metadata from server
		#	@return [User] returns self
		def refresh
			response = @rest_adapter.get_profile
			set_user_info(**response)
			self
		end

		#	@return [String]
		#	@!visibility private
		def to_s
			str = "#{self.class}: username: #{@properties[:username]}"
			str <<  ", first name: #{@properties[:first_name]}" unless RestAdapter::Utils.is_blank?(@properties[:first_name])
			str <<  ", last name: #{@properties[:last_name]}" unless RestAdapter::Utils.is_blank?(@properties[:last_name])
			str <<  ", email: #{@properties[:email]}" unless RestAdapter::Utils.is_blank?(@properties[:email])
			str
		end

		alias inspect to_s
		private :set_user_info
	end
end
