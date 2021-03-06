#!/usr/bin/env ruby
require_relative '../lib/cloudfs'
require 'securerandom'

module TestSession
	extend self
		@clientid = ''
		@secret = ''
		@host = ''
	
		@admin_clientid = ''
		@admin_secret = ''
		@admin_host = ''

		@username = ''
		@password = ''
		@http_debug = nil
	
	def setup(create_new_account: false, create_user_first_time: false, http_debug: nil)

		puts "Setup Session.."
		http_debug ||= @http_debug
		puts "\nInitializing Session"
		session = CloudFS::Session.new(@clientid, @secret, @host, 
				http_debug: http_debug)

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
		puts "Username: #{user.username}"
		puts "User created at: #{user.created_at}"
		puts "User last login time: #{user.last_login}"
	end

	def get_account(session)
		puts "\nGet Account.."
		account = session.account
		puts "Account id: #{account.id}"
		puts "Usage: #{account.usage}"
		puts "Limit: #{account.limit}"
		puts "Plan: #{account.plan}"
	end

	def get_history(session)
		puts "\n Action history"
		history_actions = session.action_history
	end

	def create_account(session, username, password)
		puts "\nCreate Account"
		account = session.create_account(username, password, email: "bc@izeltech.com", 
				first_name: "izel", last_name: "tech")
		puts "\nUsage: #{account.usage}"
		puts "Limit: #{account.limit}"
		puts "Plan: #{account.plan}"
		account
	end

	def sessionapi(http_debug: nil)
		@http_debug = http_debug
		session = setup(create_user_first_time: false, 
				create_new_account: false, http_debug: http_debug)
		get_user(session)
		get_account(session)
		get_history(session)
		session
	end

end

if __FILE__ == $0
	begin
		TestSession.sessionapi(http_debug: nil)
	rescue CloudFS::Client::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end

end
