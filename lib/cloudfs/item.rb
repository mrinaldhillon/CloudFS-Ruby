require_relative 'filesystem_common'
require_relative 'rest_adapter'

module CloudFS
  # An object managed by CloudFS. An item can be either a file or folder.
  #
  #	Item is the base class for File, Container whereas Folder is derived from Container
  #	Provides common APIs for files, folders
  # @author Mrinal Dhillon
  class Item

    # @return [String] the internal id of item that is right most path segment in url
    attr_reader :id

    #	@return [String] id of parent of item
    attr_reader :parent_id

    # @return [String]	type of item, either file or folder
    attr_reader :type

    #	@return [String] known current version of item
    attr_reader :version

    # @return [Boolean] indicating whether the item was created by mirroring a file
    attr_reader :is_mirrored

    #	@return [String] blocklist_key of file
    attr_reader :blocklist_key

    #	@return [String] blocklist_id of file
    attr_reader :blocklist_id

    #	@return [Fixnum] file size in bytes
    attr_reader :size

    # @return [String] absolute path of item in user's account
    attr_reader :url

    # @return [String] absolute path of item in user's account
    def path
      @url
    end

    # name of item
    #
    # @param value [String] name.
    #
    # @raise [RestAdapter::Errors::InvalidItemError,
    #   RestAdapter::Errors::OperationNotAllowedError]
    attr_accessor :name

    # mime type of file
    #
    # @param value [String]
    #
    # @raise [RestAdapter::Errors::InvalidItemError,
    #			RestAdapter::Errors::OperationNotAllowedError]
    attr_accessor :mime

    #	extension of item of type file
    # @overload extension
    # 	@return [String] extension of file
    #
    # @overload extension=(value)
    #		Set new file extension by including the extension in the name of file.
    #		CloudFS will assign the extension based on the name
    # 	@param value [String]
    # 	@raise [RestAdapter::Errors::InvalidItemError,
    #			RestAdapter::Errors::OperationNotAllowedError]
    attr_accessor :extension

    # extra metadata of item
    #	@overload application_data
    #		@return [Hash] extra metadata of item
    #
    # @overload application_data=(hash={})
    # 	Sets application_data
    # 	@param hash [Hash]
    # 	@raise [RestAdapter::Errors::InvalidItemError,
    #			RestAdapter::Errors::OperationNotAllowedError]
    # 	@todo support update of nested hash, currently overwrites nested hash
    attr_reader :application_data

    # see #name
    def name=(new_name)
      FileSystemCommon.validate_item_state(self)
      @name = new_name
      @changed_properties[:name] = new_name
      change_attributes(@changed_properties)
    end

    # @see #extension
    def extension=(value)
      fail OperationNotAllowedError,
           "Operation not allowed for item of type #{@type}" unless @type == "file"
      FileSystemCommon.validate_item_state(self)
      @extension = value
      @changed_properties[:extension] = value
    end

    #	@!attribute [rw] date_created
    #	Time when item was created
    # @overload date_created
    #		@return [Time] creation time
    def date_created
      if @date_created
        Time.at(@date_created)
      else
        nil
      end
    end

    # @see #date_created
    def date_created=(value)
      FileSystemCommon.validate_item_state(self)
      @date_created = value.utc.to_i
      @changed_properties[:date_created] = @date_created
    end

    #	@!attribute [rw] date_meta_last_modified
    #	Time when item's metadata was last modified
    # @overload date_meta_last_modified
    #		@return [Time] time when metadata was last modified
    def date_meta_last_modified
      if @date_meta_last_modified
        Time.at(@date_meta_last_modified)
      else
        nil
      end
    end

    # @see #date_meta_last_modified
    def date_meta_last_modified=(value)
      FileSystemCommon.validate_item_state(self)
      @date_meta_last_modified = value.utc.to_i
      @changed_properties[:date_meta_last_modified] = @date_meta_last_modified
    end

    #	@!attribute [rw] date_content_last_modified
    #	Time when item's content was last modified
    # @overload date_content_last_modified
    #		@return [Time] time when content was last modified
    def date_content_last_modified
      if @date_content_last_modified
        Time.at(@date_content_last_modified)
      else
        nil
      end
    end

    # @see #date_content_last_modified
    def date_content_last_modified=(value)
      FileSystemCommon.validate_item_state(self)
      @date_content_last_modified = value.utc.to_i
      @changed_properties[:date_content_last_modified] = @date_content_last_modified
    end

    # see #mime
    def mime=(value)
      fail OperationNotAllowedError,
           "Operation not allowed for item of type #{@type}" unless @type == 'file'
      FileSystemCommon.validate_item_state(self)
      @mime = value
      @changed_properties[:mime] = value
      change_attributes(@changed_properties)
    end

    def application_data
      if @application_data
        Marshal.load(Marshal.dump(@application_data))
      else
        {}
      end
    end

    def application_data=(hash={})
      FileSystemCommon.validate_item_state(self)
      if @application_data
        @application_data.merge!(hash)
      else
        @application_data = hash.dup
      end
      @changed_properties[:application_data].merge!(hash)
      change_attributes(@changed_properties)
    end

    # @param rest_adapter [RestAdapter] RESTful Client instance
    # @param parent [Item, String] default: ("/") parent folder item or url
    # @param in_trash [Boolean] set true to specify item exists in trash
    # @param in_share [Boolean] set true to specify item exists in share
    # @param old_version [Boolean] set true to specify item is an old version
    # @param [Hash] properties metadata of item
    #   @option properties [String] :id path id of item
    #   @option properties [String] :parent_id (nil) pathid of parent of item
    #   @option properties [String] :type (nil) type of item either file, folder
    #   @option properties [String] :name (nil)
    #   @option properties [Timestamp] :date_created (nil)
    #   @option properties [Timestamp] :date_meta_last_modified (nil)
    #   @option properties [Timestamp] :date_content_last_modified (nil)
    #   @option properties [Fixnum] :version (nil)
    #   @option properties [Boolean] :is_mirrored (nil)
    #   @option properties [String] :mime (nil) applicable to item
    #     type file only
    #   @option properties [String] :blocklist_key (nil) applicable to item
    #     type file only
    #   @option properties [String] :blocklist_id (nil) applicable to item
    #     type file only
    #   @option properties [Fixnum] :size (nil) applicable to item of
    #     type file only
    #   @option properties [Hash] :application_data ({}) extra metadata of item
    #
    # @raise [RestAdapter::Errors::ArgumentError]
    def initialize(rest_adapter, parent: nil, in_trash: false,
                   in_share: false, old_version: false, ** properties)
      fail RestAdapter::Errors::ArgumentError,
           'Invalid RestAdaper, input type must be CloudFS::RestAdapter' unless rest_adapter.is_a?(RestAdapter)

      @rest_adapter = rest_adapter
      set_item_properties(parent: parent, in_trash: in_trash,
                          in_share: in_share, old_version: old_version, ** properties)
    end

    # @see #initialize
    # @review required properties
    def set_item_properties(parent: nil, in_trash: false,
                            in_share: false, old_version: false, ** params)
      # id, type and name are required instance variables
      @id = params.fetch(:id) {
        fail RestAdapter::Errors::ArgumentError, 'Provide item id' }
      @type = params.fetch(:type) {
        fail RestAdapter::Errors::ArgumentError, 'Provide item type' }
      @name = params.fetch(:name) {
        fail RestAdapter::Errors::ArgumentError, 'Provide item name' }

      @type = 'folder' if @type == 'root'
      @parent_id = params[:parent_id]
      @date_created = params[:date_created]
      @date_meta_last_modified = params[:date_meta_last_modified]
      @date_content_last_modified = params[:date_content_last_modified]
      @version = params[:version]

      if @type == 'file'
        @is_mirrored = params[:is_mirrored]
        @mime = params[:mime]
        @blocklist_key = params[:blocklist_key]
        @extension = params[:extension]
        @blocklist_id = params[:blocklist_id]
        @size = params[:size]
      end

      @application_data = params[:application_data]
      @in_trash = in_trash
      @in_share = in_share
      @old_version = old_version
      @exists = true

      set_url(parent)
      changed_properties_reset
    end

    #	@return [Boolean] whether the item is an older version
    def old_version?
      @old_version
    end

    #	@return [Boolean] whether the item exists in trash
    def in_trash?
      @in_trash
    end

    #	@return [Boolean] whether the item exists in share
    def in_share?
      @in_share
    end

    # @return [Boolean] whether item exists, false if item
    #		has been deleted permanently
    def exists?
      @exists
    end

    # Reset changed properties
    def changed_properties_reset
      @changed_properties = {application_data: {}}
    end


    # Move this item to destination folder
    # @note	Updates this item and it's reference is returned.
    # @note Locally changed properties get discarded
    #
    # @param destination [Item, String] destination to move item to, should be folder
    # @param name [String] (nil) new name of moved item
    # @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME')
    #		action to take in case of a conflict with an existing folder, default 'RENAME'
    #
    # @return [Item] returns self
    #
    # @raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError, RestAdapter::Errors::ArgumentError,
    #   RestAdapter::Errors::InvalidItemError,
    #   RestAdapter::Errors::OperationNotAllowedError]
    def move(destination, name: nil, exists: 'RENAME')
      FileSystemCommon.validate_item_state(self)
      FileSystemCommon.validate_item_state(destination)

      destination_url = FileSystemCommon.get_folder_url(destination)
      name ||= @name

      if @type == 'folder'
        response = @rest_adapter.move_folder(
            @url,
            destination_url,
            name,
            exists: exists)
      else
        response = @rest_adapter.move_file(
            @url,
            destination_url,
            name,
            exists: exists)
      end
      # Overwrite this item's properties with Moved Item's properties
      set_item_properties(parent: destination_url, ** response)
      self
    end

    # Copy this item to destination
    # @note	Locally changed properties are not copied
    #
    # @param destination [Item, String] destination to copy item to,
    #   should be folder
    # @param name [String] (nil) new name of copied item
    # @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME')
    #		action to take in case of a conflict with an existing folder,
    #   default 'RENAME'
    #
    # @return [Item] new instance of copied item
    #
    # @raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError, RestAdapter::Errors::ArgumentError,
    #   RestAdapter::Errors::InvalidItemError,
    #   RestAdapter::Errors::OperationNotAllowedError]
    def copy(destination, name: nil, exists: 'RENAME')
      FileSystemCommon.validate_item_state(self)
      FileSystemCommon.validate_item_state(destination)

      destination_url = FileSystemCommon.get_folder_url(destination)
      name = @name unless name

      if @type == 'folder'
        response = @rest_adapter.copy_folder(
            @url,
            destination_url,
            name,
            exists: exists)
      else
        response = @rest_adapter.copy_file(
            @url,
            destination_url,
            name,
            exists: exists)
      end
      FileSystemCommon.create_item_from_hash(
          @rest_adapter,
          parent: destination_url,
          ** response)
    end

    # Delete this item
    # @note Updates this item if operation is successful
    # @note	Locally changed properties get discarded
    #
    # @param commit [Boolean] (false) set true to remove item permanently,
    #		else will be moved to trash, RestAdapter::Errors::InvalidItemError
    #   is raised for subsequent operation if commit: true
    # @param force [Boolean] (false) set true to delete non-empty folder
    # @param raise_exception [Boolean] (false)
    #		method suppresses exceptions and returns false if set to false,
    #			added so that consuming application can control behaviour
    #
    # @return [Boolean] whether operation is successful
    #
    # @raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError,
    #		RestAdapter::Errors::InvalidItemError,
    #   RestAdapter::Errors::OperationNotAllowedError]
    #
    #		if raise_exception is true
    def delete(commit: false, force: false, raise_exception: false)
      FileSystemCommon.validate_item_state(self, in_trash: false)

      if @in_trash
        # @review NOOP if commit is false since item is already in trash, return true
        if commit
          @rest_adapter.delete_trash_item(path: @url)
          @exists = false
          @in_trash = false
        end
        return true
      end

      if @type == 'folder'
        @rest_adapter.delete_folder(@url, commit: commit, force: force)
      else
        @rest_adapter.delete_file(@url, commit: commit)
      end

      if commit
        @exists = false
        @in_trash = false
      else
        @application_data[:_bitcasa_original_path] = ::File.dirname(@url)
        set_url(nil)
        @in_trash = true
      end
      changed_properties_reset
      true
    rescue RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
        RestAdapter::Errors::OperationNotAllowedError, RestAdapter::Errors::InvalidItemError
      raise $! if raise_exception
      false
    end

    # Get this item's properties from server
    # @return [Hash] metadata of this item
    # @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError]
    def get_properties_from_server
      if @in_trash
        properties = @rest_adapter.browse_trash(path: @url).fetch(:meta)
      elsif @type == 'folder'
        properties = @rest_adapter.get_folder_meta(@url)
      else
        properties = @rest_adapter.get_file_meta(@url)
      end
    end

    # Refresh this item's properties from server
    #
    #	@note	Locally changed properties get discarded
    #
    # @return [Item] returns self
    #
    # @raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError,
    #		RestAdapter::Errors::InvalidItemError,
    #   RestAdapter::Errors::OperationNotAllowedError]
    def refresh
      FileSystemCommon.validate_item_state(self, in_trash: false, in_share: false)

      properties = get_properties_from_server
      parent_url = ::File.dirname(@url)

      set_item_properties(
          parent: parent_url,
          in_trash: @in_trash,
          in_share: @in_share,
          ** properties)
      self
    end

    # Sets restored item's url and properties based on exists and destination url
    # This method is called to update this item after it has been restored.
    #		If exist == 'Fail' then this item's expected url is its original path
    #			elseif exists == 'RESCUE' the url should be destination_url/(item's trashid)
    #			elseif exists == 'RECREATE' then url should be
    #					(url of named path)/(item' trashid)
    #
    # @param destination_url [String] ('RESCUE' (default root), RECREATE(named path))
    #		path depending on exists option to place item into
    #		if the original path does not exist.
    # @param exists [String] ('FAIL', 'RESCUE', 'RECREATE')
    #		action to take if the recovery operation encounters issues, default 'FAIL'
    #
    # @raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError, RestAdapter::Errors::ArgumentError]
    def set_restored_item_properties(destination_url, exists)
      begin
        parent_url = @application_data[:_bitcasa_original_path]
        properties = FileSystemCommon.get_item_properties_from_server(
            @rest_adapter,
            parent_url,
            @id,
            @type)
      rescue
        raise $! if exists == 'FAIL'

        if exists == 'RESCUE'
          parent_url = destination_url
          properties = FileSystemCommon.get_item_properties_from_server(
              @rest_adapter,
              parent_url,
              @id,
              @type)

        elsif exists == 'RECREATE'
          response = FileSystemCommon.get_properties_of_named_path(
              @rest_adapter,
              destination_url)

          parent_url = response[:url]
          properties = FileSystemCommon.get_item_properties_from_server(
              @rest_adapter,
              parent_url,
              @id,
              @type)
        end
      end
      set_item_properties(parent: parent_url, in_trash: false, ** properties)
    end

    # Restore this item from trash
    # @note This item's properties are updated if successful
    #
    # @param destination [Folder, String] ('RESCUE' (default root),
    #		RECREATE(named path)) destination folder path depending on exists
    #		option to place item into if the original path does not exist.
    # @param exists [String] ('FAIL', 'RESCUE', 'RECREATE')
    #		action to take if the recovery operation encounters issues, default 'FAIL'
    # @param raise_exception [Boolean] (false)
    #		method suppresses exceptions and returns false if set to false,
    #			added so that consuming application can control behaviour
    #
    # @return [Boolean] true/false
    #
    # @raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError, RestAdapter::Errors::ArgumentError,
    #   RestAdapter::Errors::InvalidItemError,
    #   RestAdapter::Errors::OperationNotAllowedError] if raise_exception is true
    #
    # @note exist: 'RECREATE' with named path is expensive operation
    #		as items in named path hierarchy are traversed
    #		in order to fetch Restored item's properties.
    #
    # @example
    #		item.restore
    #		item.restore("/FOPqySw3ToK_25y-gagUfg", exists: 'RESCUE')
    #		item.restore(folderobj, exists: 'RESCUE')
    #		item.restore("/depth1/depth2", exists: 'RECREATE')
    def restore(destination: nil, exists: 'FAIL', raise_exception: false)
      fail RestAdapter::Errors::OperationNotAllowedError,
           'Item needs to be in trash for Restore operation' unless @in_trash
      FileSystemCommon.validate_item_state(destination)

      destination_url = FileSystemCommon.get_folder_url(destination)
      @rest_adapter.recover_trash_item(
          @url,
          destination: destination_url,
          restore: exists)

      set_restored_item_properties(destination_url, exists)
      true
    rescue RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
        RestAdapter::Errors::ArgumentError, RestAdapter::Errors::InvalidItemError,
        RestAdapter::Errors::OperationNotAllowedError
      raise $! if raise_exception
      false
    end

    # List versions of this item if file.
    #	@note The list of files returned are mostly non-functional,
    #		though their meta-data is correct.
    #
    # @param start_version [Fixnum] version number to begin listing file versions
    # @param stop_version [Fixnum] version number from which to stop
    #		listing file versions
    # @param limit [Fixnum] how many versions to list in the result set.
    #		It can be negative to list items prior to given start version
    #
    # @return [Array<Item>] listed versions
    #
    #	@raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError, RestAdapter::Errors::InvalidItemError,
    #   RestAdapter::Errors::OperationNotAllowedError]
    #
    #	@review confirm if versions should be allowed for items in trash, in share
    def versions(start_version: 0, stop_version: nil, limit: 10)
      FileSystemCommon.validate_item_state(self, in_trash: false, in_share: false)
      fail OperationNotAllowedError,
           "Operation not allowed for item of type #{@type}" unless @type == 'file'

      response = @rest_adapter.list_file_versions(
          @url,
          start_version: start_version,
          stop_version: stop_version,
          limit: limit)

      FileSystemCommon.create_items_from_hash_array(
          response, @rest_adapter,
          parent: @url,
          in_share: @in_share,
          in_trash: @in_trash,
          old_version: true)
    end

    # Save this item's current state.
    #		Locally changed properties are committed to this item in user's account
    #
    # @param version_conflict [String] ('FAIL', 'IGNORE') action to take
    #		if the version on this item does not match the version on the server
    #
    # @return [Item] returns self
    #
    #	@raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError, RestAdapter::Errors::ArgumentError,
    #   RestAdapter::Errors::InvalidItemError,
    #		RestAdapter::Errors::OperationNotAllowedError]
    def save(version_conflict: 'FAIL')
      FileSystemCommon.validate_item_state(self)
      return self if RestAdapter::Utils.is_blank?(@changed_properties)

      if @type == 'folder'
        response = @rest_adapter.alter_folder_meta(
            @url,
            @version,
            version_conflict: version_conflict,
            ** @changed_properties)
      else
        response = @rest_adapter.alter_file_meta(
            @url,
            @version,
            version_conflict: version_conflict,
            ** @changed_properties)
      end

      parent_url = ::File.dirname(@url)
      set_item_properties(parent: parent_url, ** response)
      self
    end

    # Gets properties in hash format
    # @return [Hash] metadata of item
    def get_properties_in_hash
      properties = {
          :'name' => "#{@name}",
          :'date_created' => "#{@date_created}",
          :'date_meta_last_modified' => "#{@date_meta_last_modified}",
          :'date_content_last_modified' => "#{@date_content_last_modified}",
          :'extension' => "#{@extension}",
          :'mime' => "#{@mime}",
          :'application_data' => @application_data
      }
      properties
    end

    # Sets the url of item
    #
    # @param parent [Folder, String]
    #
    # @return [void]
    def set_url(parent)
      parent_url = FileSystemCommon.get_folder_url(parent)
      @url = parent_url == '/' ? "/#{@id}" : "#{parent_url}/#{@id}"
    end

    #	@return [String]
    #	@!visibility private
    def to_s
      "#{self.class}: url #{@url}, name: #{@name}"
    end

    alias inspect to_s

    #	@return [Boolean]
    #	@!visibility private
    def eql?(item)
      self.class.equal?(item.class) &&
          item.respond_to?(:id) &&
          item.id == @id
    end

    # Changes the attributes of a given file or folder.
    #
    # @param values [Hash] attribute changes.
    # @param if_conflict [String] ('FAIL', 'IGNORE') action to take
    #		if the version on this item does not match the version on the server.
    #
    #	@return [Boolean] based on the success or fail status of the action.
    def change_attributes(values, if_conflict: 'FAIL')
      if @type == 'folder'
        response = @rest_adapter.alter_folder_meta(
            @url,
            @version,
            version_conflict: if_conflict,
            ** values)
      else
        response = @rest_adapter.alter_file_meta(
            @url,
            @version,
            version_conflict: if_conflict,
            ** values)
      end

      parent_url = ::File.dirname(@url)
      set_item_properties(parent: parent_url, ** response)
      response.has_key?(:id)
    end

    alias == eql?
    private :set_item_properties, :changed_properties_reset,
            :set_restored_item_properties, :get_properties_in_hash, :set_url,
            :get_properties_from_server
  end
end
