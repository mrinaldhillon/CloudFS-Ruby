require_relative 'item'
require_relative 'rest_adapter'
require_relative 'filesystem_common'

module CloudFS
  # File class is aimed to provide native File object like interface
  #		to cloudfs files
  #
  # @author Mrinal Dhillon
  # @example
  #		file = session.filesystem.root.upload(local_file_path)
  #		file.seek(4, IO::SEEK_SET) #=> 4
  #		file.tell #=> 4
  #		file.read #=> " is some buffer till end of file"
  #		file.rewind
  #		file.read {|chunk| puts chunk} #=> "this is some buffer till end of file"
  # 	file.download(local_folder_path, filename: new_name_of_downloaded_file)
  class File < Item

    # @return [String] the size.
    attr_reader :size

    # @return [String] the extension.
    attr_reader :extension

    # @return [String] the mime type of file
    attr_reader :mime

    # Sets the mime type of the item and updates to CloudFS
    def mime=(value)
      fail RestAdapter::Errors::ArgumentError,
           'Invalid input, expected new mime' if RestAdapter::Utils.is_blank?(value)

      @mime = value
      @changed_properties[:mime] = value
      change_attributes(@changed_properties)
    end

    # @see #extension
    def extension=(value)
      FileSystemCommon.validate_item_state(self)
      @extension = value
      @changed_properties[:extension] = value
    end

    # @see Item#initialize
    def initialize(rest_adapter, parent: nil, parent_state: nil, in_trash: false,
                   in_share: false, old_version: false, ** properties)
      fail RestAdapter::Errors::ArgumentError,
           "Invalid item of type #{properties[:type]}" unless properties[:type] == 'file'

      @offset = 0
      super
    end

    # Download this file to local directory
    #
    # @param local_destination_path [String] path of local folder
    # @param filename [String] name of downloaded file, default is name of this file
    # @yield [Integer] download progress.
    #
    #	@return [true]
    #
    # @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
    #		RestAdapter::Errors::ArgumentError, RestAdapter::Errors::InvalidItemError,
    #		RestAdapter::Errors::OperationNotAllowedError]
    # @review overwrites a file if it exists at local path
    #	@note Internally uses chunked stream download,
    #		max size of in-memory chunk is 16KB.
    def download(local_destination_path, filename: nil, &block)
      fail RestAdapter::Errors::ArgumentError,
           'local path is not a valid directory' unless ::File.directory?(local_destination_path)
      FileSystemCommon.validate_item_state(self)

      filename ||= @name
      if local_destination_path[-1] == '/'
        local_filepath = "#{local_destination_path}#{filename}"
      else
        local_filepath = "#{local_destination_path}/#{filename}"
      end
      ::File.open(local_filepath, 'wb') do |file|
        downloaded = 0
        @rest_adapter.download(@url) do |buffer|
          downloaded += buffer.size
          file.write(buffer)
          yield @size, downloaded if block_given?
        end
      end
      true
    end

    # Get the download URL of the file.
    # @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
    #		RestAdapter::Errors::ArgumentError, RestAdapter::Errors::InvalidItemError,
    #		RestAdapter::Errors::OperationNotAllowedError]
    # @return [String] download URL of the file.
    def download_url
      url = @rest_adapter.download_url(@url)
      URI.extract(url).first.chomp(';')
    end


    # Read from file to buffer
    #
    #	@param bytecount [Fixnum] number of bytes to read from current access position
    # @return [String] buffer
    # @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError]
    def read_to_buffer(bytecount)
      buffer = @rest_adapter.download(@url, startbyte: @offset, bytecount: bytecount)
      @offset += buffer.nil? ? 0 : buffer.size
      buffer
    end

    # Read from file to proc
    #
    #	@param bytecount [Fixnum] number of bytes to read from current access position
    # @yield [String] chunk of data as soon as available,
    #		chunksize size may vary each time
    # @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError]
    def read_to_proc(bytecount, &block)
      @rest_adapter.download(@url, startbyte: @offset, bytecount: bytecount) do |chunk|
        @offset += chunk.nil? ? 0 : chunk.size
        yield chunk
      end
    end

    # Read from file
    #
    #	@param bytecount [Fixnum] number of bytes to read from
    #		current access position, default reads upto end of file
    #
    # @yield [String] chunk data as soon as available,
    #		chunksize size may vary each time
    # @return [String] buffer, unless block is given
    # @raise [RestAdapter::Errors::SessionNotLinked, RestAdapter::Errors::ServiceError,
    #		RestAdapter::Errors::ArgumentError, RestAdapter::Errors::InvalidItemError,
    #		RestAdapter::Errors::OperationNotAllowedError]
    #
    #	@note	Pass block to stream chunks as soon as available,
    #		preferable for large reads.
    def read(bytecount: nil, &block)
      fail RestAdapter::Errors::ArgumentError,
           "Negative length given - #{bytecount}" if bytecount && bytecount < 0
      FileSystemCommon.validate_item_state(self)

      if bytecount == 0 || @offset >= @size
        return yield '' if block_given?
        return ''
      end

      # read till end of file if no bytecount is given
      # 	or offset + bytecount  > size of file
      bytecount = @size - @offset if bytecount.nil? || (@offset + bytecount > @size)

      if block_given?
        read_to_proc(bytecount, &block)
      else
        read_to_buffer(bytecount)
      end
    end

    #	Reset position indicator
    def rewind
      @offset = 0
    end

    # Return current access position in this file
    # @return [Fixnum] current position in file
    def tell
      @offset
    end

    # Seek to a particular byte in this file
    # @param offset [Fixnum] offset in this file to seek to
    # @param whence [Fixnum] defaults 0,
    #		If whence is 0 file offset shall be set to offset bytes
    #		If whence is 1, the file offset shall be set to its
    #			current location plus offset
    #		If whence is 2, the file offset shall be set to the size of
    #			the file plus offset
    # @return [Fixnum] resulting offset
    # @raise [RestAdapter::Errors::ArgumentError]
    def seek(offset, whence: 0)

      case whence
        when 0
          @offset = offset if whence == 0
        when 1
          @offset += offset if whence == 1
        when 2
          @offset = @size + offset if whence == 2
        else
          fail RestAdapter::Errors::ArgumentError,
               'Invalid value of whence, should be 0 or IO::SEEK_SET, 1 or IO::SEEK_CUR, 2 or IO::SEEK_END'
      end

      @offset
    end

    #	@return [String]
    #	@!visibility private
    def to_s
      "#{self.class}: url #{@url}, name: #{@name}, mime: #{@mime}, version: #{@version}, size: #{@size} bytes"
    end

    alias inspect to_s
    private :read_to_buffer, :read_to_proc
  end
end
