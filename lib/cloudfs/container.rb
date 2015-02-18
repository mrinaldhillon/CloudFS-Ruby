require_relative 'item'
require_relative 'client'
require_relative 'filesystem_common'

module CloudFS
	# Base class for {Folder}
	#
	# @author Mrinal Dhillon
	#	@example
	#		folder = session.filesystem.root.create_folder(name_of_folder)
	#		folder.list		# => []
	#		session.filesystem.root.list	# => Array<File, Folder>
	class Container < Item
		# @see Item#initialize
		def initialize(client, parent: nil, in_trash: false, 
				in_share: false, **properties)
			fail Client::Errors::ArgumentError, 
		 		"Invalid item of type #{properties[:type]}" unless properties[:type] == 
				"folder" || properties[:type] == "root"
			super
		end

		# List contents of this container
		#
		# @return [Array<Folder, File>] list of items
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidItemError]
		def list
			fail Client::Errors::InvalidItemError, 
				"Operation not allowed as item does not exist anymore" unless exists?

			if @in_trash
				response = @client.browse_trash(path: @url).fetch(:items)
			else
				response = @client.list_folder(path: @url, depth: 1)
			end
			FileSystemCommon.create_items_from_hash_array(response, 
					@client, parent: @url, in_trash: @in_trash)
		end

		# Create folder under this container
		#
		# @param name [String] name of folder to be created
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME', 'REUSE') action to take 
		#		if the item already exists
		#
		# @return [Folder] instance
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::ArgumentError, Client::Errors::InvalidItemError, 
		#		Client::Errors::OperationNotAllowedError]
		def create_folder(name, exists: 'FAIL')
			FileSystemCommon.validate_item_state(self)	
			
			properties = @client.create_folder(name, path: @url, exists: exists)
			FileSystemCommon.create_item_from_hash(@client, parent: @url, **properties)
		end

		
		# overriding inherited properties that are not not valid for folder
		private :extension, :extension=, :mime, :mime=, :blocklist_key, 
			:blocklist_id, :size, :versions, :old_version?
	end
end
