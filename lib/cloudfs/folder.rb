require_relative 'container'
require_relative 'filesystem_common'


module CloudFS
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
    # @param file_system_path [String, #read&#pos&#pos=] local file path, in-memory string,
    #		an io object for example StringIO, File, Tempfile.
    # @param name [String] default: nil, name of uploaded file, must be set
    #		if file_system_path does not respond to #path unless file_system_path is local file path
    # @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME')
    #		action to take in case of a conflict with an existing folder.
    #	@param upload_io [Boolean] default: false,
    #		if set to false, file_system_path is considered to be a local file path
    #
    # @return [File] instance reference to uploaded file
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
    def upload(file_system_path, name: nil, exists: 'FAIL', upload_io: false)
      FileSystemCommon.validate_item_state(self)
      fail RestAdapter::Errors::ArgumentError,
           'Invalid input, expected file system path.' if RestAdapter::Utils.is_blank?(file_system_path)

      if upload_io == false
        response = ::File.open(file_system_path, 'r') do |file|
          @rest_adapter.upload(@url, file, name: name, exists: exists)
        end
      else
        response = @rest_adapter.upload(@url, file_system_path, name: name, exists: exists)
      end
      FileSystemCommon.create_item_from_hash(@rest_adapter,
                                             parent: @url, ** response)
    end

    # Create folder under this container
    #
    # @param name [String] name of folder to be created
    # @param exists [String] ('FAIL', 'OVERWRITE', 'RENAME') action to take
    #		if the item already exists
    #
    # @return [Folder] instance
    # @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
    #		RestAdapter::Errors::ArgumentError, RestAdapter::Errors::InvalidItemError,
    #		RestAdapter::Errors::OperationNotAllowedError]
    def create_folder(name, exists: 'FAIL')
      FileSystemCommon.validate_item_state(self)
      fail RestAdapter::Errors::ArgumentError,
           'Invalid argument, must pass name' if RestAdapter::Utils.is_blank?(name)

      properties = @rest_adapter.create_folder(name, path: @url, exists: exists)
      FileSystemCommon.create_item_from_hash(@rest_adapter, parent: @url, ** properties)
    end

    #	@return [String]
    #	@!visibility private
    def to_s
      "#{self.class}: url #{@url}, name: #{@name}"
    end

    alias inspect to_s
    # overriding inherited properties that are not not valid for folder
    private :blocklist_key, :blocklist_id, :versions, :old_version?
  end
end
