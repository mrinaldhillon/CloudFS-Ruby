require_relative 'item'
require_relative 'client'
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
		
		# @see Item#initialize
		def initialize(client, parent: nil, in_trash: false, 
				in_share: false, old_version: false, **properties)
			fail Client::Errors::ArgumentError, 
		 	"Invalid item of type #{properties[:type]}" unless properties[:type] == "file"

			@offset = 0
			super
		end
		
		# Download this file to local directory
		#
		# @param local_path [String] path of local folder
		# @param filename [String] name of downloaded file, default is name of this file
		#
		#	@return [true]
		#
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::ArgumentError, Client::Errors::InvalidItemError, 
		#		Client::Errors::OperationNotAllowedError]
		# @review overwrites a file if it exists at local path
		#	@note Internally uses chunked stream download, 
		#		max size of in-memory chunk is 16KB.
		def download(local_path, filename: nil)
			fail Client::Errors::ArgumentError, 
				"local path is not a valid directory" unless ::File.directory?(local_path)
			FileSystemCommon.validate_item_state(self)

			filename ||= @name
			if local_path[-1] == '/'
				local_filepath = "#{local_path}#{filename}"
			else
				local_filepath = "#{local_path}/#{filename}"
			end
			::File.open(local_filepath, 'wb') do |file|
				@client.download(@url) { |buffer| file.write(buffer) }
			end
			true
		end

		# Read from file to buffer
		#
		#	@param bytecount [Fixnum] number of bytes to read from current access position 
		# @return [String] buffer
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError]
		def read_to_buffer(bytecount)
			buffer = @client.download(@url, startbyte: @offset, bytecount: bytecount)
			@offset += buffer.nil? ? 0 : buffer.size
			buffer
		end

		# Read from file to proc
		#
		#	@param bytecount [Fixnum] number of bytes to read from current access position 
		# @yield [String] chunk of data as soon as available, 
		#		chunksize size may vary each time
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError]
		def read_to_proc(bytecount, &block)
			@client.download(@url, startbyte: @offset, bytecount: bytecount) do |chunk|
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
		# @raise [Client::Errors::SessionNotLinked, Client::Errors::ServiceError, 
		#		Client::Errors::ArgumentError, Client::Errors::InvalidItemError, 
		#		Client::Errors::OperationNotAllowedError]
		#
		#	@note	Pass block to stream chunks as soon as available, 
		#		preferable for large reads.
		def read(bytecount: nil, &block)
			fail Client::Errors::ArgumentError, 
				"Negative length given - #{bytecount}" if bytecount && bytecount < 0
			FileSystemCommon.validate_item_state(self)
	
			if bytecount == 0 || @offset >= @size
				return yield "" if block_given?
				return ""
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
		# @raise [Client::Errors::ArgumentError]
		def seek(offset, whence: 0)
			
			case whence
			when 0 
				@offset = offset if whence == 0
			when 1
				@offset += offset if whence == 1
			when 2
				@offset = @size + offset if whence == 2
			else
				fail Client::Errors::ArgumentError, 
					"Invalid value of whence, should be 0 or IO::SEEK_SET, 1 or IO::SEEK_CUR, 2 or IO::SEEK_END"
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
