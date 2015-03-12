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
	@debug = false
	
	def debug(string)
		puts string if @debug == true
	end

	def operations(parent_root, parent_folder, do_populate_only: false)
		debug "\nCreate Folder a1"
		a1 = parent_folder.create_folder("a1")
		debug "name: #{a1.name}"
		debug "absolute path: #{a1.url}"

		debug "\nCreate Folder a1/b2"
		b2 = a1.create_folder("b2")
		debug "name: #{b2.name}"
		debug "absolute path: #{b2.url}"

		debug "\nCreate Folder c1"
		c1 = parent_folder.create_folder("c1")
		debug "name: #{c1.name}"
		debug "absolute path: #{c1.url}"

		debug "\nCopy Folder a1/b2 to d1"
		d1 = b2.copy(parent_folder, name: "d1")
		debug "name: #{d1.name}"
		debug "absolute path: #{d1.url}"

		debug "\nMove Folder d1 to c1/d2"
		d2 = d1.move(c1, name: "d2")
		debug "name: #{d2.name}"
		debug "absolute path: #{d2.url}"

		debug "\n Alter meta of d2, name = d2.new, date_created = (current_time - 1000), application_data"
		d2.name = "d2.new"
		d2.date_created = Time.at(Time.now.to_i - 1000)
		d2.application_data={a: "b", b: {c: "d", d: "e"}}
		d2.save
		debug "Fetching changed properties of d2.."
		debug "name: #{d2.name}"
		debug "absolute path: #{d2.url}"
		
		return if do_populate_only
		debug "\nList Folder recursively #{parent_folder}"
		recursive_list(parent_folder)

		puts "\nFolder Restore Operations#####################"
		debug "\nDeleting folder #{d2.name} at #{d2.url}"
		d2.delete(raise_exception: true, force: true)
			
		debug "\nRestore folder #{d2.name} in trash url- #{d2.url} to original path"
		d2.restore(raise_exception: true)
		debug "Restored folder URL: #{d2.url}"
		
		debug "\nDeleting folder #{d2.name} at #{d2.url}"
		d2.delete(raise_exception: true, force: true)

		debug "\nDeleting parent folder to test rescue path"
		parent_folder.delete(raise_exception: true, force: true)

		debug "\nCreate rescue path to test restore rescue ./#{@rescue_folder_name}"
		restore_at_folder = parent_root.create_folder(@rescue_folder_name, 
				exists: "OVERWRITE")
		
		debug "\nRestore folder #{d2.name} in trash url - #{d2.url} at rescue path #{restore_at_folder.url}"
		d2.restore(destination: restore_at_folder, exists: "RESCUE", raise_exception: true)
		debug "Restored folder URL: #{d2.url}"

		debug "\nDeleting folder #{d2.name} at #{d2.url}"
		d2.delete(raise_exception: true, force: true)

		debug "\nDeleting parent folder to test recreate path"
		restore_at_folder.delete(raise_exception: true, force: true)

		debug "\nRestore folder #{d2.name} in trash url - #{d2.url} at recreate path /#{@recreate_folder_name}"
		d2.restore(destination: "/#{@recreate_folder_name}", 
				exists: "RECREATE", raise_exception: true)
			
		debug "Restored folder URL: #{d2.url}"
		puts "\nEnd File Restore Operations###############"
	end

	def recursive_list(folder, &block)
		folder.list.each do |i|
			debug "name: #{i.name}"
			debug "absolute path: #{i.url}"
			debug "class: #{i.class}"	
			yield i if block

			if i.is_a?(CloudFS::Folder)
				debug "List Recursive Folder #{i.name}"
				recursive_list(i, &block)
			end
		end
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
		puts test_folder.date_created	
		TestFile.operations(test_root, test_folder, do_populate_only: true)
		puts "Folder API ##############################################################"
		operations(test_root, test_folder)
		puts "End Folder API #############################################################"
		puts "Passed Folder API"	
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
			debug "\nEnd Cleanup ###########"
	end	


end	

if __FILE__ == $0
	begin
		session = TestSession.setup
		TestFolder.api(session, test_debug: false)	
	rescue CloudFS::RestAdapter::Errors::Error => error
		debug error
		debug error.class
		debug error.code if error.respond_to?(:code)
		debug error.request if error.respond_to?(:request)
		debug error.response if error.respond_to?(:response)
		debug error.backtrace if error.respond_to?(:backtrace)
	end
end
