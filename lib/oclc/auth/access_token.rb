# Copyright 2013 OCLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module OCLC
  module Auth
    
    # This class represents an OAuth 2 Access Token. Clients can request access tokens 
    # so that they can authenticate to OCLC Web Services that accept access tokens. 
    
    class AccessToken
      
      attr_accessor :grant_type, :authenticating_institution_id, :context_institution_id, :scope, :redirect_uri, :code, 
          :auth_server_url, :value, :expires_at, :principal_id, :principal_idns
      
      # Construct the access token object
      #
      # [grant_type] the OAuth grant type, authorization_code or client_credentials
      # [scope] a space separated list of the OCLC web services the client is requesting access to
      # [authenticating_institution_id] the WorldCat Registry ID of the institution that will login the user
      # [context_institution_id] the WorldCat Registry ID of the institution whose data will be accessed
      # [options] a hash of optional parameters described below
      #
      # Options
      #
      # [:redirect_uri] the redirect URI associated with the WSKey that will 'catch' the redirect back to your app after login 
      # [:code] the authorization code retrieved from the authorization server
      def initialize(grant_type, scope, authenticating_institution_id, context_institution_id, options = {})
        self.grant_type = grant_type
        self.authenticating_institution_id = authenticating_institution_id
        self.context_institution_id = context_institution_id
        self.scope = scope
        self.redirect_uri = options[:redirect_uri] if options[:redirect_uri] 
        self.code = options[:code] if options[:code] 
      end
      
      # The default URL for the OCLC OAuth server.
      def self.production_url
        'https://authn.sd00.worldcat.org/oauth2/accessToken'
      end
      
      def create!(wskey, options = {})
        uri = URI(request_url)
        url = uri.to_s
        auth = wskey.hmac_signature("POST", url, options)
        
        resource = RestClient::Resource.new url
        resource.post('', :authorization => auth) do |response, request, result|
          @response_body = response
          @response_code = result.code
          if @response_code == '200'
            token_data = JSON.parse(@response_body)
            @value = token_data["access_token"]
            @principal_id = token_data["principalID"]
            @principal_idns = token_data["principalIDNS"]
            @expires_at = DateTime.parse(token_data["expires_at"])
          else
            token_data = JSON.parse(@response_body)
            if token_data['message']
              raise OCLC::Auth::Exception, token_data['message']
            elsif token_data['error']['errorMessage']
              raise OCLC::Auth::Exception, token_data['error']['errorMessage']
            else
              raise OCLC::Auth::Exception, @response_body
            end  
          end
        end
      end
      
      def expired?
        @expires_at - Time.now.to_datetime < 0
      end
      
      def request_url
        base_url + "?" + querystring
      end
      
      protected
      
      def querystring
        params = {
          "grant_type" => grant_type,
          "scope" => scope, 
          "contextInstitutionId" => context_institution_id.to_s, 
          "authenticatingInstitutionId" => authenticating_institution_id.to_s
        }
        params["redirect_uri"] = redirect_uri if redirect_uri
        params["code"] = code if code
        
        params.map { |name,value| "#{CGI.escape name}=#{CGI.escape value}" }.sort.join("&")
      end
      
      def base_url 
        @auth_server_url ||= OCLC::Auth::AccessToken.production_url
      end
      
    end
  end
end