require_relative 'spec_helper'

describe CloudFS::User do
	before do
		 session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
		 session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
		 @logged_in_user = session.user
	end

	it '#init' do
		@logged_in_user.username.wont_be_nil
		@logged_in_user.username.must_be_instance_of String
	end

	describe 'Get User Id' do
		it '#getid' do
			@logged_in_user_id = @logged_in_user.id
			@logged_in_user_id.must_be_instance_of String
		end
	end

	describe 'Get Username' do
		it '#getusername' do
			@logged_in_user_username = @logged_in_user.username
			@logged_in_user_username.must_be_instance_of String
			@logged_in_user_username.must_equal Configuration::USERNAME
		end
	end

	describe 'Get FirstName' do
		it '#getfirstname' do
			@logged_in_user_fname = @logged_in_user.first_name
			@logged_in_user_fname.must_be_instance_of String
			puts(@logged_in_user_fname)

		end
	end

	describe 'Get LastName' do
		it '#getlirstname' do
			@logged_in_user_last_name = @logged_in_user.last_name
			@logged_in_user_last_name.must_be_instance_of String

		end
	end

	describe 'Get Email' do
		it '#getemail' do
			@logged_in_user_email = @logged_in_user.email
			@logged_in_user_email.must_be_instance_of String
		end
	end

	describe 'Get Created At' do
		it '#getcreatedat' do
			@logged_in_user_created_at = @logged_in_user.created_at
			@logged_in_user_created_at.wont_be_nil
			@logged_in_user_created_at.must_be_instance_of Time
		end
	end

	describe 'Get Last login' do
		it '#getlastlogin' do
			@logged_in_user_last_login = @logged_in_user.last_login
			@logged_in_user_last_login.wont_be_nil
			@logged_in_user_last_login.must_be_instance_of Time
		end
	end

end
