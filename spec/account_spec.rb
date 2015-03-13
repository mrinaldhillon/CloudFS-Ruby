require_relative 'spec_helper'

describe CloudFS::Account do
	before do
		 session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
		 session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
		 @account_object = session.account
	end

	describe 'Get Account Id' do
		it '#getid' do
			@account_id = @account_object.id
			@account_id.must_be_instance_of String
			@account_id.length.must_equal 36
		end
	end

	describe 'Get Storage Usage' do
		it '#getstorageusage' do
			@storage_usage = @account_object.storage_usage
			@storage_usage.wont_be_nil
			@storage_usage.must_be_instance_of Fixnum
		end
	end

	describe 'Get storage limit' do
		it '#getstoragelimit' do
			@storage_limit = @account_object.storage_limit
			@storage_limit.wont_be_nil
			@storage_limit.must_be_instance_of Fixnum
		end
	end


	describe 'Get over storage limit' do
		it '#getoverstoragelimit' do
			@over_storage_limit = @account_object.over_storage_limit
			@over_storage_limit.wont_be_nil
			@over_storage_limit.must_equal false
		end
	end

	describe 'Get state id' do
		it '#getstateid' do
			@state_id = @account_object.state_id
			@state_id.wont_be_nil
			@state_id.must_be_instance_of String
			@state_id.length.must_equal 5
		end
	end

	describe 'Get state display name' do
		it '#getstatedisplayname' do
			@state_display_name = @account_object.state_display_name
			@state_display_name.wont_be_nil
			@state_display_name.must_be_instance_of String
		end
	end

	describe 'Get plan display name' do
		it '#getplandisplayname' do
			@plan_display_name = @account_object.plan_display_name
			@plan_display_name.wont_be_nil
			@plan_display_name.must_be_instance_of String
		end
	end

	describe 'Get plan id' do
		it '#getplanid' do
			@plan_id = @account_object.plan_id
			@plan_id.wont_be_nil
			@plan_id.must_be_instance_of String
		end
	end

	describe 'Get session locale' do
		it '#getsessionlocale' do
			@session_locale = @account_object.session_locale
			@session_locale.wont_be_nil
			@session_locale.must_be_instance_of String
		end
	end

	describe 'Get account locale' do
		it '#getaccountlocale' do
			@account_locale = @account_object.account_locale
			@account_locale.wont_be_nil
			@account_locale.must_be_instance_of String
		end
	end


end
