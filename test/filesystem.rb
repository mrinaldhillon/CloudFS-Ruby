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

	def fs_api(fs, folder)
		puts "\nList Filesystem path #{folder.url}"
		puts "List items"
		items = fs.list(item: folder)
		list_items(items)

		share_api(fs, folder)
		copy_items(fs, folder, items)
		move_items(fs, folder, items)
		delete_items(fs, items)
		restore_items(fs, folder, items)
	end

	def list_share(share)
		puts "\nshare key: #{share.share_key}"
		puts "share name: #{share.name}"
		puts "url: #{share.url}"
		puts "short_url: #{share.short_url}"
		puts "date_created: #{share.date_created}"
		puts "size: #{share.size}"
	end


	def share_api(fs, test_folder)
		puts "\nShare Apis#####################"
		puts "\nCreate Share"
		share = fs.create_share(test_folder)
		puts "\nList Shares"
		shares = fs.list_shares
		shares.each do |share|
			list_share(share)
		end
		password = "Pa55w0rd"
		puts "\nSet share password"	
		share.set_password(password)

		puts "\nUnlock share"	
		share.unlock(password)

		puts "\nBrowse Share: #{share.share_key} "
		items = fs.list(item: share)
		list_items(items)

		puts "\nGet new share from share key"
		new_share = fs.share_from_share_key(share.share_key, password: password)
		items = share.list
		list_items(items)

		puts "\nChange share name: #{share.name} to bitcasa_test_share" 
		share.name = "bitcasa_test_share"
		share.save(password: password)
		# At this point new_share object has become inconsistent
		list_share(share)
		puts "\nCreate folder to recieve share"
		folder = fs.root.create_folder("recieve_share", exists: "OVERWRITE")
		puts "Folder name #{folder.name}"
		puts "Folder name #{folder.url}"

		puts "\nReceive share"
		items = share.receive(path: folder.url)
		list_items(items) 
		
		puts "\nRefresh new share"
		new_share.refresh
		list_share(share)

		ensure
			puts "\nDelete share"	
			share.delete if share

			folder.delete(commit: true, force: true) if folder
		puts "\nEnd Share Apis#####################"
	end



	def move_items(fs, parent, items)
		puts "\nMove items############"
		puts "Create destination folder"	
		dest_folder = parent.create_folder("testfs_move_to")

		puts "Move to: #{dest_folder.url}"
		fs.move(items, dest_folder)
		puts "\nList Moved Items"
		list_items(items) 
		puts "\nEnd Move Items############"
	end

	def copy_items(fs, parent, items)
		puts "\nCopy items############"
		puts "Create dest folder"	
		dest_folder = parent.create_folder("testfs_copy_to")

		puts "Copy to: #{dest_folder.url}"
		copied_items = fs.copy(items, dest_folder)
		puts "\nList copied Items"
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
		puts "\nDelete original folder to test rescue"	
		fs.delete(parent, force: true) 

		puts "\nCreate rescue path to test restore rescue /#{@rescue_folder_name}"
		restore_at_folder = fs.root.create_folder(@rescue_folder_name, 
				exists: "OVERWRITE")

		puts "\nRestore items at #{restore_at_folder.url} exists: rescue if original path does not exists"
		fs.restore(items, destination: restore_at_folder, exists: 'RESCUE')
		puts "\nRestored items:"
		list_items(items)
		
		puts "\nDelete items"	
		fs.delete(items, force: true)

		puts "\nDelete parent folder to test recreate"
		fs.delete(restore_at_folder, force: true, commit: true)

		puts "\nRestore item at /#{@recreate_folder_name} exists: recreate if original path does not exists"
		fs.restore(items.first, destination: "#{@recreate_folder_name}", exists: 'RECREATE')
		puts "\nRestored item:"
		list_items(items.first)
		ensure
			fs.delete(restore_at_folder, force: true, commit: true) if (restore_at_folder && restore_at_folder.exists?)
		puts "\nEnd Restore items##########"
	end

	def delete_items(fs, items)
		puts "\nDelete items##########"
		fs.delete(items, commit: false, force: true).each { |resp| puts resp }
		puts "\nItems in trash:"
		list_items(items)
		puts "\nEnd Delete items##########"
	end

	def list_items(items, &block)
			Array(items).each do |i|
				puts "name: #{i.name}"
				puts "url: #{i.url}" 
				yield i if block
			end
	end


	def recursive_list(fs, item, &block)
		items = fs.list(item: item)	
		items.each do |i|
			puts "name: #{i.name}"
			puts "absolute path: #{i.url}"
			
			yield i if block

			if i.respond_to?(:list)
				puts "List Recursive Folder #{i.name}"
				recursive_list(fs, i, &block)
			end
		end
	end

	def api(session)
		root = nil
		test_root = nil
		fs = session.filesystem
		puts "\nGet filesystem root"
		root = fs.root
		
		puts "\nCreate folder- /#{@test_root_folder}"
		test_root = root.create_folder(@test_root_folder, exists: "OVERWRITE")
		puts "\nCreate folder- /#{@test_root_subfolder}"
		test_folder = test_root.create_folder(@test_root_subfolder)

		puts "Populate ##############################################################"
		TestFile.operations(test_root, test_folder, do_populate_only: true)
		TestFolder.operations(test_root, test_folder, do_populate_only: true)
		puts "End Populate #############################################################"
		
		puts "Filesystem API ############################################################"
		fs_api(fs, test_folder)
		puts "END Filesystem API ########################################################"

		ensure
			puts "\nCleanup ###########"
			test_root.delete(commit: true, force: true) if test_root
			
			if root
				root.list.each do |item|
					if item.name == @recreate_folder_name
						item.delete(force: true, commit: true, raise_exception: true)
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
		TestFileSystem.api(session)
	rescue Bitcasa::Client::Errors::Error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end
end
