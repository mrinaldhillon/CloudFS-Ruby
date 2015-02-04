#!/usr/bin/env ruby
require_relative '../lib/bitcasa'
require_relative './session'
require_relative './file'

module TestFolder
	extend self
	@test_root_folder = "test_root"
	@test_root_subfolder = "test_root_sub"
	@recreate_folder_name = "test_recreate_folder" 
	@rescue_folder_name = "test_rescue_folder"	


	def operations(parent_root, parent_folder, do_populate_only: false)
		puts "\nCreate Folder a1"
		a1 = parent_folder.create_folder("a1")
		puts "name: #{a1.name}"
		puts "absolute path: #{a1.url}"

		puts "\nCreate Folder a1/b2"
		b2 = a1.create_folder("b2")
		puts "name: #{b2.name}"
		puts "absolute path: #{b2.url}"

		puts "\nCreate Folder c1"
		c1 = parent_folder.create_folder("c1")
		puts "name: #{c1.name}"
		puts "absolute path: #{c1.url}"

		puts "\nCopy Folder a1/b2 to d1"
		d1 = b2.copy_to(parent_folder, name: "d1")
		puts "name: #{d1.name}"
		puts "absolute path: #{d1.url}"

		puts "\nMove Folder d1 to c1/d2"
		d2 = d1.move_to(c1, name: "d2")
		puts "name: #{d2.name}"
		puts "absolute path: #{d2.url}"

		puts "\n Alter meta of d2, name = d2.new, date_created = (current_time - 1000), application_data"
		d2.name = "d2.new"
		d2.date_created = Time.now.to_i - 1000
		d2.application_data={a: "b", b: {c: "d", d: "e"}}
		d2.save
		puts "Fetching changed properties of d2.."
		puts "name: #{d2.name}"
		puts "absolute path: #{d2.url}"
		
		return if do_populate_only
		puts "\nList Folder recursively #{parent_folder}"
		recursive_list(parent_folder)

		puts "\nFolder Restore Operations#####################"
		puts "\nDeleting folder #{d2.name} at #{d2.url}"
		d2.delete(raise_exception: true, force: true)
			
		puts "\nRestore folder #{d2.name} in trash url- #{d2.url} to original path"
		d2.restore(raise_exception: true)
		puts "Restored folder URL: #{d2.url}"
		
		puts "\nDeleting folder #{d2.name} at #{d2.url}"
		d2.delete(raise_exception: true, force: true)

		puts "\nDeleting parent folder to test rescue path"
		parent_folder.delete(raise_exception: true, force: true)

		puts "\nCreate rescue path to test restore rescue ./#{@rescue_folder_name}"
		restore_at_folder = parent_root.create_folder(@rescue_folder_name, 
				exists: "OVERWRITE")
		
		puts "\nRestore folder #{d2.name} in trash url - #{d2.url} at rescue path #{restore_at_folder.url}"
		d2.restore(destination: restore_at_folder, exists: "RESCUE", raise_exception: true)
		puts "Restored folder URL: #{d2.url}"

		puts "\nDeleting folder #{d2.name} at #{d2.url}"
		d2.delete(raise_exception: true, force: true)

		puts "\nDeleting parent folder to test recreate path"
		restore_at_folder.delete(raise_exception: true, force: true)

		puts "\nRestore folder #{d2.name} in trash url - #{d2.url} at recreate path /#{@recreate_folder_name}"
		d2.restore(destination: "/#{@recreate_folder_name}", 
				exists: "RECREATE", raise_exception: true)
			
		puts "Restored folder URL: #{d2.url}"
		puts "\nEnd File Restore Operations###############"
	end

	def recursive_list(folder, &block)
		folder.list.each do |i|
			puts "name: #{i.name}"
			puts "absolute path: #{i.url}"
			puts "class: #{i.class}"	
			yield i if block

			if i.is_a?(Bitcasa::Folder)
				puts "List Recursive Folder #{i.name}"
				recursive_list(i, &block)
			end
		end
	end


	def api(session)
		root = nil
		test_root = nil
		root = session.filesystem.root
		
		puts "\nCreate folder- /#{@test_root_folder}"
		test_root = root.create_folder(@test_root_folder, exists: "OVERWRITE")
		puts "\nCreate folder- /#{@test_root_subfolder}"
		test_folder = test_root.create_folder(@test_root_subfolder)
		
		TestFile.operations(test_root, test_folder, do_populate_only: true)
		puts "Folder API ##############################################################"
		operations(test_root, test_folder)
		puts "End Folder API #############################################################"
		
		ensure
			puts "\nCleanup ###########"
			test_root.delete(commit: true, force: true) if test_root
			
			if root
				root.list.each do |item|
					if item.name == @recreate_folder_name
						item.delete(force: true, commit: true) 			
						break
					end
				end
			end
			puts "\nEnd Cleanup ###########"
	end	


end	

if __FILE__ == $0
	begin
		session = TestSession.setup
		TestFolder.api(session)	
	rescue Bitcasa::Client::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end
end
