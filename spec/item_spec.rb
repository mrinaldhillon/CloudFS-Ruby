require_relative 'spec_helper'

describe CloudFS::Item do
  before do
    session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
    session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
    @subject = session.filesystem
    @test_folder = @subject.root.create_folder(Configuration::TEST_FOLDER, exists: 'OVERWRITE')
    @folder = @test_folder.create_folder('item_test_folder', exists: 'OVERWRITE')
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
    it '# get application data' do
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
      @new_folder.delete(commit: true, force: true)
      @new_file.delete(commit: true)
    end

  end

  describe 'set application data' do
    it '#set application data' do
      application_data = @file.application_data
      @file.application_data = (application_data)
      status = @file.save

      status.wont_be_nil
    end
  end

  describe 'change attributes' do
    it '#change attributes' do
      folder_attributes = Hash.new
      folder_attributes[:name] = 'changed_folder_name'
      folder_result = @folder.change_attributes(** folder_attributes)
      @updated_folder = @subject.get_item(@folder.path)

      @updated_folder.name.must_equal 'changed_folder_name'
      folder_result.must_equal true

      file_attributes = Hash.new
      file_attributes[:name] = 'changed_file_name.txt'
      file_result = @file.change_attributes(** file_attributes)
      @updated_file = @subject.get_item(@file.path)

      @updated_file.name.must_equal 'changed_file_name.txt'
      file_result.must_equal true
    end
    after do
      @updated_folder.delete(commit: true, force: true)
      @updated_file.delete(commit: true)
    end
  end

  describe 'delete folder' do
    it '#delete folder' do
      file_result = @file.delete(commit: true, force: true)
      file_result.must_equal true

      folder_result = @folder.delete(commit: true, force: true)
      folder_result.must_equal true
    end
  end

  describe 'moving items' do
    before do
      @move_target = @test_folder.create_folder('move_test_target')
      @move_source = @test_folder.create_folder('move_test_source')
      @move_file_source = @folder.upload('item move test', name: 'item_move_test_file.txt', exists: 'OVERWRITE', upload_io: true)
    end

    it '#move' do
      @move_source.move(@move_target.path)
      @move_file_source.move(@move_source.path)
      @move_target.list.length.must_equal 1
      @move_source.list.length.must_equal 1
    end

    after do
      @move_target.delete(commit: true, force: true)
      @move_source.delete(commit: true)
    end
  end

  describe 'copying items' do
    before do
      @copy_target = @test_folder.create_folder('copy_test_target')
      @copy_source = @test_folder.create_folder('copy_test_source')
      @copy_folder = @copy_source.create_folder('copy_item1')
      @copy_file_source = @copy_source.upload('item copy test', name: 'item_copy_test_file.txt', exists: 'OVERWRITE', upload_io: true)

    end

    it '#copy' do
      @copy_folder.copy(@copy_target.path)
      @copy_file_source.copy(@copy_target.path)

      @copy_target.list.length.must_equal 2
      @copy_source.list.length.must_equal 2
    end

    after do
      @copy_target.delete(commit: true, force: true)
      @copy_source.delete(commit: true)
    end
  end

  describe 'restore' do
    it '#restore' do
      @delete_test = @test_folder.create_folder('delete_folder')
      @delete_folder = @delete_test.create_folder('new_folder')
      @delete_file = @delete_test.upload('item delete test', name: 'item_delete_test_file.txt', exists: 'OVERWRITE', upload_io: true)

      @delete_file.delete
      @delete_folder.delete

      @delete_folder.restore(destination: @delete_folder.path)
      @delete_file.restore(destination: @delete_file.path)

      @delete_test.list.length.must_equal 2
    end
  end

end
