#CloudFS Ruby SDK user guide 

##API Refference 
Refer the [Rubydoc](CloudFS.html) Documentation to view	class and method details.

##Getting the SDK

You can download the SDk from Github.

```bash
git clone https://github.com/bitcasa/CloudFS-Ruby
```

##Using the SDK
If you don't have a CloudFS API account, [register](https://www.bitcasa.com/) to gain access.

###Creating and linking the CloudFS Sessions

Sessions represent connections to CloudFS. They use a set of credentials that consists of an end point URL, a client ID and a client secret. These credentials can be obtained via the Bitcasa admin console.

[Session](CloudFS/Session.html) - Performs regular file system operations.

```ruby
session = CloudFS::Session.new(end_point, client_id, client_secret)
```

A user can be linked to the session by authenticating using a username and a password.

```ruby
session.authenticate(username, password)
```

You can assert whether a user is linked to the session.

```ruby
session.is_linked?
```

The currently linked user can be unlinked from the session.

```ruby
session.unlink
```

**Note:**

+  Only one user can be linked to a session at a time.


###Admin Operations

**Note:**
You need to create an admin session in order to perform admin operations.

+ [Create Account](CloudFS/Session.html#create_account-instance_method)

You can create end users for an admin/paid account.

```ruby
account = create_account(username, password, email, first_name, last_name, log_in_to_created_user)
```

###File System Operations
**Note:** You need to create a session in order to perform file system operations.


+ [Get Root Folder](CloudFS/FileSystem.html#root-instance_method)	

	```ruby
	root = session.filesystem.root
	```

+ [Get Specific Folder](CloudFS/FileSystem.html#get_item-instance_method)
	
	```ruby
	folder = session.filesystem.get_item('folder_path')
	```  

+ [Get Specific File](CloudFS/FileSystem.html#get_item-instance_method)
	
	```ruby
	file = session.filesystem.get_item('file_path')
	```

+ [Get Trash Items](CloudFS/FileSystem.html#list_trash-instance_method)

You can list down the contents of a folder. Below example shows how to retrieve contents of the root folder.

```ruby
items = session.filesystem.list_trash(item: item)
```

+ [Get Shares](CloudFS/FileSystem.html#list_shares-instance_method)
  
You can list down available shares. Below example shows how to retrieve the list of shares.

```ruby
items = session.filesystem.list_shares(item: item)
```

+ [Create Share](CloudFS/FileSystem.html#create_share-instance_method)

You can create a share by providing the path as shown in below example. A passworded share cannot be used for anything if the password is not provided. It doesn’t make sense to create a share unless the developer has the password.

```ruby
share = session.filesystem.create_share('file_path/folder_path', 'new_share_password')
```

###Folder Operations

**Note:** You need to create a session in order to perform folder operations.

+ [List Folder Contents](CloudFS/Container.html#list-instance_method)

You can list the contents of a folder. This will return a list of top level folders and items in the specified folder.

```ruby
items = folder.list(item: item)
```

+ [Change Folder Attributes](CloudFS/Item.html#change_attributes-instance_method)

You can change the attributes of a Folder by providing a hash map of field names and values. An example is given below.

```ruby
folder_attributes = Hash.new
folder_attributes[:name] = 'changed_folder_name'
folder.change_attributes(** folder_attributes)
```

+ [Copy Folder](CloudFS/Item.html#copy_to-instance_method)

You can copy a folder to a new location in the file system. If the destination conflicts with the copying folder you can either RENAME, OVERWRITE, REUSE or FAIL the operation.

```ruby
copy_folder.copy copy_target.path
```

+ [Move Folder](CloudFS/Item.html#move-instance_method)

You can move a folder to a new location in the file system. If the destination conflicts with the moving folder you can either RENAME, OVERWRITE or FAIL the operation.

```ruby
move_source.move move_target.path
```
+ [Delete Folder](CloudFS/Item.html#delete-instance_method)

You can perform the delete operation on a folder. This will return the Success/fail status of the operation.

```ruby
status = folder.delete
```

+ [Restore Folder](CloudFS/Item.html#restore-instance_method)

You can restore a folder from the trash. This will return the Success/fail status of the operation.

```ruby
  delete_folder.restore destination: delete_folder.path
```

+ [Create Sub Folder](CloudFS/Container.html#create_folder-instance_method)

You can create a sub folder in a specific folder. If the folder already has a sub folder with the given name, the operation will fail.

```ruby
folder.create_folder 'test_folder' 
```

+ [Upload File](CloudFS/Folder.html#upload-instance_method)

You can upload a file from your local file system into a specific folder. If the destination conflicts, you can either RENAME, OVERWRITE, REUSE or FAIL the operation.

```ruby
file = folder.upload file_path
```

###File Operations

**Note:** You need to create a session in order to perform file operations.

+ [Change File Attributes](CloudFS/Item.html#change_attributes-instance_method)

You can change the attributes of a File by providing a hash map of field names and values. An example is given below.

```ruby
file_attributes = Hash.new
file_attributes[:name] = 'changed_file_name'
file.change_attributes(** file_attributes)
```

+ [Copy File](CloudFS/Item.html#copy-instance_method)

You can copy a file to a new location in the file system. If the destination conflicts with the copying file you can either RENAME, OVERWRITE, REUSE or FAIL the operation.

```ruby
file.copy('destination_path', exists: 'OVERWRITE')
```

+ [Move File](CloudFS/Item.html#move-instance_method)

You can move a file to a new location in the file system. If the destination conflicts with the moving file you can either RENAME, OVERWRITE, REUSE or FAIL the operation.

```ruby
file.move('destination_path', exists: 'OVERWRITE')
```

+ [Delete File](CloudFS/Item.html#delete-instance_method)

You can perform the delete operation on a file. This will return the Success/fail status of the operation.

```ruby
file.delete
```

+ [Restore File](CloudFS/Item.html#restore-instance_method)

You can restore a file from the trash. he restore method can be set to either FAIL, RESCUE or RECREATE. This will return the Success/fail status of the operation.

```ruby
file.restore('destination_path', exists: 'OVERWRITE')
```

+ [Download File](CloudFS/File.html#download-instance_method)

You can download a file to your local file system.

```ruby
file.download local_file_path
```


+ [Get File Versions](CloudFS/Item.html#versions-instance_method)

You can retrieve the versions of a specific file.

```ruby
file_version = file.version
```

###Share Operations

**Note:**  You need to create a session in order to perform share operations.

+ [Delete Share](CloudFS/Share.html#delete-instance_method)

```ruby
share_file.delete
```

+ [Set Share Password](CloudFS/Share.html#set_password-instance_method)

Sets the share password. Old password is only needed if one exists.

```ruby
share_file.set_password 'share_password'
```