# Copyright 2014 Terry Reese
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module WC_METADATA_API
   class Helper
     attr_accessor :debug_string
     attr_accessor :wskey, :secret, :principalID, :principalDNS

     def initialize(options={})
        @wskey = options[:wskey]
        @secret = options[:secret]
        @principalID = options[:principalID]
        @principalDNS = options[:principalDNS]
     end

 
     def MakeHTTPRequest(opts={})
	@debug_string = ""

	   token = OCLC::Auth::WSKey.new(@wskey, @secret)
	   uri = URI.parse(opts[:url])
           request = Net::HTTP::Get.new(uri.request_uri)
	   request['Authorization'] =token.hmac_signature('GET', opts[:url], :principal_id => @principalID, :principal_idns => @principalDNS)
 	   request['Accept'] = 'application/atom+xml;content="application/vnd.oclc.marc21+xml"' # Modified to specify MARCXML
	   request['Content-Type'] = 'application/atom+xml'
	   http = Net::HTTP.new(uri.host, uri.port)
	   http.use_ssl = true
	   response = http.start do |http|
	      http.request(request)
	   end
	   return response # Modified to return full response object
     end

     def MakeHTTP_POST_PUT_Request(opts={})
        @debug_string = ""
           token = OCLC::Auth::WSKey.new(@wskey, @secret)
           uri = URI.parse(opts[:url])
	   request = nil
           if opts[:method] == "POST"
	     request = Net::HTTP::Post.new(uri.request_uri)
	   elsif opts[:method] == "PUT"
	     request = Net::HTTP::Put.new(uri.request_uri)
	   elsif opts[:method] == "DELETE"
	     request = Net::HTTP::Delete.new(uri.request_uri)
	   end 
           request['Authorization']=token.hmac_signature(opts[:method], opts[:url], :principal_id => @principalID, :principal_idns => @principalDNS) 
           request['Content-Type'] = 'application/vnd.oclc.marc21+xml'
	   request['Accept'] = 'application/atom+xml'
	   http = Net::HTTP.new(uri.host, uri.port)
           http.use_ssl = true
	   request.body = opts[:xRecord]
           response = http.start do |http|
	       http.request(request)
	   end
           return response
      end
   end
end
