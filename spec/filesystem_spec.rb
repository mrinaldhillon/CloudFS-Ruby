require_relative 'spec_helper'

describe CloudFS::FileSystem do
 before do 
   session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
   session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
   @subject = session.filesystem 
   @test_folder = @subject.root.create_folder(Configuration::TEST_FOLDER, exists: 'OVERWRITE')
 end

 it "Should have a root" do
   @subject.root.type.must_equal 'folder'
   @subject.root.name.must_equal 'root'
 end

 describe "Listing items" do
  before do
   @list_folder = @test_folder.create_folder('list_test', exists: 'OVERWRITE')
  end

  after do
    @list_folder.delete
  end

  it "#list" do
    items = @subject.list(item: @test_folder)
    items.must_be_instance_of Array 
    items.length.must_equal 1
  end
 end


end
