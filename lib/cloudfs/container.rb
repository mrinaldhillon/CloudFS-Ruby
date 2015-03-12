require_relative 'item'
require_relative 'rest_adapter'
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
		def initialize(rest_adapter, parent: nil, in_trash: false,
				in_share: false, **properties)
			fail RestAdapter::Errors::ArgumentError,
		 		"Invalid item of type #{properties[:type]}" unless properties[:type] == 
				"folder" || properties[:type] == "root"
			super
		end

		# List contents of this container
		#
		# @return [Array<Folder, File>] list of items
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::InvalidItemError]
		def list
			fail RestAdapter::Errors::InvalidItemError,
				"Operation not allowed as item does not exist anymore" unless exists?

			if @in_trash
				response = @rest_adapter.browse_trash(path: @url).fetch(:items)
			else
				response = @rest_adapter.list_folder(path: @url, depth: 1)
			end
			FileSystemCommon.create_items_from_hash_array(response, 
					@rest_adapter, parent: @url, in_trash: @in_trash)
		end

		# overriding inherited properties that are not not valid for folder
		private :extension, :extension=, :mime, :mime=, :blocklist_key, 
			:blocklist_id, :size, :versions, :old_version?
	end
end
