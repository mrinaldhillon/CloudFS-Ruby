require_relative 'spec_helper'

describe CloudFS::FileSystem do
  before do
    session = CloudFS::Session.new(Configuration::HOST, Configuration::CLIENT_ID, Configuration::SECRET)
    session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
    @subject = session.filesystem
    @test_folder = @subject.root.create_folder(Configuration::TEST_FOLDER, exists: 'OVERWRITE')
  end

  it 'Should have a root' do
    @subject.root.type.must_equal 'folder'
    @subject.root.name.must_equal 'root'
  end

end
