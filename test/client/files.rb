#!/usr/bin/env ruby
require_relative '../../lib/bitcasa/client'
require_relative './folder'
require 'tempfile'

module TestFileApi
	extend self
	def fileapi(client, test_folder_url, do_populate_only: false)
		temp_file = nil
		str_io = nil
		puts "\nUploading file"
		local_file_name = "testfile"	
		puts "\nCreating temporary file to upload"
		temp_file = Tempfile.new(local_file_name)

		1000.times do 
			temp_file.write("this test file")
		end
		temp_file.flush
		temp_file.rewind

		puts "\nMD5 hash of temporary file"
		puts Digest::MD5.file(temp_file.path).hexdigest
		resp = client.upload(test_folder_url, temp_file, exists: 'FAIL')

		file_url = "#{test_folder_url}/#{resp[:id]}"
		version = resp[:version]
	
		str_io = StringIO.new
		puts "\nFile read stream"
		client.download(file_url) { |chunk| str_io.write(chunk) }
		puts "MD5 sum of stream" 
		puts Digest::MD5.hexdigest(str_io.string)

		puts "\nCopy testfile to testfile.@copy"
		resp = client.copy_file(file_url, test_folder_url, "testfile.@copy", exists: 'FAIL')
		file_copy_url = "#{test_folder_url}/#{resp[:id]}"

		str = %q(Alter Metadata of testfile: change name to testfile.@altered, date created = now, application data = "{a: "b", c: "d", e: {f: "g", h: "i"}")
		puts "\n#{str}"
		resp = client.alter_file_meta(file_url, version, version_conflict: 'FAIL', name: "testfile.@altered", date_created: "#{Time.now.to_i}", application_data: {a: "b", c: "d", e: {f: "g", h: "i"}})

		return if do_populate_only

		puts "\nMove testfile.@copy to testfile.@move"
		resp = client.move_file(file_copy_url, test_folder_url, "testfile.@move", exists: 'FAIL')
		file_moved_url = "#{test_folder_url}/#{resp[:id]}"
		
		puts "\nGet Metadata of testfile"
		resp = client.get_file_meta(file_url)
		

		puts "\nList file versions"
		resp = client.list_file_versions(file_url)
		
		version = resp[0][:version]
		
		puts "\nList single file version"
		resp = client.list_single_file_version(file_url, version)
		

		puts "\nPromote file version"
		resp = client.promote_file_version(file_url, version)
		

		puts "\nDelete file"
		resp = client.delete_file(file_url, commit: true)
		
		
		ensure
			if temp_file
				temp_file.close
				temp_file.unlink
			end
			str_io.close if str_io
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

	def api(client)
		test_folder_url = setup_testfolder(client, "/", "test_folder")
		fileapi(client, test_folder_url)
		ensure
			puts "Cleanup.."
			client.delete_folder(test_folder_url, commit: true, force: true) if test_folder_url
	end	
end

if __FILE__ == $0
	begin
		client = TestAuthApi.get_client
		TestAuthApi.authenticate(client)
		TestFileApi.api(client)
	rescue Bitcasa::Client::Errors::Error => error
		puts error
		puts error.class
		puts error.code if error.respond_to?(:code)
		puts error.request if error.respond_to?(:request)
		puts error.response if error.respond_to?(:response)
		puts error.backtrace if error.respond_to?(:backtrace)
	end
end
