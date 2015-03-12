




def test_item_api
	session = setup_session
	fs = session.filesystem
	test_folder_root = folder_setup(fs, "testfile_root")	
	test_folder = test_folder_root.create_folder("testfile_folder")

	puts "File API ##############################################################"
	file_api(test_folder_root, test_folder)
	puts "End File API #############################################################"
	ensure
		if test_folder
			puts "Cleanup.."
			test_folder_root.delete(commit: true, force: true)
		end
		if fs	
			fs.list.each { |item| item.delete(commit: true, force: true) }
		end
end	

if __FILE__ == $0
	begin
		test_item_api
	rescue CloudFS::RestAdapter::Errors::Error
		puts $!
		puts $!.backtrace if $!.respond_to?(:backtrace)
	end
end
