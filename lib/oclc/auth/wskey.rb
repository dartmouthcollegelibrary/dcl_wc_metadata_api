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
    
    # A class that represents a clients OCLC Web Service Key. The WSKey has a key and 
    # secret and has access to one or more OCLC Web Services. Optionally, it can include 
    # a redirect URI and an array of services to be used in the OAuth 2 login flows.
    # 
    # The WSKey class is used to
    #
    # * generate HMAC signatures
    # * return the login URL for the OCLC Explicit Authorization flow for requesting an AuthCode
    # * redeem an authorization code for an access token
    # * request an access token via a client credentials grant flow
    # 
    # See the OCLC::Auth documentation for examples.
    class WSKey
    
      attr_reader :key, :secret, :redirect_uri, :services
      attr_accessor :debug_mode, :debug_timestamp, :debug_nonce 
    
      # Construct a new Web Service key for use when authenticating to OCLC Web Services.
      #
      # [key] the hashed string that represents your API key
      # [secret] the secret used when generating digital signatures
      # [options] a hash of optional parameters described below
      # 
      # Options
      # 
      # [:redirect_uri] the redirect URI associated with the WSKey that will 'catch' the redirect back to your app after login 
      # [:services] an array of one or more OCLC web services, examples: WorldCatMetadataAPI, WMS_NCIP
      def initialize(key, secret, options = {})
        @key = key
        @secret = secret
        if options[:redirect_uri] 
          @redirect_uri = options[:redirect_uri] 
        end
        if options[:services]
          @services = options[:services] 
        end
      end
      
      # Returns the login URL used with OCLC's OAuth 2 implementation of the  Explicit Authorization Flow.
      #
      # See {Explicit Auth Documentation}[http://www.oclc.org/developer/platform/explicit-authorization-code] on the 
      # OCLC Developer Network.
      def login_url(authenticating_institution_id, context_institution_id)
        if services == nil or services.size == 0
          raise OCLC::Auth::Exception, "No service specified. You must construct a WSKey with one or more services to request an auth code" 
        end
        auth_code = OCLC::Auth::AuthCode.new(@key, authenticating_institution_id, context_institution_id, @redirect_uri, services.join(' '))
        auth_code.login_url
      end
      
      # Retuns an OCLC::Auth::AccessToken object when given an authorization code
      #
      # [auth_code] the authorization code returne from OCLC's Authorization Server as a result of sending 
      #             a user's browser through the login process.
      # [authenticating_institution_id] the WorldCat Registry ID of the institution that will login the user
      # [context_institution_id] the WorldCat Registry ID of the institution whose data will be accessed
      def auth_code_token(auth_code, authenticating_institution_id, context_institution_id)
        options = {:redirect_uri => redirect_uri, :code => auth_code}
        token = OCLC::Auth::AccessToken.new('authorization_code', services.join(' '), authenticating_institution_id, context_institution_id, options)
        token.create!(self)
        token
      end
      
      # Retuns an OCLC::Auth::AccessToken object when given an authorization code
      #
      # [scope] a space separated list of the OCLC web services the client is requesting access to
      # [authenticating_institution_id] the WorldCat Registry ID of the institution that will login the user
      # [context_institution_id] the WorldCat Registry ID of the institution whose data will be accessed
      # [options] a hash of optional parameters described below
      #
      # Options
      # 
      # [:principal_id] the ID that represents a user
      # [:principal_idns] the ID namespace context for the user
      def client_credentials_token(authenticating_institution_id, context_institution_id, options = {})
        if services == nil or services.size == 0
          raise OCLC::Auth::Exception, "No service specified. You must construct a WSKey with one or more services to request an access token code" 
        end
        token = OCLC::Auth::AccessToken.new('client_credentials', services.join(' '), authenticating_institution_id, context_institution_id)
        token.create!(self, options)
        token
      end
    
      # Generates a digital signature for a given request according to the OAuth HMAC specification
      #
      # [http_method] the HTTP method, GET, POST, PUT, DELETE
      # [url] the URL the request will be made to
      # [options] a hash of optional parameters described below
      #
      # Options
      # 
      # [:principal_id] the ID that represents a user
      # [:principal_idns] the ID namespace context for the user
      def hmac_signature(http_method, url, options = {})
        req_timestamp = timestamp
        req_nonce = nonce 
        signature_base = signature_base_string(req_timestamp, req_nonce, http_method, url)
      
        auth  = ""
        auth += "#{scheme_url} "
        auth += "clientId=\"#{client_id}\", "
        auth += "timestamp=\"#{req_timestamp}\", "
        auth += "nonce=\"#{req_nonce}\", "
        auth += "signature=\"#{signature(signature_base)}\""
        
        if options[:principal_id] and options[:principal_idns] 
          append = true
          uri = URI.parse(url)
          if uri.query
            params = CGI::parse(uri.query)
            append = params.has_key?("principalID") ? false : true
          end
          auth += ", principalID=\"#{options[:principal_id]}\", principalIDNS=\"#{options[:principal_idns]}\"" if append
        end
        auth
      end
      
      protected
    
      def scheme_url
        "http://www.worldcat.org/wskey/v2/hmac/v1"
      end
    
      # The WSKey assigned from OCLC
      def client_id
        @key
      end
    
      # A POSIX timestamp
      def timestamp
        @debug_timestamp ? @debug_timestamp : Time.now.to_i
      end
    
      def nonce
        @debug_nonce ? @debug_nonce : rand(10 ** 30).to_s.rjust(30,'0')
      end
    
      def signature_base_string(req_timestamp, req_nonce, http_method, url)
        str = [client_id, req_timestamp, req_nonce, '', http_method, 'www.oclc.org', '443', '/wskey'].join("\n")
        str += "\n#{normalized_query_str(url)}" if normalized_query_str(url).strip != ''
        str + "\n"
      end
    
      def normalized_query_str(url)
        escaped_params = []
        
        uri = URI.parse(url)
        if uri.query
          params = CGI::parse(uri.query)
          params.each do |key,values|
            values.each do |value|
              value = CGI.unescape(value)
              escaped_params << key + "=" + CGI.escape(value).gsub('+', '%20')
            end
          end
        end
      
        escaped_params.sort.join("\n")
      end
    
      def signature( base_string )
        digest = OpenSSL::Digest::Digest.new( 'sha256' )
        hmac = OpenSSL::HMAC.digest( digest, @secret, base_string  )
        Base64.encode64( hmac ).chomp.gsub( /\n/, '' )
      end
    end
  end
end