require_relative 'rest_adapter'
require_relative 'folder'
require_relative 'filesystem_common'

module CloudFS
  # FileSystem class provides interface to maintain cloudfs user's filesystem
  #
  # @author Mrinal Dhillon
  class FileSystem

    # Get root object of filesystem
    #
    # @return [Folder] represents root folder of filesystem
    #
    # @raise RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError
    def root
      response = @rest_adapter.get_folder_meta('/')
      FileSystemCommon.create_item_from_hash(@rest_adapter, ** response)
    end

    # @param rest_adapter [RestAdapter] cloudfs RESTful api object
    #
    # @raise [RestAdapter::Errors::ArgumentError]
    def initialize(rest_adapter)
      fail RestAdapter::Errors::ArgumentError,
           'invalid RestAdapter, input type must be RestAdapter' unless rest_adapter.is_a?(RestAdapter)
      @rest_adapter = rest_adapter
    end

    # @return [Array<File, Folder>] items in trash
    #
    # @raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError, RestAdapter::Errors::InvalidItemError,
    #   RestAdapter::Errors::OperationNotAllowedError]
    def list_trash
      response = @rest_adapter.browse_trash.fetch(:items)
      FileSystemCommon.create_items_from_hash_array(
          response,
          @rest_adapter,
          in_trash: true)
    end

    # List shares created by end-user
    # @return [Array<Share>] shares
    #
    # @raise [RestAdapter::Errors::SessionNotLinked,
    # RestAdapter::Errors::ServiceError]
    def list_shares
      response = @rest_adapter.list_shares
      FileSystemCommon.create_items_from_hash_array(response, @rest_adapter)
    end

    # Create share of paths in user's filesystem
    #
    # @param paths [Array<File, Folder, String>] file, folder or url
    # @param password [String] password.
    #
    # @return [Share] instance
    #
    # @raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError, RestAdapter::Errors::ArgumentError,
    #   RestAdapter::Errors::InvalidItemError,
    #   RestAdapter::Errors::OperationNotAllowedError]
    def create_share(paths, password: nil)
      fail RestAdapter::Errors::ArgumentError,
           'Invalid input, expected items or paths' unless paths

      path_list = []
      [*paths].each do |path|
        FileSystemCommon.validate_item_state(path)
        path_list << FileSystemCommon.get_item_url(path)
      end

      response = @rest_adapter.create_share(path_list, password: password)
      FileSystemCommon.create_item_from_hash(@rest_adapter, ** response)
    end

    # Fetches share associated with share key.
    #
    #	@param share_key [String] valid share key
    #	@param password [String] password if share is locked
    #
    #	@return [Share] instance of share
    # @raise [RestAdapter::Errors::SessionNotLinked,
    #   RestAdapter::Errors::ServiceError, RestAdapter::Errors::ArgumentError]
    #
    #	@note	This method is intended for retrieving share from another user
    def retrieve_share(share_key, password: nil)
      fail RestAdapter::Errors::ArgumentError,
           'Invalid input, expected items or paths' if RestAdapter::Utils.is_blank?(share_key)

      @rest_adapter.unlock_share(share_key, password) if password
      response = @rest_adapter.browse_share(share_key).fetch(:share)
      FileSystemCommon.create_item_from_hash(@rest_adapter, ** response)
    end

    # Get an item located in a given location.
    def get_item(path)
      fail RestAdapter::Errors::ArgumentError,
           'Invalid input, expected item path' if RestAdapter::Utils.is_blank?(path)

      if path.is_a?(String)
        FileSystemCommon.get_item(@rest_adapter, path)
      else
        nil
      end
    end

  end
end
