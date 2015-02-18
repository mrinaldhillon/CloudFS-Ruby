require_relative 'user'
module CloudFS

	# Account class defines properties of the end-user's CloudFS paid account
	#
	# @author Mrinal Dhillon
	class Account
				
		#	@!attribute [r] id
		# @return [String] id of this user's account
		def id
			@properties[:id]
		end
		
		#	@!attribute [r] usage
		#	@return [Fixnum] current storage usage of account in bytes
		def usage
			@properties[:storage][:usage]
		end

		#	@!attribute [r] limit
		#	@return [Fixnum] storage limit of account in bytes
		def limit
			@properties[:storage][:limit]
		end

		#	@!attribute [r] over_storage_limit
		#	@return [Boolean] whether user is currently over its storage quota
		def over_storage_limit
			@properties[:storage][:otl]
		end

		#	@!attribute [r]	state_id
		#	@return [String] id of current account state
		def state_id
			@properties[:account_state][:id]
		end

		#	@!attribute [r] plan
		#	@return [String] Human readable name of account's CloudFS plan
		def plan
			@properties[:account_plan][:display_name]
		end

		#	@!attribute [r] plan_id
		#	@return [String] id of CloudFS plan
		def plan_id
			@properties[:account_plan][:id]
		end

		#	@!attribute [r] session_locale
		#	@return [String] locale of current session
		def session_locale
			@properties[:session][:locale]
		end

		#	@!attribute [r] locale
		#	@return [String] locale of the entire account
		def locale
			@properties[:locale]
		end

		# @param client [Client] cloudfs RESTful api object
		# @param [Hash] properties metadata of account
		def initialize(client, **properties)
			fail Client::Errors::ArgumentError, 
				"invalid client type #{client.class}, expected CloudFS::Client" unless client.is_a?(CloudFS::Client)

			@client = client
			set_account_info(**properties)
		end

		# @see #initialize
		# @review required parameters
		def set_account_info(**properties)
			@properties = properties
		end

		# Refresh this user's account metadata from server
		#	@return [Account] returns self
		def refresh
			response = @client.get_profile
			set_account_info(**response)
			self
		end

		private :set_account_info
	end
end
