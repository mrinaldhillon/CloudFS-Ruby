# Bitcasa SDK for Ruby

The **Bitcasa SDK for Ruby** enables Ruby developers to easily work with [Bitcasa 
Cloud Storage Platform](https://www.bitcasa.com/) and build scalable solutions.

* [REST API Documentation](https://www.bitcasa.com/cloudfs-api-docs/)
* [Blog](http://blog.bitcasa.com/)

* Supports current set of CloudFS rest apis except following features.

##	Not Supported
*	File upload does not support reuse exists option.
*	Cannot set application_data and properties on files or folders at creation time.

##	Installation

	$ gem install cloudfs_sdk

## Using the SDK

Use the credentials you obtained from Bitcasa admin console to create a client session. This session can be used for all future requests to Bitcasa.

```ruby
session = CloudFS::Session.new(clientid, secret, host)
session.authenticate(username, password)
```

Getting the root folder

```ruby
//Folder root = session.getFileSystem().getRoot();
```

Getting the contents of root folder

```ruby
//Item[] itemArray = session.getFileSystem().list("");
```
or
```ruby
//Item[] itemArray = session.getFileSystem().list(root);
```

Deleting the contents of root folder

```ruby
//session.getFileSystem().delete(itemArray);
```

Uploading a file to root folder

```ruby
//root.upload(pathOfFile, Exists.FAIL, listener);
```

Download a file from root folder

```ruby
//File fileToDownload = session.getFileSystem().getFile(pathOfFileToDownload);
//fileToDownload.download(localDestinationPath, listener);
```

Create user (for paid accounts only)

```ruby
//AdminSession adminSession = new AdminSession(adminEndPoint, adminClientId, adminClientSecret);
//Profile profile = adminSession.admin().createAccount(username, password, email, firstName, lastName);
```

##	Debug
*	In order to log http wire trace initialize session with http_debug option 
	with an object that responds to #<<. For example STDERR, STDOUT, File etc.

```ruby
session = CloudFS::Session.new(clientid, secret, host, http_debug: STDERR)
```

We would love to hear what features or functionality you're interested in, or general comments on the SDK (good and bad - especially bad).