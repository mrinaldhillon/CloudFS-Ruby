require_relative 'file.rb'
module CloudFS
	
	#	@review Not creating file objects based on mime type, 
	#		since save operation cannot update the class of file object, 
	#		if mime is changed
	# Photo class initializes the type of the file, not used currently
	class Photo < File; end

	#	@review Not creating file objects based on mime type, 
	#		since save operation cannot update the class of file object, 
	#		if mime is changed
	# Video class initializes the type of the file, not used currently
	class Video < File; end

	#	@review Not creating file objects based on mime type, 
	#		since save operation cannot update the class of file object, 
	#		if mime is changed
	# Audio class initializes the type of the file, not used currently
	class Audio < File; end

	#	@review Not creating file objects based on mime type, 
	#		since save operation cannot update the class of file object, 
	#		if mime is changed
	# Document class initializes the type of the file, not used currently
	class Document < File; end

end
