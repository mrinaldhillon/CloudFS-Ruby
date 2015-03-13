# Bitcasa SDK for Ruby

The **Bitcasa SDK for Ruby** enables Ruby developers to easily work with [Bitcasa Cloud Storage Platform](https://www.bitcasa.com/) and build scalable solutions.

* [REST API Documentation](https://www.bitcasa.com/cloudfs-api-docs/)
* [Blog](http://blog.bitcasa.com/)

##	Not Supported

*	Cannot set application_data and properties on files or folders at creation time.

##	Installation

	$ gem install cloudfs

## Using the SDK

```ruby
# in Gemfile
    gem 'cloudfs'

# in application
    require 'cloudfs'
```

Use the credentials you obtained from Bitcasa admin console to create a client session. This session can be used for all future requests to Bitcasa.

```ruby
session = CloudFS::Session.new(clientid, secret, host)
session.authenticate(username, password)
```

Getting the root folder

```ruby
Folder root = session.filesystem.root
```

Getting the contents of root folder

```ruby
items = session.filesystem.list(item: item)	
```

or

```ruby
itemArray = session.fileSystem.list(root);
```

Deleting the contents of root folder

```ruby
//code
```

Uploading a file to root folder

```ruby
//code
```

Download a file from root folder

```ruby
//code
```

Create user (for paid accounts only)

```ruby
account = create_account(session, user, password)
```

##	Debug
*	In order to log http wire trace initialize session with http_debug option 
	with an object that responds to #<<. For example STDERR, STDOUT, File etc.

```ruby
session = CloudFS::Session.new(clientid, secret, host, http_debug: STDERR)
```

We would love to hear what features or functionality you're interested in, or general comments on the SDK (good and bad - especially bad).