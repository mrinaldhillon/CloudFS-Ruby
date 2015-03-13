require_relative 'spec_helper'

describe CloudFS::Folder do
  before do
    session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
    session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
    @subject = session.filesystem
    @test_folder = @subject.root.create_folder(Configuration::TEST_FOLDER, exists: 'OVERWRITE')
  end

  describe 'Creating a Folder' do

    it '#create_folder' do
      @create_folder = @test_folder.create_folder('folder_test')
      @create_folder.type.must_equal 'folder'

      @create_folder_rename = @test_folder.create_folder('folder_test', exists: 'RENAME')
      @create_folder_rename.type.must_equal 'folder'
      @create_folder_rename.name.must_equal 'folder_test (1)'
    end

    after do
      @create_folder.delete
      @create_folder_rename.delete
    end
  end

  describe 'Uploading a File Via IO' do

    before do
      @create_folder = @test_folder.create_folder('folder_test')
    end

    it '#upload' do
      @file = @create_folder.upload('file test', name:'file_test.txt', upload_io: true)
      @file.type.must_equal 'file'
      @file.name.must_equal 'file_test.txt'
    end

    after do
      @create_folder.delete
    end
  end

  describe 'Uploading Local File' do

    before do
      @create_folder = @test_folder.create_folder('folder_test')
      logged_in_user = ENV['USER']
			@directory_path = '/home/' + logged_in_user + '/file_upload'
      @local_path_exist = File.directory?(@directory_path)

			if @local_path_exist == false
					Dir.mkdir(@directory_path)
      end

      @file_path = @directory_path + '/file_test.txt'
      File.open(@file_path, 'w') {|f| f.write('test content') }
    end

    it '#upload' do
      @file = @create_folder.upload(@file_path)
      @file.type.must_equal 'file'
      @file.name.must_equal 'file_test.txt'
    end

    after do
      @create_folder.delete
      File.delete(@file_path)
      Dir.delete(@directory_path)
    end
  end
end