#!/usr/bin/env ruby
require_relative '../../lib/cloudfs/rest_adapter'
require_relative './authenticate.rb'

module TestFolderApi
	extend self
	def folderapi(client, test_folder_url, do_populate_only: false)
		share_key = nil	
		puts "\nCreate Folder a1"
		resp = client.create_folder("a1", path: test_folder_url, exists: 'FAIL')
		a1_path = "#{test_folder_url}/#{resp[:id]}"

		puts "\nCreate Folder a1/b2"
		resp = client.create_folder("b2", path: a1_path, exists: 'FAIL')
		b2_path = "#{a1_path}/#{resp[:id]}"

		puts "\nCreate Folder c1"
		resp = client.create_folder("c1", path: test_folder_url, exists: 'FAIL')
		c1_path = "#{test_folder_url}/#{resp[:id]}"

		puts "\nCopy Folder a1/b2 to d1"
		resp = client.copy_folder(b2_path, test_folder_url, "d1", exists: 'FAIL')
		
		d1_path = "#{test_folder_url}/#{resp[:id]}"

		puts "\nMove Folder d1 to c1/d2"
		resp = client.move_folder(d1_path, c1_path, "d2")
		
		d2_path = "#{c1_path}/#{resp[:id]}"
		
		return if do_populate_only

		puts "\nGet Metadata of c1/d2"
		resp = client.get_folder_meta(d2_path)

		str = %q(Alter Metadata of d2: change name to e2, date created = now, application data = "{a: "b", c: "d", e: {f: "g", h: "i"}")
		puts str
		resp = client.alter_folder_meta(d2_path, 0, version_conflict: 'IGNORE', name: "e2", date_created: "#{Time.now.getutc}", application_data: {a: "b", c: "d", e: {f: "g", h: "i"}})
		paths = [a1_path, c1_path]
		puts "\nShare Operations ######################################"

		puts "\nCreate share"
		resp = client.create_share(paths)
		share_key = resp[:share_key]
		password = "Pa55w0rd"
		puts "\nSet share password"	
		resp = client.alter_share_info(share_key, password: password)

		puts "\nUnlock share"
		resp = client.unlock_share(share_key, password)

		puts "\nBrowse share"
		resp = client.browse_share(share_key)

		puts "\nList shares"
		resp = client.list_shares

		puts "\nReceive share"
		resp = client.receive_share(share_key, path: b2_path, exists: 'FAIL')

		puts "\nList received path"
		client.list_folder(path: "#{b2_path}/#{resp.first[:id]}")

		puts "\nEND Share Operations ######################################"
		
		puts "\nList history"
		client.list_history

		puts "\nDelete folder c1/d2"
		resp = client.delete_folder(d2_path, force: true)
		
		puts "\nBrowse Trash"
		resp = client.browse_trash
		trash_path = resp[:items][0][:id]
		trash_name = resp[:items][0][:name]
		
		puts "\nRestore Trash File: #{trash_name}"
		resp = client.recover_trash_item(trash_path, restore: 'RESCUE', destination: test_folder_url)
		ensure
			puts "\nDelete share"
			client.delete_share(share_key) if share_key
	end


	def setup_testfolder(client, path, name)
		resp = client.create_folder(name, path: path, exists: 'OVERWRITE')
		if path == "/"
			test_folder_url = "#{resp[:id]}"
		else
			test_folder_url = "#{path}/#{resp[:id]}"
		end
		puts "\nTestfolder name: #{resp[:name]}, path :#{test_folder_url}"
		test_folder_url
	end

	def cleanup(client, test_folder_url)
		puts "Deleting #{test_folder_url}"
		client.delete_folder(test_folder_url, commit: true, force: true)
	end

	def api(client)
		test_folder_url = nil
		test_folder_url = setup_testfolder(client, "/", "test_folder")
		folderapi(client, test_folder_url)
		ensure
			puts "Cleanup.."
			cleanup(client, test_folder_url) if test_folder_url
	end	
end
if __FILE__ == $0
	begin
		client = TestAuthApi.get_client
		TestAuthApi.authenticate(client)
		TestFolderApi.api(client)
	rescue CloudFS::RestAdapter::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end
end
