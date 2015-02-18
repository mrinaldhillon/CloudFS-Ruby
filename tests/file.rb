#!/usr/bin/env ruby
require_relative '../lib/cloudfs'
require_relative './session'
require 'tempfile'

module TestFile
	extend self
	@test_root_folder = "test_root"
	@test_root_subfolder = "test_root_sub"
	@local_file_name = "test_file"
	@recreate_folder_name = "test_recreate_folder" 
	@rescue_folder_name = "test_rescue_folder"	
	@debug = false

	def debug(string)
		puts string if @debug == true
	end

	def read_operations(file)
		puts "File read operations ######################"

		new_filename = 'cloudfs_tmp_file.txt'
		tmpfile = Tempfile.new(new_filename)
		tmpfile.close

		debug "\nDownload file #{file.name} in #{::File.dirname(tmpfile.path)}"
		file.download(::File.dirname(tmpfile.path), filename: ::File.basename(tmpfile.path))

		debug "MD5 sum of downloaded file at #{tmpfile.path}"
		debug Digest::MD5.file(tmpfile.path).hexdigest
		tmpfile.unlink

		debug "\nRead file to buffer"
		buffer = file.read
		debug "\ntell: #{file.tell}"
		debug "MD5 sum of buffer" 
		debug Digest::MD5.hexdigest(buffer)
		debug "\nrewind: #{file.rewind}"
		
		debug "\nFile read stream"
		input_stream = StringIO.new
		file.read {|chunk| input_stream.write(chunk)}
		debug "MD5 sum of stream" 
		debug Digest::MD5.hexdigest(input_stream.string)
		input_stream.close
		
		debug "\ntell: #{file.tell}"
		debug "\nseek_set 50: #{file.seek(50)}"
		debug "\nread 50:"
		debug file.read(bytecount: 50)
		debug "\ntell: #{file.tell}"
		debug "\nseek_cur 50: #{file.seek(50, whence: IO::SEEK_CUR)}"
		debug "\ntell: #{file.tell}"
		debug "\nread 50:"
		debug file.read(bytecount: 50)
		debug "\ntell: #{file.tell}"
		debug "\nseek_end 50: #{file.seek(50, whence: IO::SEEK_END)}"
		debug "\nread 50:"
		debug file.read(bytecount: 50)
		debug "\ntell: #{file.tell}"

		puts "\nEND File read operations ###############"
	end

	def item_operations(parent_root, parent_folder, file)
		puts "\nFile item operations ######################"
		debug "\nCopy file #{file.name} to file_copy"
		file_copy = file.copy_to(parent_folder, name: "file_copy")
		debug "name: #{file_copy.name}"
		debug "url: #{file_copy.url}"

		debug "\nMove file #{file.name} to file_moved"
		file.move_to(parent_folder, name: "file_moved")
		debug "name: #{file.name}"
		debug "url: #{file.url}"

		debug "\n Alter meta of #{file.name}, name = file.altered, date_created = (current_time - 1000), application_data"
		file.name = "file.altered"
		file.date_created = Time.at(Time.now.to_i - 1000)
		file.application_data={a: "b", b: {c: "d", d: "e"}}
		debug "\nSave file changes"
		file.save
		debug "name: #{file.name}"
		debug "url: #{file.url}"
		debug "application_data: #{file.application_data}"
		
		puts "\nFile Restore Operations#####################"
		debug "\nDeleting file #{file.name} at #{file.url}"
		file.delete(raise_exception: true)
			
		debug "\nRestore file #{file.name} in trash url- #{file.url} to original path"
		file.restore(raise_exception: true)
		debug "Restored at URL: #{file.url}"
		
		debug "\nDeleting file #{file.name} at #{file.url}"
		file.delete(raise_exception: true)

		debug "\nCreate rescue path to test restore rescue ./#{@rescue_folder_name}"
		restore_at_folder = parent_root.create_folder(@rescue_folder_name, 
				exists: "OVERWRITE")

		debug "\nDeleting parent folder to test rescue path"
		parent_folder.delete(raise_exception: true, force: true)

		debug "\nRestore file #{file.name} in trash url - #{file.url} at rescue path #{restore_at_folder.url}"
		file.restore(destination: restore_at_folder, exists: "RESCUE", raise_exception: true)
		debug "Restored file URL: #{file.url}"

		debug "\nDeleting file #{file.name} at #{file.url}"
		file.delete(raise_exception: true)

		debug "\nDeleting parent folder to test recreate path"
		restore_at_folder.delete(raise_exception: true, force: true)

		debug "\nRestore file #{file.name} in trash url - #{file.url} at recreate path /#{@recreate_folder_name}"
		file.restore(destination: "/#{@recreate_folder_name}", 
				exists: "RECREATE", raise_exception: true)
			
		debug "Restored file URL: #{file.url}"
		puts "\nEnd File Restore Operations###############"

		debug "\nList versions of #{file.name}"
		items = file.versions
	 	items.each do |item|
			debug "name: #{item.name}"
			debug "url: #{item.url}"
			debug "version: #{item.version}"
		end
		begin
			items.first.move_to(parent_root)		
		rescue CloudFS::Client::Errors::OperationNotAllowedError => error
			debug error.message
		end
		puts "End File item operations ##############################"
	end

	def operations(test_root, test_folder, do_populate_only: false)

		debug "\nCreating temporary file to upload in current folder"
		temp_file = Tempfile.new(@local_file_name)

		1000.times do 
			temp_file.write("this test file")
		end
		temp_file.flush
		temp_file.close

		debug "\nMD5 hash of temporary file"
		debug Digest::MD5.file(temp_file.path).hexdigest

		begin
			debug "\nUpload #{temp_file.path} at #{test_folder.url}"
			file = test_folder.upload(temp_file.path)
			debug "name: #{file.name}"
			debug "url: #{file.url}"
		ensure
			temp_file.unlink
		end
		return nil if do_populate_only
		read_operations(file)
		item_operations(test_root, test_folder, file)
	end

	def api(session, test_debug: false)
		@debug = test_debug
		root = nil
		test_root = nil
		root = session.filesystem.root
		
		debug "\nCreate folder- /#{@test_root_folder}"
		test_root = root.create_folder(@test_root_folder, exists: "OVERWRITE")
		debug "\nCreate folder- /#{@test_root_subfolder}"
		test_folder = test_root.create_folder(@test_root_subfolder)

		puts "File API ##############################################################"
		operations(test_root, test_folder, do_populate_only: false)
		puts "End File API #############################################################"
		puts "Passed File API"
		ensure
			debug "\nCleanup ###########"
			test_root.delete(commit: true, force: true) if test_root
			if root
				root.list.each do |item|
					if item.name == @recreate_folder_name
						item.delete(force: true, commit: true) 			
						break
					end
				end
			end

			debug "\n END Cleanup ##########"
	end	
end

if __FILE__ == $0
	begin
		session = TestSession.setup
		TestFile.api(session, test_debug: false)
	rescue CloudFS::Client::Errors::Error => error
		debug error
		debug error.class
		debug error.code if error.respond_to?(:code)
		debug error.request if error.respond_to?(:request)
		debug error.response if error.respond_to?(:response)
		debug error.backtrace if error.respond_to?(:backtrace)
	end
end
