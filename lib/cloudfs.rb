require_relative 'cloudfs/version'
require_relative 'cloudfs/rest_adapter'
require_relative 'cloudfs/user'
require_relative 'cloudfs/account'
require_relative 'cloudfs/session'
require_relative 'cloudfs/item'
require_relative 'cloudfs/filesystem'
require_relative 'cloudfs/file'
require_relative 'cloudfs/container'
require_relative 'cloudfs/folder'
require_relative 'cloudfs/share'
require_relative 'cloudfs/media'

# This module enables application to consume Bitcasa CloudFS storage service 
#	by creating authenticated RESTful interfaces to filesystem objects 
#	in end-user's CloudFS account.
module CloudFS
end
