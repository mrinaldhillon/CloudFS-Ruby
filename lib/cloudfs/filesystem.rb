require_relative 'rest_adapter'
require_relative 'folder'
require_relative 'filesystem_common'

module CloudFS
	# FileSystem class provides interface to maintain cloudfs user's filesystem
	#
	# @author Mrinal Dhillon
	class FileSystem
		# @!attribute [r] root
		# @return [Folder] root folder of this end-user's filesystem
		# @raise [RestAdapter::Errors::SessionNotLinked, Client::Errors::ServiceError]
		def root
			@root ||= get_root
		end

    # @param rest_adapter [RestAdapter] cloudfs RESTful api object
		# @raise [RestAdapter::Errors::ArgumentError]
		def initialize(rest_adapter)
			fail RestAdapter::Errors::ArgumentError,
				"invalid client, input type must be Client" unless rest_adapter.is_a?(RestAdapter)
				@rest_adapter = rest_adapter
		end
		
		# Get root object of filesystem
		# @return [Folder] represents root folder of filesystem
		# @raise RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError
		def get_root
				response = @rest_adapter.get_folder_meta("/")
				FileSystemCommon.create_item_from_hash(@rest_adapter, **response)
		end

		# List contents of a folder in end-user's filesystem
		#
		# @param item [Folder, String] default: root, folder object 
		#		or url in end-user's filesystem
		#
		# @return [Array<Folder, File>] items under folder path
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidItemError]
		def list(item: nil)
			if (RestAdapter::Utils.is_blank?(item) || item.is_a?(String))
				response = @rest_adapter.list_folder(path: item, depth: 1)
				FileSystemCommon.create_items_from_hash_array(response, 
						@rest_adapter, parent: item)
			else
				item.list
			end
		end

		#	Move items to destination
		#
		# @param items [Array<File, Folder>] items
		# @param destination [Folder, String] destination folder or url
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') action to take in case 
		#		of a conflict with an existing item in destination folder.
		#
		# @return [Array<File, Folder>] moved items
		#	@note item at index in returned array is refrence to same object
		#		whose properties are updated as an effect of move operation at corresponding 
		#		index in input array 'items'
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::ArgumentError, Client::Errors::InvalidItemError, 
		#		Client::Errors::OperationNotAllowedError]
    # @see Item#move
		def move(items, destination, exists: 'RENAME')
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected items" unless items

			response = []
			Array(items).each do |item|
				response << item.move(destination, exists: exists)
			end
			response
		end

		#	Copy items to destination
		#
		# @param items [Array<File, Folder>] items
		# @param destination [Folder, String] destination folder or url
		# @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') action to take in case 
		#		of a conflict with an existing item in destination folder.
		#
		# @return [Array<File, Folder>] copied items
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::ArgumentError, Client::Errors::InvalidItemError, 
		#		Client::Errors::OperationNotAllowedError]
    # @see Item#copy
		def copy(items, destination, exists: 'RENAME')
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected array of items" unless items
			
			response = []
			Array(items).each do |item|
				response << item.copy(destination, exists: exists)
			end
			response
		end

		#	Delete items from end-user's filesystem
		#
		# @param items [Array<File, Folder>] items
		# @param force [Boolean] default: (false), set true to delete non-empty folder		
		# @param commit [Boolean] default: (false), set true to remove item permanently, 
		#		else deleted items are moved to trash
		#	
		# @return [Array<Boolean>] value at index is result of delete operation 
		#		on item at corresponding index in input array 'items'
		# @raise [Client::Errors::ArgumentError] 
		#
		#	@note item's properties in input 'items' array are updated 
		#		as an effect of delete operation. 
		# @see Item#delete Delete an item
		# @see #restore Restore items
		# @see Item#restore Restore an item
		def delete(items, force: false, commit: false, raise_exception: false)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected array of items" unless items

			responses = []
			Array(items).each do |item|
				responses << item.delete(force: force, commit: commit)
			end
			responses
		end

		#	Restore an item from trash
		#
		# @param item [File, Folder, String] item or url
		# @param destination_url [String] ('RESCUE' (default root), 
		#		RECREATE(named path)) path depending on exists option to place item into 
		#		if the original path does not exist.
		# @param exists [String] ('FAIL', 'RESCUE', RECREATE) action to take 
		#		if the recovery operation encounters issues
		#
		# @return [File, Folder] item object
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::ArgumentError, Client::Errors::InvalidItemError, 
		#		Client::Errors::OperationNotAllowedError]
		def restore_item(item, destination_url, exists)
			if item.is_a?(String)
				response = @rest_adapter.browse_trash(path: item)
				properties = response.fetch(:meta)
				item = FileSystemCommon.create_item_from_hash(@rest_adapter,
					in_trash: true, **properties)
			end
			
			item.restore(destination: destination_url, 
					exists: exists, raise_exception: true)
		end

		#	Restore items from trash
		#
		# @param items [Array<File, Folder, String>] items
		# @param destination [Folder, String] ('RESCUE' (default root), 
		#		RECREATE(named path)) path depending on exists option to place item into 
		#		if the original path does not exist.
		# @param exists [String] ('FAIL', 'RESCUE', 'RECREATE') 
		#		action to take if the recovery operation encounters issues, default 'FAIL'
		# @return [Array<File, Folder>] restored items
		#	@note unless item is url at corresponding index in input array 'items', 
		#		the item at index in returned array is refrence to same object
		#		whose properties are updated as an effect of restore operation at 
		#		corresponding index in input array 'items'
		#
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::ArgumentError, Client::Errors::InvalidItemError, 
		#		Client::Errors::OperationNotAllowedError]
		# @see Item#restore
		def restore(items, destination: nil, exists: 'FAIL')
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected items" unless items

			FileSystemCommon.validate_item_state(destination)
			destination_url = FileSystemCommon.get_folder_url(destination)

			response = []
			Array(items).each do |item|
				response << restore_item(item, destination_url, exists)
			end
			response
		end
		
		# @return [Array<File, Folder>] items in trash
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
		#		RestAdapter::Errors::InvalidItemError, RestAdapter::Errors::OperationNotAllowedError]
		def list_trash
			response = @rest_adapter.browse_trash.fetch(:items)
			FileSystemCommon.create_items_from_hash_array(response, 
					@rest_adapter, in_trash: true)
		end
	
		# List versions of file
		# @param item [File, String]
		# @return [Array<File>] versions of file
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::InvalidItemError, Client::Errors::OperationNotAllowedError]
		# @see Item#versions
		def list_file_versions(item)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected Item or string path" if RestAdapter::Utils.is_blank?(item)

			if item.is_a?(String)
				response = @rest_adapter.list_file_versions(item)
				FileSystemCommon.create_items_from_hash_array(response, 
						@rest_adapter, parent: item)
			else
				item.versions
			end
		end

		# List shares created by end-user
		# @return [Array<Share>] shares
		# @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError]
		def list_shares
			response = @rest_adapter.list_shares
			FileSystemCommon.create_items_from_hash_array(response, @rest_adapter)
		end

		# Create share of paths in user's filesystem
		# @param items [Array<File, Folder, String>] file, folder or url
		# @return [Share] instance
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::ArgumentError, Client::Errors::InvalidItemError, 
		#		Client::Errors::OperationNotAllowedError]
		def create_share(items)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected items or paths" unless items

			paths = []	
			Array(items).each do |item|
				FileSystemCommon.validate_item_state(item)
				paths << FileSystemCommon.get_item_url(item)
			end

			response = @rest_adapter.create_share(paths)
			FileSystemCommon.create_item_from_hash(@rest_adapter, **response)
    end

    # Create share of path in user's filesystem
    # @param path [String] file, folder or url
    # @return [Share] instance
    # @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError,
    #		Client::Errors::ArgumentError, Client::Errors::InvalidItemError,
    #		Client::Errors::OperationNotAllowedError]
    def create_share(path, password: nil)
      fail RestAdapter::Errors::ArgumentError,
           "Invalid input, expected item or path" unless path

      FileSystemCommon.validate_item_state(path)
      path = FileSystemCommon.get_item_url(path)

      response = @rest_adapter.create_share(path, password: password)
      FileSystemCommon.create_item_from_hash(@rest_adapter, ** response)
    end

		# Fetches share associated with share key.
		#	@param share_key [String] valid share key
		#	@param password [String] password if share is locked
		#	@return [Share] instance of share
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::ArgumentError]
		#	@note	This method is intended for retrieving share from another user
		def retrieve_share(share_key, password: nil)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected items or paths" if RestAdapter::Utils.is_blank?(share_key)

			@rest_adapter.unlock_share(share_key, password) if password
			response = @rest_adapter.browse_share(share_key).fetch(:share)
			FileSystemCommon.create_item_from_hash(@rest_adapter, **response)
		end

		def get_item(path)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected item path" if RestAdapter::Utils.is_blank?(path)

			if path.is_a?(String)
				FileSystemCommon.get_item(@rest_adapter, path)
			else
				return nil
			end
		end


		private :restore_item, :get_root
	end
end
