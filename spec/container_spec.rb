require_relative 'spec_helper'

describe CloudFS::Container do
	before do
		 session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
		 session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
		 @subject = session.filesystem
		 @test_folder = @subject.root.create_folder(Configuration::TEST_FOLDER, exists: 'OVERWRITE')
	end

	describe 'Container Initialize' do
		before do
			@new_container = @test_folder.create_folder('container_test', exists: 'OVERWRITE')
		end
		it '#intialize' do
			@new_container.type.must_equal 'folder'
			@new_container.name.must_equal 'container_test'
		end
		after do
			@new_container.delete
		end
	end

	describe 'List Container' do
		before do
			@new_container = @test_folder.create_folder('container_test', exists: 'OVERWRITE')
		end
		it '#list' do
			items = @subject.list(item: @new_container)
			items.must_be_instance_of Array
			items.length.must_equal 0
		end
		after do
			@new_container.delete
		end
	end

end
