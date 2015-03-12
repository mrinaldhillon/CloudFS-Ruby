require_relative 'spec_helper'

describe CloudFS::FileSystem do
 before do 
   session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
   session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
   @subject = session.filesystem 
   @test_folder = @subject.root.create_folder(Configuration::TEST_FOLDER, exists: 'OVERWRITE')
 end

 it 'Should have a root' do
   @subject.root.type.must_equal 'folder'
   @subject.root.name.must_equal 'root'
 end

 describe 'Listing items' do
  before do
   @list_folder = @test_folder.create_folder('list_test')
  end

  after do
    @list_folder.delete
  end

  it '#list' do
    items = @subject.list(item: @test_folder)
    items.must_be_instance_of Array 
    items.length.must_equal 1
  end
 end

 describe 'Moving items' do
   before do
     @move_target = @test_folder.create_folder('move_test_target')
     @move_source = @test_folder.create_folder('move_test_source')
     @move_item1 = @move_source.create_folder('move_item1')
     @move_item2 = @move_source.create_folder('move_item2')
   end
   
   after do
     @move_target.delete
     @move_source.delete
   end

   it '#move' do
     @subject.move([@move_item1, @move_item2], @move_target)
     @move_source.list.length.must_equal 0
     @move_target.list.length.must_equal 2
   end
 end 

 describe 'Copying items' do
   before do
     @copy_target = @test_folder.create_folder('copy_test_target')
     @copy_source = @test_folder.create_folder('copy_test_source')
     @copy_item1 = @copy_source.create_folder('copy_item1')
     @copy_item2 = @copy_source.create_folder('copy_item2')
   end
   
   after do
     @copy_target.delete
     @copy_source.delete
   end

   it '#copy' do
     @subject.copy([@copy_item1, @copy_item2], @copy_target)
     @copy_source.list.length.must_equal 2
     @copy_target.list.length.must_equal 2
   end
 end 

 describe 'Delete items' do
   before do
     @delete_folder = @test_folder.create_folder('delete_test_source')
     @delete_item = @delete_folder.create_folder('delete_item')
   end

   after do
     @delete_folder.delete
   end

   it '#delete' do
     @delete_item.delete
     @delete_folder.list.length.must_equal 0
   end
 end

end
