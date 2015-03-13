require_relative 'spec_helper'

describe CloudFS::Share do
  before do
    session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
    session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
    @subject = session.filesystem
    @test_folder = @subject.root.create_folder(Configuration::TEST_FOLDER, exists: 'OVERWRITE')
    @share_folder = @test_folder.create_folder('share_test')
    @file = @share_folder.upload('share file content', name:'share_file.txt', upload_io: true)
    @share_file = @subject.create_share(@file.path)
  end

  after do
    # @share_folder.delete
  end

  # describe 'Getting Share Key' do
  #   it '#share_key' do
  #     @share_key = @share_file.share_key
  #     @share_key.wont_be_empty
  #   end
  # end
  #
  # describe 'Getting Name' do
  #   it '#name' do
  #     @share_name = @share_file.name
  #     @share_name.wont_be_empty
  #   end
  # end
  #
  # describe 'Get Size' do
  #   it '#size' do
  #     @share_size = @share_file.size
  #     @share_size.must_equal 18
  #   end
  # end

  # describe 'List Share' do
  #   it '#list' do
  #     @share_list = @share_file.list
  #     @share_list.must_be_instance_of Array
  #     @share_list.length.must_equal 1
  #     puts @share_list
  #   end
  # end

  # describe 'Receive Share File' do
  #
  #   before do
  #     @share_download_folder = @test_folder.create_folder('share_download')
  #   end
  #
  #   it '#receive' do
  #     @receive_file = @share_file.receive(path:@share_download_folder.path)
  #     @receive_file.must_be_instance_of Array
  #     @receive_file.length.must_equal 1
  #     puts @receive_file
  #   end
  #
  #   after do
  #     @share_download_folder.delete
  #   end
  # end

  # describe 'Set Share Password' do
  #   it '#set_password' do
  #     @share_file = @share_file.set_password('user@123')
  #     @share_file = @share_file.set_password('user@1234', current_password:'user@123')
  #   end
  # end

  describe 'change attributes' do

    it '#change attributes' do
      # folder_attributes = Hash.new
      # folder_attributes[:name] = 'changed_folder_name'
      # @folder.change_attributes(** folder_attributes)
      # @updated_folder = @subject.get_item(@share_folder.path)
      #
      # puts (@updated_folder.name)
      # @updated_folder.name.must_equal 'changed_folder_name'

      file_attributes = Hash.new
      file_attributes[:name] = 'changed_file_name.txt'
      @share_file.change_attributes(** file_attributes)
      @updated_file = @subject.get_item(@file.path)

      puts (@updated_file.name)
      @updated_file.name.must_equal 'changed_file_name.txt'
    end
    after do
      # @updated_folder.delete(commit: true, force: true)
      # @updated_file.delete(commit: true)
    end
  end

  describe 'Delete Share' do

    it '#delete' do
      # @status = @share_file.delete
      # @status.must_equal true
    end
  end

end