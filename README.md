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
itemArray = session.fileSystem.list(root);
```

Delete a file or folder

```ruby
item.delete
```

Uploading a file to a folder

```ruby
file = folder.upload(file_path)
```

Download a file from a folder

```ruby
file = session.filesystem.get_item('file_path')
file.download local_file_path
```

Create user (for paid accounts only)

```ruby
account = create_account(session, user, password)
```

##	Debug

*	In order to log http wire trace initialize session with http_debug option with an object that responds to #<<. For example STDERR, STDOUT, File etc.

```ruby
session = CloudFS::Session.new(clientid, secret, host, http_debug: STDERR)
```

## Running the Tests

Before running the tests, you should add the API credentials found in your CloudFS account to the file \spec\configurationrb

To execute the tests go the directory \spec and run:

```ruby
rake test
```

We would love to hear what features or functionality you're interested in, or general comments on the SDK (good and bad - especially bad).