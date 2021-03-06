require "cgi"
require 'base64'
require 'openssl'
require 'multi_json'

module CloudFS
	class Client
		#	@private
		# Utility functions module, used to handle common tasks
		module Utils 
			extend self
			# Urlencode value
			#
			# @param value [#to_s] to urlencode
			# @return [String] url encoded string	
			def urlencode(value)
				CGI.escape("#{value}")
			end
			
			# Converts hash to url encoded string	
			#
			# @param hash [Hash] hash to be converted 
			# @param delim [#to_s]
			# @param join_with [#to_s]
			#
			# @return [String] url encode string 
			#		"#{ key }#{ delim }#{ value }#{ join_with }#{ key }#{ delim }#{ value }"
			# @optimize does not handle nested hash
			def hash_to_urlencoded_str(hash = {}, delim, join_with)
				hash.map{|k,v| 
					"#{urlencode(k)}#{delim}#{urlencode(v)}"}.join("#{join_with}")
			end
			
			# Sorts hash by key.downcase
			# @param hash [Hash] unsorted hash
			# @return [Hash] sorted hash
			def sort_hash(hash={})
				sorted_hash = {}
				hash.sort_by{ |k,_| k.to_s.downcase }.each {|k,v| sorted_hash["#{k}"] = v}
				sorted_hash
			end

			# Generate OAuth2 signature based on cloudfs 
			#		signature calculation algorithm
			# 
			# @param endpoint [String] server endpoint
			# @param params [Hash] form data
			# @param headers [Hash] http request headers 
			# @param secret [Hash] cloudfs account secret
			#
			# @return [String] OAuth2 signature
			def generate_auth_signature(endpoint, params, headers, secret)
				params_sorted = sort_hash(params)
				params_encoded = hash_to_urlencoded_str(params_sorted, "=", "&")
				headers_encoded = hash_to_urlencoded_str(headers, ":", "&")
				string_to_sign = "POST&#{endpoint}&#{params_encoded}&#{headers_encoded}" 	
				hmac_str = OpenSSL::HMAC.digest('sha1', secret, string_to_sign)
				Base64.strict_encode64(hmac_str)
			end
	
			# Coverts Json sting to hash
			#		calls MultiJson#load
			# @param json_str [String] json format string
			# @return [Hash] converted hash	
			def json_to_hash(json_str)
				MultiJson.load(json_str, :symbolize_keys=>true)
			end
	
			#	Converts hash to json string
			#		calls MultiJson#dump
			# @param hash [Hash] hash to convert
			# @return [String] json formated string
			def hash_to_json(hash={})
				MultiJson.dump(hash)
			end
			
			# @param hash [Hash]
			# @option filed [Array<String>, Array<Symbol>]
			# @return [Array<Object>]	values at found fields
			def hash_to_arguments(hash, *field)
				if field.any? {|f| hash.key?(f)}
					return hash.values_at(*field)
				end
			end	
			
			# @return [Boolean] whether variable is nil, empty
			def is_blank?(var)
				var.respond_to?(:empty?) ? var.empty? : !var
			end
		
		end
	end
end
