#!/usr/bin/env ruby
require_relative '../lib/bitcasa'
require_relative './session'
require 'tempfile'

module TestFile
	extend self
	@test_root_folder = "test_root"
	@test_root_subfolder = "test_root_sub"
	@local_file_name = "test_file"
	@recreate_folder_name = "test_recreate_folder" 
	@rescue_folder_name = "test_rescue_folder"	


	def read_operations(file)
		puts "File read operations ######################"

		new_filename = 'bitcasa_tmp_file.txt'
		tmpfile = Tempfile.new(new_filename)
		tmpfile.close

		puts "\nDownload file #{file.name} in #{::File.dirname(tmpfile.path)}"
		file.download(::File.dirname(tmpfile.path), filename: ::File.basename(tmpfile.path))

		puts "MD5 sum of downloaded file at #{tmpfile.path}"
		puts Digest::MD5.file(tmpfile.path).hexdigest
		tmpfile.unlink

		puts "\nRead file to buffer"
		buffer = file.read
		puts "\ntell: #{file.tell}"
		puts "MD5 sum of buffer" 
		puts Digest::MD5.hexdigest(buffer)
		puts "\nrewind: #{file.rewind}"
		
		puts "\nFile read stream"
		input_stream = StringIO.new
		file.read {|chunk| input_stream.write(chunk)}
		puts "MD5 sum of stream" 
		puts Digest::MD5.hexdigest(input_stream.string)
		input_stream.close
		
		puts "\ntell: #{file.tell}"
		puts "\nseek_set 50: #{file.seek(50)}"
		puts "\nread 50:"
		puts file.read(bytecount: 50)
		puts "\ntell: #{file.tell}"
		puts "\nseek_cur 50: #{file.seek(50, whence: IO::SEEK_CUR)}"
		puts "\ntell: #{file.tell}"
		puts "\nread 50:"
		puts file.read(bytecount: 50)
		puts "\ntell: #{file.tell}"
		puts "\nseek_end 50: #{file.seek(50, whence: IO::SEEK_END)}"
		puts "\nread 50:"
		puts file.read(bytecount: 50)
		puts "\ntell: #{file.tell}"

		puts "\nEND File read operations ###############"
	end

	def item_operations(parent_root, parent_folder, file)
		puts "\nFile item operations ######################"
		puts "\nCopy file #{file.name} to file_copy"
		file_copy = file.copy_to(parent_folder, name: "file_copy")
		puts "name: #{file_copy.name}"
		puts "url: #{file_copy.url}"

		puts "\nMove file #{file.name} to file_moved"
		file.move_to(parent_folder, name: "file_moved")
		puts "name: #{file.name}"
		puts "url: #{file.url}"

		puts "\n Alter meta of #{file.name}, name = file.altered, date_created = (current_time - 1000), application_data"
		file.name = "file.altered"
		file.date_created = Time.now.to_i - 1000
		file.application_data={a: "b", b: {c: "d", d: "e"}}
		puts "\nSave file changes"
		file.save
		puts "name: #{file.name}"
		puts "url: #{file.url}"
		puts "application_data: #{file.application_data}"
		
		puts "\nFile Restore Operations#####################"
		puts "\nDeleting file #{file.name} at #{file.url}"
		file.delete(raise_exception: true)
			
		puts "\nRestore file #{file.name} in trash url- #{file.url} to original path"
		file.restore(raise_exception: true)
		puts "Restored at URL: #{file.url}"
		
		puts "\nDeleting file #{file.name} at #{file.url}"
		file.delete(raise_exception: true)

		puts "\nCreate rescue path to test restore rescue ./#{@rescue_folder_name}"
		restore_at_folder = parent_root.create_folder(@rescue_folder_name, 
				exists: "OVERWRITE")

		puts "\nDeleting parent folder to test rescue path"
		parent_folder.delete(raise_exception: true, force: true)

		puts "\nRestore file #{file.name} in trash url - #{file.url} at rescue path #{restore_at_folder.url}"
		file.restore(destination: restore_at_folder, exists: "RESCUE", raise_exception: true)
		puts "Restored file URL: #{file.url}"

		puts "\nDeleting file #{file.name} at #{file.url}"
		file.delete(raise_exception: true)

		puts "\nDeleting parent folder to test recreate path"
		restore_at_folder.delete(raise_exception: true, force: true)

		puts "\nRestore file #{file.name} in trash url - #{file.url} at recreate path /#{@recreate_folder_name}"
		file.restore(destination: "/#{@recreate_folder_name}", 
				exists: "RECREATE", raise_exception: true)
			
		puts "Restored file URL: #{file.url}"
		puts "\nEnd File Restore Operations###############"

		puts "\nList versions of #{file.name}"
		items = file.versions
	 	items.each do |item|
			puts "name: #{item.name}"
			puts "url: #{item.url}"
			puts "version: #{item.version}"
		end
		begin
			items.first.move_to(parent_root)		
		rescue Bitcasa::Client::Errors::OperationNotAllowedError => error
			puts error.message
		end
		puts "End File item operations ##############################"
	end

	def operations(test_root, test_folder, do_populate_only: false)

		puts "\nCreating temporary file to upload in current folder"
		temp_file = Tempfile.new(@local_file_name)

		1000.times do 
			temp_file.write("this test file")
		end
		temp_file.flush
		temp_file.close

		puts "\nMD5 hash of temporary file"
		puts Digest::MD5.file(temp_file.path).hexdigest

		begin
			puts "\nUpload #{temp_file.path} at #{test_folder.url}"
			file = test_folder.upload(temp_file.path)
			puts "name: #{file.name}"
			puts "url: #{file.url}"
		ensure
			temp_file.unlink
		end
			
		return nil if do_populate_only
		read_operations(file)
		item_operations(test_root, test_folder, file)
	end

	def api(session)
		root = nil
		test_root = nil
		root = session.filesystem.root
		
		puts "\nCreate folder- /#{@test_root_folder}"
		test_root = root.create_folder(@test_root_folder, exists: "OVERWRITE")
		puts "\nCreate folder- /#{@test_root_subfolder}"
		test_folder = test_root.create_folder(@test_root_subfolder)

		puts "File API ##############################################################"
		operations(test_root, test_folder)
		puts "End File API #############################################################"
		ensure
			puts "\nCleanup ###########"
			if root
				root.list.each do |item|
					if item.name == @recreate_folder_name
						item.delete(force: true, commit: true) 			
						break
					end
				end
			end

			test_root.delete(commit: true, force: true) if test_root
			puts "\n END Cleanup ##########"
	end	
end

if __FILE__ == $0
	begin
		session = TestSession.setup
		TestFile.api(session)
	rescue Bitcasa::Client::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end
end
