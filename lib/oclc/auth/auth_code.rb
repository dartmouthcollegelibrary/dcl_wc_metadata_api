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
    
    # This class represents an OAuth 2 Authorization Code. In the OAuth 2
    # Explicit Authorization Flow, clients request an authorization code from OCLC
    # Authorization Server. This class will return the login URL to redirect 
    # Location for a user's browser to begin a sign-in process. After a successful
    # login, the user's browser will be redirect back to the client's application
    # with a URL parameter containing the authorization code. This code is then 
    # redeemed for an access token to be used when sending HTTP requests to OCLC
    # web services.
    
    class AuthCode 
      
      attr_accessor :client_id, :authenticating_institution_id, :context_institution_id, :redirect_uri, :scope, :code, 
          :auth_server_url
      
      # Construct the authorization code object to determine your login URL.
      #
      # [client_id] the WSKey key
      # [authenticating_institution_id] the WorldCat Registry ID of the institution that will login the user
      # [context_institution_id] the WorldCat Registry ID of the institution whose data will be accessed
      # [redirect_uri] the redirect URI associated with the WSKey that will 'catch' the redirect back to your app after login 
      # [scope] a space separated list of the OCLC web services the client is requesting access to
      # 
      # Example:
      #
      #   auth_code = OCLC::Auth::AuthCode.new('asdf', 128807, 128807, 'http://localhost:4567/catch_auth_code', 'WMS_Availability')
      #   redirect auth_code.login_url
      #
      def initialize(client_id, authenticating_institution_id, context_institution_id, redirect_uri, scope)
        self.client_id = client_id
        self.authenticating_institution_id = authenticating_institution_id
        self.context_institution_id = context_institution_id
        self.redirect_uri = redirect_uri
        self.scope = scope
      end
      
      # The default URL for the OCLC OAuth server.
      def self.production_url
        'https://authn.sd00.worldcat.org/oauth2/authorizeCode'
      end
      
      # The login URL to redirect a user's web browser to to request an authorization code.
      def login_url
        base_url + "?" + querystring
      end
      
      protected
      
      def querystring
        params = {
          "client_id" => client_id,
          "authenticatingInstitutionId" => authenticating_institution_id.to_s, 
          "contextInstitutionId" => context_institution_id.to_s, 
          "redirect_uri" => redirect_uri, 
          "response_type" => 'code',
          "scope" => scope
        }        
        params.map { |name,value| "#{CGI.escape name}=#{CGI.escape value}" }.sort.join("&")
      end
      
      
      # The Authorization Server URL can be overriden to point at a development instance.
      def base_url 
        @auth_server_url ||= OCLC::Auth::AuthCode.production_url
      end
      
    end
  end
end