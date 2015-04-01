require_relative 'spec_helper'

describe CloudFS::Folder do
  before do
    session = CloudFS::Session.new(Configuration::HOST, Configuration::CLIENT_ID, Configuration::SECRET)
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

  describe 'Listing the folder content, traversing ' do
    before do
      @root_folder = @test_folder.create_folder('root_folder', exists: 'OVERWRITE')
      @folder_child_01 = @root_folder.create_folder('folder_child_01', exists: 'OVERWRITE')
      @folder_child_01.upload('folder child 01 content', name: 'folder_child_01.txt', upload_io: true)
    end

    it 'Should show the child folders and files' do
      root_folder_content = @root_folder.list
      root_folder_content.length.must_equal 1
      root_folder_content.first.name.must_equal 'folder_child_01'

      child_folder_content = root_folder_content.first.list
      child_folder_content.length.must_equal 1
      child_folder_content.first.name.must_equal 'folder_child_01.txt'

      @root_folder.delete(commit: false, force: true)

      root_trash_folder = @root_folder.list
      root_trash_folder.length.must_equal 1
      root_trash_folder.first.name.must_equal 'folder_child_01'

      first_trash_child = root_trash_folder.first.list
      first_trash_child.length.must_equal 1
      first_trash_child.first.name.must_equal 'folder_child_01.txt'
    end

    after do
      @root_folder.delete(commit: true, force: true)
    end
  end

end