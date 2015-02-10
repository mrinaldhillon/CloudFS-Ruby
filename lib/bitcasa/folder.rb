require_relative 'container'
require_relative 'filesystem_common'


module Bitcasa
	# Represents a folder in the user's filesystem that can contain files and other folders.
	#
	#	@author Mrinal Dhillon
	#	@example
	#		folder = session.filesystem.root.create_folder(name_of_folder)
	#		folder.name = "newname"
	#		folder.save
	#		file = folder.upload(local_file_path)
	#		folder.list		#=> Array<File, Folder>
	class Folder < Container
	
		# Upload file to this folder
		#
		# @param source [String, #read&#pos&#pos=] local file path, in-memory string, 
		#		an io object for example StringIO, File, Tempfile.
		# @param name [String] default: nil, name of uploaded file, must be set 
		#		if source does not respond to #path unless source is local file path
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') 
		#		action to take in case of a conflict with an existing folder.
		#	@param upload_io [Boolean] default: false, 
		#		if set to false, source is considered to be a local file path
		#
		# @return [File] instance refrence to uploaded file
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		# @example
		#		Upload local file path
		#			file = folder.upload(local_file_path, name: "testfile.txt")
		#	@example
		#		Upload ::File instance
		# 	file = ::File.open(local_file_path, "r") do |fp|
		#				folder.upload(fp, name: "testfile.txt", upload_io: true)
		#		end
		#	@example
		#		Upload string
		#			file = folder.upload("This is upload string", 
		#				name: 'testfile.txt', upload_io: true)
		#	@example
		#		Upload stream
		#			io = StringIO.new
		#			io.write("this is test stringio")
		#			file = folder.upload(io, name: 'testfile.txt', upload_io: true)
		#			io.close
		def upload(source, name: nil, exists: 'FAIL', upload_io: false)
			FileSystemCommon.validate_item_state(self)
			
			if upload_io == false
				response = ::File.open(source, "r") do |file|
					@client.upload(@url, file, name: name, exists: exists)
				end
			else
				response = @client.upload(@url, source, name: name, exists: exists)
			end
			FileSystemCommon.create_item_from_hash(@client, 
						parent: @url, **response)
		end

		# overriding inherited properties that are not not valid for folder
		private :extension, :extension=, :mime, :mime=, :blocklist_key, 
			:blocklist_id, :size, :versions, :old_version?
	end
end
