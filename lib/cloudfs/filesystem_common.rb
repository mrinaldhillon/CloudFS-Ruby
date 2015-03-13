require_relative 'rest_adapter'

module CloudFS
	# @private
	# Provides common filesystem operations consumed by other classes
	module FileSystemCommon
		extend self
		
		# @return [Audio, Video, Photo, Document, File] based on mime type
		def create_file_from_mime_type(rest_adapter, parent: nil,
				in_trash: false, in_share: false, old_version: false, **hash)
			require_relative 'file'
			require_relative 'media'
				
			mime = hash[:mime]
			if mime.include?("audio")
				Audio.new(rest_adapter, parent: parent,
						in_trash: in_trash, in_share: in_share, 
						old_version: old_version, **hash)
			elsif mime.include?("video")
				Video.new(rest_adapter, parent: parent,
						in_trash: in_trash, in_share: in_share, 
						old_version: old_version, **hash)
			elsif mime.include?("image")
				Photo.new(rest_adapter, parent: parent,
						in_trash: in_trash, in_share: in_share, 
						old_version: old_version, **hash)
			elsif mime.include?("text") || mime.include?("pdf")
				Document.new(rest_adapter, parent: parent,
						in_trash: in_trash, in_share: in_share, 
						old_version: old_version, **hash)
			else File.new(rest_adapter, parent: parent,
						in_trash: in_trash, in_share: in_share, 
						old_version: old_version, **hash)
			end
		end


		# Create item from hash
    # @param rest_adapter [RestAdapter] RESTful Client instance
		# @param parent [Item, String] parent item of type folder
		# @param in_trash [Boolean] set true to specify, item exists in trash
		# @param in_share [Boolean] set true to specify, item exists in share
		# @param old_version [Boolean] set true to specify, item is an old version
		# @param hash [Hash] item properties
		# @return [File, Folder, Share] item
		# @raise [RestAdapter::Errors::ArgumentError]
		#	@review not creating file objects based on mime type, 
		#		since save operation cannot update the class of file object, 
		#		if mime is changed
		def create_item_from_hash(rest_adapter, parent: nil,
				in_trash: false, in_share: false, old_version: false, **hash)
			require_relative 'file'
			require_relative 'folder'
			require_relative 'share'

			return Share.new(rest_adapter, **hash) if hash.key?(:share_key)
			fail RestAdapter::Errors::ArgumentError,
				"Did not recognize item" unless hash.key?(:type)
			if (hash[:type] == "folder" || hash[:type] == "root")
				Folder.new(rest_adapter, parent: parent,
						in_trash: in_trash, in_share: in_share, **hash)
			else 
				File.new(rest_adapter, parent: parent,
						in_trash: in_trash, in_share: in_share, 
						old_version: old_version, **hash)
