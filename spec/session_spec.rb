require_relative 'spec_helper'

describe CloudFS::Session do
	before do
		@session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
	end

	it 'initializing session' do
		@session.wont_be_nil
	end

	describe 'authenticating session' do
		before do
			@auth_status = @session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
		end
		it '#authenticatesession' do
			@auth_status.wont_be_nil
			@auth_status.must_equal true
		end
	end

	describe 'get user' do
		before do
			@auth_status = @session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
		end
		it '#getuser' do
			@authenticated_user = @session.user
			@authenticated_user_name = @authenticated_user.username
			@authenticated_user.wont_be_nil
			@authenticated_user_name.must_equal Configuration::USERNAME
		end
	end

	describe 'get filesystem' do
		before do
			@auth_status = @session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
		end
		it '#getfilesystem' do
			@file_system = @session.filesystem
			@root_name = @file_system.root.name
			@file_system.wont_be_nil
			@root_name.must_equal 'root'
		end
	end

	describe 'get account' do
		before do
			@auth_status = @session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
		end
		it '#getaccount' do
			@account_object = @session.account
			@account_id = @account_object.id
			@account_object.wont_be_nil
			@account_id.must_be_instance_of String
			@account_id.length.must_equal 36
		end
	end

	describe 'is linked' do
			before do
				@auth_status = @session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
			end
			it '#islinked' do
				@is_linked = @session.is_linked?
				@is_linked.must_equal true
			end
	end

	describe 'unlink session' do
		before do
			@auth_status = @session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
		end
		it '#unlink' do
			@unlink_status = @session.unlink
			@unlink_status.must_equal true
		end
	end

	describe 'action history' do
		before do
			@auth_status = @session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
		end
		it '#actionhistory' do
			@action_history = @session.action_history
			@action_history.wont_be_nil
			@action_history.must_be_instance_of Array
		end
	end

	#Test not working Due to Server Error
	# describe 'create account' do
	# 	it '#createaccount' do
	#
	# 		@session.admin_credentials(Configuration::CLIENT_ID, Configuration::SECRET)
	# 		@created_account = @session.create_account('test@gmail.com','user@123', email:'test@gmail.com',
	# 																							 first_name:'test', last_name:'lastname')
	# 	end
	#
	# end

end
