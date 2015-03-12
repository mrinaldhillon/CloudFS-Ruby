#CloudFS Ruby SDK user guide 

##API Refference 
Refer the [Rubydoc]() Documentation to view	class and method details.

##Getting the SDK

You can get the SDK either by downloading the compiled version or by downloading the compiled version or by building the project from source. 

###Download the compiled version


###Build the project from source
You can download the project from our repository and build it. 

To checkout the latest source code: 

```bash
git clone https://github.com/bitcasa/CloudFS-Ruby
```

To build the project:

```bash
mvn -Dmaven.test.skip=true install
```

##Using the SDK
If you don't have a CloudFS API account, [register](https://www.bitcasa.com/) to gain access.

###Creating and linking the CloudFS Sessions

Sessions represent connections to CloudFS. They use a set of credentials that consists of an end point URL, a client ID and a client secret. These credentials can be obtained via the Bitcasa admin console.

There are two types of sessions,

* [AdminSession]() - Performs administrative operations such as user and account management.

	```
	//code
```

* [Session]() - Performs regular file system operations.

A user can be linked to the session by authenticating using a username and a password.

```
session.authenticate(username, password)
```

You can assert whether a user is linked to the session.

```
session.is_linked?
```

The currently linked user can be unlinked from the session.

```
session.unlink
```



**Note:**

+  Performing actions on an unlinked session will produce an [AuthenticationException]()
+  Only one user can be linked to a session at a time.


###Admin Operations

**Note:**
You need to create an admin session in order to perform admin operations.

+ [Create Account](CloudFS/Client.html#create_account-instance_method)



You can create end users for an admin/paid account.

```
//code
```
###File System Operations
**Note:** You need to create a session in order to perform file system operations.

+ [Get items]()
	+ [Get Root Folder]()	

	```
	Folder root=-session.filesystem.root
	```
	+ [Get Specific Folder]()
	
	```
	Folder folder= //code
	```  
	+ [Get Specific File]()
	
	```
	//code
	```
+ [List Items]()

You can list down the contents of a Folder. Below example shows two approaches to retrieve contents of the root folder.

```
//code
```

+ [Copy Items]()

You can copy a list of items to a new location in the file system. If the contents in the destination folder conflicts with the copying items you can either RENAME, OVERWRITE, REUSE or FAIL the operation.

```
//code
```

+ [Move Items]()

You can move a list of items to a new location in the file system. If the contents in the destination folder conflicts with the moving items you can either RENAME, OVERWRITE, REUSE or FAIL the operation. 

```
//code
```

+ [Delete Items]()

 You can specify a list of items that needs to be deleted. This will return a list of Success/fail status of each item once the operation completes.

```
//code
```

+ [Restore Items]()

You can specify a list of items that needs to be restored from the trash. The restore options can be set to either FAIL, RESCUE or RECREATE. This will return a list of Success/fail statuses of items once the operation completes.

```
//code
```

+ [Change Item Meta Data]()

You can change meta data of items. Below example demonstrates changing of a file name and saving in the file system. You can either FAIL or IGNORE if the version already exists.

```
//code
```

+ [Retrieve File History]()

You can retrieve the versions of a specific item.

```
//code
```


###Folder Operations
**Note:** You need to create a session in order to perform folder operations.

+ [List Folder Contents]()

You can list the contents of a folder. This will return a list of top level folders and items in the specified folder.

```
//code
```

+ [Copy Folder]()

You can copy a folder to a new location in the file system. If the destination conflicts with the copying folder you can either RENAME, OVERWRITE, REUSE or FAIL the operation.

```
//code
```

+ [Delete Folder]()

You can perform the delete operation on a folder. This will return the Success/fail status of the operation.

```
//code
```

+ [Restore Folder]()

You can restore a folder from the trash. This will return the Success/fail status of the operation.

```
//code
```

+ [Create Sub Folder]()

You can create a sub folder in a specific folder. If the folder already has a sub folder with the given name, the operation will fail.

```
//code
```

+ [Upload File]()

You can upload a file from your local file system into a specific folder. If the destination conflicts, you can either RENAME, OVERWRITE, REUSE or FAIL the operation.

```
//code
```
###File Operations

**Note:** You need to create a session in order to perform file operations.

+ [Copy File]()

You can copy a file to a new location in the file system. If the destination conflicts with the copying file you can either RENAME, OVERWRITE, REUSE or FAIL the operation.

```
//code
```

+ [Move File]()

You can move a file to a new location in the file system. If the destination conflicts with the moving file you can either RENAME, OVERWRITE, REUSE or FAIL the operation.

```
//code
```

+ [Delete File]()

You can perform the delete operation on a file. This will return the Success/fail status of the operation.

```
//code
```

+ [Restore File]()

You can restore a file from the trash. This will return the Success/fail status of the operation.

```
//code
```

+ [Get File History]()

You can retrieve the versions of a specific file.

```
//code
```

+ [Download File]()

You can download a file to your local file system.

```
//code
```

+ [Read File]()

You can read the contents of a file to an Input Stream.


```
//code
```


###Trash Operations

**Note:** You need to create a session in order to perform trash operations.

+ Browse Trash
	+	[Get Files in Trash]()


		```
		//code
		```
	+	[Get Folders in Trash]()

		```
	//code
		```
+ [Empty Trash]()

	```
	//code
	```


	
###Share Operations

**Note:**  You need to create a session in order to perform share operations.

+ [Delete Share]()

	```
	//code
	```
+ [Browse Share]()

	```
//code
	```

+ [Lock Share]()

```
//code
```

+ [Unlock Share](aaaa)

```
//code
```