#create_file_from_mime_type(rest_adapter, parent: parent,
#		in_trash: in_trash, in_share: in_share, 
#						old_version: old_version, **hash) 

			end
		end

		# Create array items from corresponding array of hashes
		# @param hashes [Array<Hash>] array of hash properties of items
    # @param rest_adapter [RestAdapter] RESTful Client instance
		# @option parent [Item, String] parent item of type folder
		# @option in_trash [Boolean] set true to specify, items exist in trash
		# @option in_share [Boolean] set true to specify, items exist in share
		# @option old_version [Boolean] set true to specify, items are old version
		# @return [Array<File, Folder, Share>] items
		# @raise [RestAdapter::Errors::ArgumentError]
		def create_items_from_hash_array(hashes, rest_adapter,
				parent: nil, in_trash: false, in_share: false, old_version: false)
			items = []
			hashes.each do |item|
				resp = create_item_from_hash(rest_adapter, parent: parent,
						in_trash: in_trash, in_share: in_share, 
						old_version: old_version, **item)
				items << resp
			end
			items
		end
		
		# Get folder url
		# @param folder [Item, String]
		# @return [String] url of item
		# @raise [RestAdapter::Errors::ArgumentError]
		def get_folder_url(folder)
			return nil if RestAdapter::Utils.is_blank?(folder)
			return folder.url if (folder.respond_to?(:url) && 
					folder.respond_to?(:type) && (folder.type == "folder"))
			return folder if folder.is_a?(String)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input of type #{folder.class}, expected destination item of type CloudFS::Folder or string"
		end

		# Get item url
		# @param item [File, Folder, String]
		# @return [String] url of item
		# @raise [RestAdapter::Errors::ArgumentError]
		def get_item_url(item)
			return nil if RestAdapter::Utils.is_blank?(item)
			return item.url if item.respond_to?(:url)
			return item if item.is_a?(String)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected destination item of type file, folder or string"
		end

		# Get item name
		# @param item [File, Folder, String]
		# @return [String] name of item
		# @raise [RestAdapter::Errors::ArgumentError]
		def get_item_name(item)
			return nil if RestAdapter::Utils.is_blank?(item)
			return item.name if item.respond_to?(:name)
			return item if item.is_a?(String)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected destination item of type file, folder or string"
		end

		# Validate item's current state for operations
		# @param item [Item] item to validate
		# @option in_trash [Boolean] set false to avoid check if item in trash
		# @option in_share [Boolean] set false to avoid check if item in share
		# @option exists [Boolean] set false to avoid check if item exists
		# @version version [Boolean] set false to avoid check if item is not current version
		# @raise [RestAdapter::Errors::InvalidItemError,
		#		RestAdapter::Errors::OperationNotAllowedError]
		def validate_item_state(item, in_trash: true, in_share: true, exists: true, 
				old_version: true) 
			require_relative 'item'
			require_relative 'file'
			return nil unless item.kind_of?(Item)
			fail RestAdapter::Errors::InvalidItemError,
				"Operation not allowed as item does not exist anymore" if (exists && item.exists? == false)
			fail RestAdapter::Errors::OperationNotAllowedError,
				"Operation not allowed as item is in trash" if (in_trash && item.in_trash?)
			fail RestAdapter::Errors::OperationNotAllowedError,
				"Operation not allowed as item is in share" if (in_share && item.in_share?)
			fail RestAdapter::Errors::OperationNotAllowedError,
				"Operation not allowed as item is an older version" if (
						item.kind_of?(CloudFS::File) && old_version && item.old_version?)
		end

		# Validate share's current state for operations
		# @param share [Share] share instance to validate
		# @option exists [Boolean] set false to avoid check if share exists
		# @raise [RestAdapter::Errors::InvalidShareError,
		#		RestAdapter::Errors::ArgumentError]
		def validate_share_state(share, exists: true) 
			require_relative 'share'
			fail RestAdapter::Errors::ArgumentError,
				"Invalid object of type #{share.class}, expected Share" unless share.kind_of?(Share)
			fail RestAdapter::Errors::InvalidShareError,
				"Operation not allowed as share does not exist anymore" if (exists && share.exists? == false)
		end


		# Fetches properties of named path by recursively listing each member 
		#			starting root with depth 1 and filter=name=path_member
    # @param rest_adapter [RestAdapter] RESTful Client instance
		# @option named_path [String] named (not pathid) cloudfs path of item i.e. /a/b/c
		# @return [Hash] containing url and meta of item
		# @raise [RestAdapter::Errors::ServiceError, RestAdapter::Errors::ArgumentError]
		def get_properties_of_named_path(rest_adapter, named_path)
			fail RestAdapter::Errors::ArgumentError,
				"Invalid input, expected destination string" if RestAdapter::Utils.is_blank?(named_path)
 			fail RestAdapter::Errors::ArgumentError,
				"invalid rest_adapter, input type must be RestAdapter" unless rest_adapter.is_a?(RestAdapter)

			named_path = "#{named_path}".insert(0, '/') unless (named_path[0] == '/')
			first, *path_members = named_path.split('/')
			path = first

			response = []
			path_members.each	do |member|
				response = rest_adapter.list_folder(path: path, depth: 1,
						filter: "name=#{member}", strict_traverse: true)
				path << "/#{response.first[:id]}"
			end

			{url: path, meta: response[0]}
		end

		# Get an item's properties from server
		#
    # @param rest_adapter [RestAdapter] RESTful Client instance
		# @param parent_url [String] url of parent
		# @param id [String] pathid of item
		# @param type [String] ("file", "folder")
		# @return [Hash] metadata of item
		#
		# @raise [RestAdapter::Errors::ServiceError]
		def get_item_properties_from_server(rest_adapter, parent_url, id, type, in_trash: false)
#	item_url = parent_url == "/" ? "/#{id}" : "#{parent_url}/#{id}"
			item_url = parent_url.nil? ? "#{id}" : "#{parent_url}/#{id}"
			if in_trash == true
				properties = rest_adapter.browse_trash(path: item_url).fetch(:meta)
			elsif type == "folder"
				properties = rest_adapter.get_folder_meta(item_url)
			else
				properties = rest_adapter.get_file_meta(item_url)
			end
		end

		# Get an item's properties from server
		#
    # @param rest_adapter [RestAdapter] RESTful Client instance
		# @param item_url [String] url of item
		# @return File, Folder, Share] item
		#
		# @raise [RestAdapter::Errors::ServiceError]
		def get_item(rest_adapter, item_url)

				item_meta = rest_adapter.get_file_meta(item_url)
				item = create_item_from_hash(rest_adapter, **item_meta)
			
		end

	end
end	
