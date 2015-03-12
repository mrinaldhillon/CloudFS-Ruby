#!/usr/bin/env ruby
require_relative '../lib/bitcasa.rb'
require_relative './session.rb'
require_relative './folder.rb'
require_relative './file.rb'

module TestFileSystem
	extend self
	@test_root_folder = "test_root"
	@test_root_subfolder = "test_root_sub"
	@recreate_folder_name = "test_recreate_folder" 
	@rescue_folder_name = "test_rescue_folder"	
	@debug = false
	
	def debug(string)
		puts string if @debug == true
	end

	def fs_api(fs, folder)
		debug "\nList Filesystem path #{folder.url}"
		debug "List items"
		items = fs.list(item: folder)
		list_items(items)

		share_api(fs, folder)
		copy_items(fs, folder, items)
		move_items(fs, folder, items)
		delete_items(fs, items)
		restore_items(fs, folder, items)
	end

	def list_share(share)
		debug "\nshare key: #{share.share_key}"
		debug "share name: #{share.name}"
		debug "url: #{share.url}"
		debug "short_url: #{share.short_url}"
		debug "date_created: #{share.date_created}"
		debug "size: #{share.size}"
	end


	def share_api(fs, test_folder)
		puts "\nShare Apis#####################"
		debug "\nCreate Share"
		share = fs.create_share(test_folder)
		debug "\nList Shares"
		shares = fs.list_shares
		shares.each do |share|
			list_share(share)
		end
		password = "Pa55w0rd"
		debug "\nSet share password"	
		share.set_password(password)

		debug "\nUnlock share"	
		share.unlock(password)

		debug "\nBrowse Share: #{share.share_key} "
		items = fs.list(item: share)
		list_items(items)

		debug "\nGet new share from share key"
		new_share = fs.share_from_share_key(share.share_key, password: password)
		items = share.list
		list_items(items)

		debug "\nChange share name: #{share.name} to bitcasa_test_share" 
		share.name = "bitcasa_test_share"
		share.save(password: password)
		# At this point new_share object has become inconsistent
		list_share(share)
		debug "\nCreate folder to recieve share"
		folder = fs.root.create_folder("recieve_share", exists: "OVERWRITE")
		debug "Folder name #{folder.name}"
		debug "Folder name #{folder.url}"

		debug "\nReceive share"
		items = share.receive(path: folder.url)
		list_items(items) 
		
		debug "\nRefresh new share"
		new_share.refresh
		list_share(share)

		ensure
			debug "\nDelete share"	
			share.delete if share

			folder.delete(commit: true, force: true) if folder
		puts "\nEnd Share Apis#####################"
	end



	def move_items(fs, parent, items)
		puts "\nMove items############"
		debug "Create destination folder"	
		dest_folder = parent.create_folder("testfs_move_to")

		debug "Move to: #{dest_folder.url}"
		fs.move(items, dest_folder)
		debug "\nList Moved Items"
		list_items(items) 
		puts "\nEnd Move Items############"
	end

	def copy_items(fs, parent, items)
		puts "\nCopy items############"
		debug "Create dest folder"	
		dest_folder = parent.create_folder("testfs_copy_to")

		debug "Copy to: #{dest_folder.url}"
		copied_items = fs.copy(items, dest_folder)
		debug "\nList copied Items"
		list_items(copied_items)

		puts "\nEnd copy Items############"
	end

	def browse_trash(fs)
		puts "\nList Trash Items#############"
		items = fs.browse_trash
		list_items(items)
		puts "\nEnd List Trash Items############"
		items
	end
		
	def restore_items(fs, parent, items)
		puts "\nRestore items##########"
		restore_at_folder = nil	
		debug "\nDelete original folder to test rescue"	
		fs.delete(parent, force: true) 

		debug "\nCreate rescue path to test restore rescue /#{@rescue_folder_name}"
		restore_at_folder = fs.root.create_folder(@rescue_folder_name, 
				exists: "OVERWRITE")

		debug "\nRestore items at #{restore_at_folder.url} exists: rescue if original path does not exists"
		fs.restore(items, destination: restore_at_folder, exists: 'RESCUE')
		debug "\nRestored items:"
		list_items(items)
		
		debug "\nDelete items"	
		fs.delete(items, force: true)

		debug "\nDelete parent folder to test recreate"
		fs.delete(restore_at_folder, force: true, commit: true)

		debug "\nRestore item at /#{@recreate_folder_name} exists: recreate if original path does not exists"
		fs.restore(items.first, destination: "#{@recreate_folder_name}", exists: 'RECREATE')
		debug "\nRestored item:"
		list_items(items.first)
		ensure
			fs.delete(restore_at_folder, force: true, commit: true) if (restore_at_folder && restore_at_folder.exists?)
		puts "\nEnd Restore items##########"
	end

	def delete_items(fs, items)
		puts "\nDelete items##########"
		fs.delete(items, commit: false, force: true).each { |resp| debug resp }
		debug "\nItems in trash:"
		list_items(items)
		puts "\nEnd Delete items##########"
	end

	def list_items(items, &block)
			Array(items).each do |i|
				debug "name: #{i.name}"
				debug "url: #{i.url}" 
				yield i if block
			end
	end


	def recursive_list(fs, item, &block)
		items = fs.list(item: item)	
		items.each do |i|
			debug "name: #{i.name}"
			debug "absolute path: #{i.url}"
			
			yield i if block

			if i.respond_to?(:list)
				debug "List Recursive Folder #{i.name}"
				recursive_list(fs, i, &block)
			end
		end
	end

	def api(session, test_debug: false)
		@debug = test_debug
		root = nil
		test_root = nil
		fs = session.filesystem
		debug "\nGet filesystem root"
		root = fs.root
		
		debug "\nCreate folder- /#{@test_root_folder}"
		test_root = root.create_folder(@test_root_folder, exists: "OVERWRITE")
		debug "\nCreate folder- /#{@test_root_subfolder}"
		test_folder = test_root.create_folder(@test_root_subfolder)

		debug "Populate ##############################################################"
		TestFile.operations(test_root, test_folder, do_populate_only: true)
		TestFolder.operations(test_root, test_folder, do_populate_only: true)
		debug "End Populate #############################################################"
		
		puts "FileSystem API ############################################################"
		fs_api(fs, test_folder)
		puts "END FileSystem API ########################################################"
		puts "Passed FileSystem API"
		ensure
			debug "\nCleanup ###########"
			test_root.delete(commit: true, force: true) if test_root
			
			if root
				root.list.each do |item|
					if item.name == @recreate_folder_name
						item.delete(force: true, commit: true, raise_exception: true)
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
		TestFileSystem.api(session, test_debug: false)
	rescue CloudFS::RestAdapter::Errors::Error
		debug error
		debug error.class
		debug error.code if error.respond_to?(:code)
		debug error.request if error.respond_to?(:request)
		debug error.response if error.respond_to?(:response)
		debug error.backtrace if error.respond_to?(:backtrace)
	end
end
