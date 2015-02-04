#!/usr/bin/env ruby
require_relative '../lib/bitcasa'
require 'securerandom'

module TestSession
	extend self
		
		@clientid = "zI7kQzt_L0TepyL2u0_NaENE96t1C8R8d42aLzKOR9U"
		@secret = "KEf7pKSypEztTZ8By-rTNlyaaR_6VAVRQ7zDk1qV5XoB4o3CLygUbfCXJc8mnlvZg5KNUAfO4qLgMFFSMo51GA"
		@host = "https://tjzvgtd91s.cloudfs.io"
	
		@admin_clientid = "37X7LQaHvXv-4mAubAWElw_pnPq-q29jsuR5H_XEr30"
		@admin_secret = "kZkp7PQahsMhdTVbNA0IPr413kQ2dobAzNazJMZHE_HM8aNWN47EFa-pNJlhkOeNVsuUmGlxRcTva-PzusEqTQ"
		@admin_host = "access.bitcasa.com"

		@username = "mrinal.dhillon@izeltech.com"
		@password = "Pa55w0rd"

	def setup(create_new_account: false, create_user_first_time: false)

		puts "Setup Session.."

		puts "\nInitializing Session"
		session = Bitcasa::Session.new(@clientid, @secret, @host)

		puts "\nSetting Admin credentials"
		session.admin_credentials={clientid: @admin_clientid, secret: @admin_secret}
		puts "\nAdmin credentials: #{session.admin_credentials}" 

		if create_new_account
			if create_user_first_time
				user = @username
			else
				user = SecureRandom.uuid
			end

			account = create_account(session, user, @password) 
			@username = account.username
		end
		puts "\nCheck is linked.."
		puts session.is_linked?

			puts "\nAuthenticating.."
		session.authenticate(@username, @password)
		session
	end

	def get_user(session)
		puts "\nGet User.."
		user = session.user
		puts "Userid: #{user.id}"
	end

	def get_account(session)
		puts "\nGet Account.."
		account = session.account
		puts "Account id: #{account.id}"
	end

	def get_history(session)
		puts "\n Action history"
		history_actions = session.action_history
		history_actions.each do |action|
			puts
			puts action[:action]
			puts action[:version]
			puts action[:data]
		end
	end

	def create_account(session, username, password)
		puts "\nCreate Account"
		account = session.create_account(username, password, email: "bc@izeltech.com", 
				first_name: "izel", last_name: "tech")
		puts "\nUsage: #{account.get_usage}"
		puts "Quota: #{account.get_quota}"
		puts "Plan: #{account.get_plan}"
		puts "Username: #{account.username}"
		account
	end

	def sessionapi
		session = setup(create_user_first_time: false, 
				create_new_account: false)
		get_user(session)
		get_account(session)
		get_history(session)
		session
	end

end

if __FILE__ == $0
	begin
		TestSession.sessionapi
	rescue Bitcasa::Client::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end

end
