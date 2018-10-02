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
  class Client

     WORLDCAT_METADATA_BIB_DATA_URI = "https://worldcat.org/bib/data"
     WORLDCAT_METADATA_HOLDINGS_DATA_URI = "https://worldcat.org/ih/data"
     WORLDCAT_METADATA_HOLDINGS_CODES_DATA_URI = "https://worldcat.org/bib/holdinglibraries"
     WORLDCAT_METADATA_LOCAL_BIB_DATA_URI = "https://worldcat.org/lbd/data"
     WORLDCAT_METADATA_LOCAL_BIB_DATA_SEARCH_URI = "https://worldcat.org/lbd/search"

     # Modified to add base URIs for validation operations
     WORLDCAT_METADATA_VALIDATE_FULL_URI = "https://worldcat.org/bib/validateFull"
     WORLDCAT_METADATA_VALIDATE_ADD_URI = "https://worldcat.org/bib/validateAdd"
     WORLDCAT_METADATA_VALIDATE_REPLACE_URI = "https://worldcat.org/bib/validateReplace"

     attr_accessor :LastResponseCode
     attr_accessor :debug_info # Modified to store debug string
     def initialize(options={})
        @debug = options[:debug]
        @wskey = options[:wskey]
        @secret = options[:secret]
        @principalDNS = options[:principalDNS]
        @principalID = options[:principalID]
     end


     def WorldCatAddBibRecord(opts={})
        sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_BIB_DATA_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)

          base_uri += "?instSymbol=" + opts[:instSymbol] + "&classificationScheme=" + opts[:schema] + "&holdingLibraryCode=" + opts[:holdingLibraryCode]
          response = helper.MakeHTTP_POST_PUT_Request(:url => base_uri, :method => "POST", :xRecord => opts[:xRecord])
          @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
	  return true
     end

     def WorldCatUpdateBibRecord(opts={})
        sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_BIB_DATA_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)

          base_uri += "?instSymbol=" + opts[:instSymbol] + "&classificationScheme=" + opts[:schema] + "&holdingLibraryCode=" + opts[:holdingLibraryCode]
          response = helper.MakeHTTP_POST_PUT_Request(:url => base_uri, :method => "PUT", :xRecord => opts[:xRecord])
          @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
          return true
     end


     def WorldCatGetBibRecord(opts={})
	sRecord = ""
        begin
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_BIB_DATA_URI + "/"
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)

          base_uri += opts[:oclcNumber] + "?instSymbol=" + opts[:instSymbol] + "&classificationScheme=" + opts[:schema] + "&holdingLibraryCode=" + opts[:holdingLibraryCode]
          response = helper.MakeHTTPRequest(:url => base_uri, :method => "GET")
	  @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
          sRecord = response
          return sRecord
 	rescue
          #raise exception
        end
     end


     def WorldCatAddHoldings(opts={})
        sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_HOLDINGS_DATA_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)

          base_uri += "?instSymbol=" + opts[:instSymbol] + "&classificationScheme=" + opts[:schema] + "&holdingLibraryCode=" + opts[:holdingLibraryCode] + "&oclcNumber=" + opts[:oclcNumber]
          response = helper.MakeHTTP_POST_PUT_Request(:url => base_uri, :method => "POST", :xRecord => opts[:xRecord])
          @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
          return true

     end

     def WorldCatDeleteHoldings(opts={})
        sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_HOLDINGS_DATA_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)

          base_uri += "?instSymbol=" + opts[:instSymbol] + "&classificationScheme=" + opts[:schema] + "&holdingLibraryCode=" + opts[:holdingLibraryCode] + "&oclcNumber=" + opts[:oclcNumber] + "&cascade=1"
          response = helper.MakeHTTP_POST_PUT_Request(:url => base_uri, :method => "DELETE", :xRecord => opts[:xRecord])
          @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
          return true
     end

     def WorldCatRetrieveHoldingCodes(opts={})
         sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_HOLDINGS_CODES_DATA_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)
          base_uri += "?instSymbol=" + opts[:instSymbol]
	  response = helper.MakeHTTPRequest(:url => base_uri, :method => "GET")
          @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
          sRecord = response
          return sRecord

     end

     def WorldCatSearchForLocalBibRecords(opts={})
         sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_LOCAL_BIB_DATA_SEARCH_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)
          base_uri += "?oclcNumber=" + opts[:oclcNumber] + "&classificationScheme=" + opts[:schema] + "&holdingLibraryCode=" + opts[:holdingLibraryCode]
          response = helper.MakeHTTPRequest(:url => base_uri, :method => "GET")
          @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
          sRecord = response
          return sRecord
     end

     def WorldCatReadLocalBibRecord(opts={})
         sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_LOCAL_BIB_DATA_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)
	  base_uri += "/" + opts[:oclcNumber] + "?classificationScheme=" + opts[:schema] + "&holdingLibraryCode=" + opts[:holdingLibraryCode]
	  response = helper.MakeHTTPRequest(:url => base_uri, :method => "GET")
          @debug_info = helper.debug_string + "\n\n" + base_uri
	  @LastResponseCode = response
          sRecord = response
          return sRecord

     end

     def WorldCatDeleteLocalBibRecord(opts={})
         sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_LOCAL_BIB_DATA_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)

          base_uri += "?instSymbol=" + opts[:instSymbol] + "&classificationScheme=" + opts[:schema] + "&holdingLibraryCode=" + opts[:holdingLibraryCode]
          response = helper.MakeHTTP_POST_PUT_Request(:url => base_uri, :method => "DELETE", :xRecord => opts[:xRecord])
          @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
          return true
     end

     def WorldCatAddLocalBibRecord(opts={})
        sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_LOCAL_BIB_DATA_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)

          base_uri += "?instSymbol=" + opts[:instSymbol] + "&classificationScheme=" + opts[:schema] + "&holdingLibraryCode=" + opts[:holdingLibraryCode]
          response = helper.MakeHTTP_POST_PUT_Request(:url => base_uri, :method => "POST", :xRecord => opts[:xRecord])
          @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
          return true
     end

     def WorldCatUpdateLocalBibRecord(opts={})
        sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_LOCAL_BIB_DATA_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)

          base_uri += "?instSymbol=" + opts[:instSymbol] + "&classificationScheme=" + opts[:schema] + "&holdingLibraryCode=" + opts[:holdingLibraryCode]
          response = helper.MakeHTTP_POST_PUT_Request(:url => base_uri, :method => "PUT", :xRecord => opts[:xRecord])
          @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
          return true
     end

     # Added to support validation operation
     def WorldCatValidateFull(opts={})
        sRecord = ""
          @LastResponseCode = ""
          base_uri = WORLDCAT_METADATA_VALIDATE_FULL_URI
          helper = Helper.new(:wskey => @wskey, :secret => @secret, :principalID=>@principalID, :principalDNS => @principalDNS)

          response = helper.MakeHTTP_POST_PUT_Request(:url => base_uri, :method => "POST", :xRecord => opts[:xRecord])
          @debug_info = helper.debug_string + "\n\n" + base_uri
          @LastResponseCode = response
	        return true
     end

  end
end
