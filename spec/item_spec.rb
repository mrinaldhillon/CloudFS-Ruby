require_relative 'spec_helper'

describe CloudFS::Item do
  before do
    session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
    session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
    @subject = session.filesystem
    @test_folder = @subject.root.create_folder(Configuration::TEST_FOLDER, exists: 'OVERWRITE')
    @folder =@test_folder.create_folder('item_test_folder', exists: 'OVERWRITE')
    @file = @folder.upload('item test', name: 'item_test_file.txt', exists: 'OVERWRITE', upload_io: true)
  end

  it 'should have an id' do
    @folder.id.wont_be_empty
    @file.id.wont_be_empty
  end

  describe 'get path' do
    it '#path' do
      @folder.path.wont_be_empty
      @file.path.wont_be_empty
    end
  end

  describe 'get type' do
    it '#path' do
      @folder.type.must_equal 'folder'
      @file.type.must_equal 'file'
    end
  end

  describe 'is mirrored' do
    it '#mirrored' do
      # @folder.is_mirrored.must_be_instance_of boolean
      # @file.is_mirrored.must_be_instance_of boolean
    end
  end

  describe 'get date content last modified' do
    it '#date content last modified' do
      @folder.date_content_last_modified.wont_be_nil
      @file.date_content_last_modified.must_be_instance_of Time
    end
  end

  describe 'get date created' do
    it '#date created' do
      @folder.date_created.wont_be_nil
      @file.date_created.must_be_instance_of Time
    end
  end

  describe 'get date meta last modified' do
    it '#date meta last modified' do
      @folder.date_meta_last_modified.wont_be_nil
      @file.date_meta_last_modified.must_be_instance_of Time
    end
  end

  describe 'get name' do
    it '#name' do
      @folder.name.must_equal 'item_test_folder'
      @file.name.must_equal 'item_test_file.txt'
    end
  end

  describe 'get application data' do
    it '#application data' do
      @folder.application_data.wont_be_nil
      @file.application_data.wont_be_nil
    end
  end

  describe 'set name' do
    it '#new name' do
      @folder.name =('item_test_folder_001')
      @folder.save

      @file.name = ('item_test_file_001')
      @file.save

      @new_folder = @subject.get_item(@folder.path)
      @new_folder.name.must_equal 'item_test_folder_001'

      @new_file = @subject.get_item(@file.path)
      @new_file.name.must_equal 'item_test_file_001'
    end

    after do
      @new_folder.delete
      @new_file.delete
    end

  end

end
