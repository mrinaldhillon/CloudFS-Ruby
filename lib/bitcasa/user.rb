require_relative 'client'

module Bitcasa
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

		# @param client [Client] bitcasa restful api object
		# @param [Hash] properties metadata of user
		# @option properties [String] :username
		# @option properties [Fixnum] :created_at in milliseconds since epoch
		# @option properties [String] :first_name
		# @option properties [String] :last_name
		# @option properties [String] :email
		# @option properties [Fixnum] :last_login in milliseconds since epoch
		# @option properties [String] :id
		def initialize(client, **properties)
			fail Client::Errors::ArgumentError, 
				"invalid client type #{client.class}, expected Bitcasa::Client" unless client.is_a?(Bitcasa::Client)

			@client = client
			set_user_info(**properties)
		end

		# @see #initialize
		# @review required parameters
		def set_user_info(**properties)
			properties.fetch(:username) { fail Client::Errors::ArgumentError, 
				"Missing required username" }
			properties.fetch(:id) { fail Client::Errors::ArgumentError, 
				"Missing required id" }
			@properties = properties
			nil
		end

		# Refresh this user's metadata from server
		def refresh
			response = @client.get_profile
			set_user_info(**response)
		end

		private :set_user_info
	end
end
