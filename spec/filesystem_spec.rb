require_relative 'spec_helper'

describe CloudFS::FileSystem do
 before do 
   session = CloudFS::Session.new(Configuration::CLIENT_ID, Configuration::SECRET, Configuration::HOST)
   session.authenticate(Configuration::USERNAME, Configuration::PASSWORD)
   @subject = session.filesystem 
 end

 it "Should have a root" do
   @subject.root.type.must_equal 'folder'
   @subject.root.name.must_equal 'root'
 end
end
