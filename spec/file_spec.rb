require_relative 'spec_helper'

describe CloudFS::File do
	before do
		 session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
		 session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
		 @subject = session.filesystem
		 @test_folder = @subject.root.create_folder(Configuration::TEST_FOLDER, exists: 'OVERWRITE')
		 @file_folder =@test_folder.create_folder('file_test', exists: 'OVERWRITE')
		 @file = @file_folder.upload('file test', name:'file_test.txt', exists: 'OVERWRITE', upload_io: true)
	end

	it 'Should have a file' do
		@file.type.must_equal 'file'
		@file.name.must_equal 'file_test.txt'
	end

	describe 'get mime' do
		it '#mime' do
			@filetype = @file.mime
			@filetype.must_equal 'text/plain; charset=utf-8'
		end
	end

	describe 'get size' do
		it '#size' do
			@filesize = @file.size
			@filesize.must_equal 9
		end
	end

	describe 'file read' do
		it '#read' do
			@read_full_data = @file.read
			@file.rewind
			@read_partial_data = @file.read(bytecount:4)
			@read_full_data.must_equal 'file test'
			@read_partial_data.must_equal 'file'
		end
		after do
			@file.rewind
		end
	end

		describe 'file tell' do
			it '#tell' do
				@offset_before_read = @file.tell
				@file.read
				@offset_after_read = @file.tell
				@offset_before_read.must_equal 0
				@offset_after_read.must_equal 9
			end
			after do
				@file.rewind
			end
		end

		describe 'file rewind' do
			it '#rewind' do
				@offset_before_read = @file.tell
				@file.read
				@offset_after_read = @file.tell
				@file.rewind
				@offset_after_rewind = @file.tell
				@offset_before_read.must_equal 0
				@offset_after_read.must_equal 9
				@offset_after_rewind.must_equal 0
			end
			after do
				@file.rewind
			end
		end

	# describe 'file seek' do
	# 	before do
	# 		@initial_offset = @file.tell
	# 	end
	#
	# 	it '#seek' do
	# 		@offset_after_seek_0_whence = @file.seek(2,whence=0)
	# 		@offset_after_seek_1_whence = @file.seek(2,whence=1)
	# 		@offset_after_seek_2_whence	= @file.seek(2,whence=2)
	# 		@offset_after_seek_0_whence.must_equal 2
	# 		@offset_after_seek_1_whence.must_equal 4
	# 		@offset_after_seek_2_whence.must_equal 11
	# 	end
	#
	# 	after do
	# 		@file.rewind
	# 	end
	# end

	describe 'file download' do
		before do
			logged_in_user = ENV['USER']
			@file_path = '/home/' + logged_in_user + '/ruby-file-download'

			@local_path_exist = File.directory?(@file_path)

			if @local_path_exist == false
					Dir.mkdir(@file_path)
			end

			@file_exist_before_download = File.exist?(@file_path + '/file_test.txt')
		end
		it '#download' do
			@file.download(@file_path)
			@file_exist_after_download = File.exist?(@file_path + '/file_test.txt')
			@file_exist_before_download.must_equal false
			@file_exist_after_download.must_equal true

		end
	after do
		if @file_exist_after_download == true
			File.delete(@file_path + '/file_test.txt')
			Dir.delete(@file_path)
		end
	end
	end

end
