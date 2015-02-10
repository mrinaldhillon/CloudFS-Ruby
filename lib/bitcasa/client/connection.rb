require 'httpclient'
require_relative 'utils'
require_relative 'error'

module Bitcasa
	class Client
		# Provides RESTful interface
		#	
		# @author Mrinal Dhillon
		# Maintains a persistent instance of class HTTPClient, 
		#		since HTTPClient instance is MT-safe and can be called from 
		#		several threads without synchronization after setting up an instance, 
		#		same behaviour is expected from Connection class.	
		#	
		# @see http://www.rubydoc.info/gems/httpclient
		#		
		# @example
		#		conn = Connection.new
		# 	response = conn.request('GET', "https://www.example.com", 
		#			:query => { :a => "b", :c => "d" }) 
		# 	response = conn.request('POST', "https://www.example.com", :body => "a=b&c=d")
		# 	response = conn.request('POST', "https://www.example.com", 
		#			:body => { :a => "b", :c => "d"} )
		class Connection
      # Creates Connection instance
			#
			# @param params [Hash] connection configurations 
			# @option params [Fixnum] :connect_timeout (60) for server handshake, 
			#			defualts to 60 as per httpclient documentation
			# @option params [Fixnum] :send_timeout (120) for send request, 
			#			defaults to 120 sec as per httpclient documentation, set 0 for no timeout
			# @option params [Fixnum] :receive_timeout (60) timeout for read per block, 
			#			defaults to 60 sec as per httpclient documentation, set 0 for no timeout
			# @option params [Fixnum] :max_retry (0) for http 500 level errors
			#	@option params [String] :agent_name (HTTPClient)
			# @option params [#<<] :debug_dev (nil) provide http wire information 
			#		from httpclient
			def initialize(**params)
				@persistent_conn = HTTPClient.new
				@persistent_conn.cookie_manager = nil

				connect_timeout, send_timeout, receive_timeout, 
				max_retries, debug_dev, agent_name	= 
						params.values_at(:connect_timeout, :send_timeout, :receive_timeout, 
								:max_retries, :debug_dev, :agent_name)
				@persistent_conn.connect_timeout = connect_timeout if connect_timeout
				@persistent_conn.send_timeout = send_timeout if send_timeout
				@persistent_conn.receive_timeout = receive_timeout if receive_timeout
				@persistent_conn.debug_dev = debug_dev if debug_dev.respond_to?(:<<)
				@persistent_conn.agent_name = agent_name
				@max_retries = max_retries ? max_retries : 0
			end
		
			# Disconnects all keep alive connections and intenal sessions
			def unlink
				@persistent_conn.reset_all
			end

			# Sends request to specified url,
			#		calls HTTPClient#request, retries http 500 level errors with 
			#			exponetial delay upto max retries
			#
			# @param method [Symbol] (:get, :put, :post, :delete) http verb
			# @param uri [String, URI] represents complete url to web resource
			#	@param params [Hash] http request parameters i.e. :headers, :query, :body 
			# @option params [Hash] :header http request headers
			# @option params [Hash] :query part of url -	
			#		"https://host/path?key=value&key1=value1"
			# @option params [Array<Hash>, Hash, String] :body {} to post multipart forms,  
			#			key:value forms, string
			#
			# @return [Hash] response hash containing content, conten_type and http code
			#			{ :content => String, :content_type => String, :code => Fixnum }
			# @raise [Errors::ClientError, Errors::ServerError]
			# 		ClientError wraps httpclient exceptions 
			#				i.e. timeout, connection failed etc.
			#			ServerError contains error message and code from server
			# @optimize async request support
			#
			# @review Behaviour in case of error with follow_redirect set to true 
			#		with callback block for get: observed is that if server return 
			#		message as response body in case of error, message is discarded 
			#		and unable to fetch it. Opened issue#234 on nahi/httpclient github.
			#		Currently fetching HTTP::Message#reason if HTTP::Message#content 
			#			is not available in such case
			# @review exceptions raised by HTTPClient should not be handled
			def request(method, uri, **params, &block)
				method = method.to_s.downcase.to_sym
				req_params = params.reject { |_,v| Utils.is_blank?(v) }
				req_params = req_params.merge({ follow_redirect: true }) if method == :get
				resp = request_with_retry(method, uri, req_params, &block)
			
				status = resp.status.to_i
				response = {code: status}
				response[:content] = resp.content 
				response[:content_type] = resp.header['Content-Type'].first
				if status < 200 || status >=400 || resp.redirect?
					message = Utils.is_blank?(resp.content) ? resp.reason : resp.content
					request = set_error_request_context(method, uri, req_params)			
					fail Errors::ServerError.new(message, status, response, request)
				end
				response
	
				rescue HTTPClient::TimeoutError
					request = set_error_request_context(method, uri, req_params)			
					raise Errors::TimeoutError.new($!, request)
				rescue HTTPClient::BadResponseError
					request = set_error_request_context(method, uri, req_params)			
					raise Errors::ClientError.new($!, request)
				rescue Errno::ECONNREFUSED, EOFError, SocketError
					request = set_error_request_context(method, uri, req_params)			
					raise Errors::ConnectionFailed.new($!, request)
			end
		
			# Retries HTTP 500 error upto max retries
			# @see request for request and response parameters	
			def request_with_retry(method, uri, req_params, &block)
				retry_count = 0
				loop do
					response = @persistent_conn.request(method, uri, req_params, &block)
					retry_count += 1
					break response unless (response.status.to_i >= 500) && do_retry?(retry_count)
				end
			end

			# Check if retry count is less that max retries and exponetially sleep
			# @param retry_count [Fixnum] current count of retry
			# @return [Boolean]
			def do_retry?(retry_count)
				# max retries + 1 to accomodate try
				retry_count < @max_retries + 1 ? sleep(2**retry_count*0.3) && true : false
			end
			
			# Set request context
			# @see #request
			def set_error_request_context(method, uri, request_params)
					request = { uri: uri.to_s }
					request[:method] = method.to_s
					# @optimize copying params as string makes exception only informative, 
					#		should instead return deep copy of request params so that 
					#		applications can evaluate error.
					request[:params] = request_params.to_s
					request
			end

			private :set_error_request_context, :request_with_retry, :do_retry?
		end
	end
end
