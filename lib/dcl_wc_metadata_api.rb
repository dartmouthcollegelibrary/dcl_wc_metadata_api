# Copyright 2015 Trustees of Dartmouth College
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

require_relative 'wc_metadata_api/client'
require_relative 'wc_metadata_api/helper'
require_relative 'oclc/auth'
require_relative 'clop/clop'
require 'nokogiri'
require 'uri'
require 'net/http'
require 'cgi'
require 'yaml'

# Minor extension to evaluate API's HTTP response

module WC_METADATA_API
  class Client
  
    def is_success?
      @LastResponseCode.code.start_with?("2") # 200, 201, 207
    end
    
  end
end

# New module introduces a Manager class to iterate through the provided 
# input, calling WC_METADATA_API::Client and recording response and status
# information for each record or record number.

module DCL_WC_METADATA_API
  class Manager
  
    attr_reader :global_opts
    attr_accessor :credentials, :client, :cmd
    attr_accessor :debug_info, :response_status, :response_data
    attr_accessor :successes, :failures
    
    XMLNS_MARC = "http://www.loc.gov/MARC21/slim"
    RECORD_XPATH = "//marc:record"
    ID_XPATH = "marc:datafield[@tag='035']/marc:subfield[@code='a']"
    WC_URL_XPATH = "//xmlns:id" # In returned Atom XML wrapper
    PAST_TENSE = { "read" => "read", "create" => "created" }
        
    def initialize(options={})
      @global_opts = options # Provided via command line
      @debug_info = "CLIENT REQUEST(S)"
      @response_status = "RESULT(S)\n\n"
      @response_data = Nokogiri::XML::Document.parse(
        "<collection xmlns=\"http://www.loc.gov/MARC21/slim\">"
      )
      @successes = 0
      @failures = 0
      
      # Set up API client
      credentials = YAML.load(
        File.open(File.dirname(__FILE__) + "/../config/credentials.yml", "r")
      )
      @credentials = credentials["credentials"]
      @client = WC_METADATA_API::Client.new(
        :wskey => @credentials["key"],
        :secret => @credentials["secret"],
        :principalID => @credentials["principalid"],
        :principalDNS => @credentials["principaldns"],
        :debug => false
      )
    end
    
    # Write to output file
    def log_output()
      any_records = (@successes > 0 ? true : false) # Check for any successes
      t = Time.now.strftime("%Y%m%d%H%M%S")
      
      # Data
      if any_records
        d_filename = "wc-" + @cmd + "-" + t + ".xml"
        d = File.new(d_filename, "w+:UTF-8")
        d.write(@response_data)
        d.close
      end
      
      # Status log
      s_filename = "wc-" + @cmd + "-" + t + "-log.txt"
      s = File.new(s_filename, "w+:UTF-8")
      s.write(@debug_info) if @global_opts[:debug]
      s.write(@response_status)
      s.close
     
      puts "OCLC WorldCat Metadata API: " + @cmd.capitalize + " operation"
      puts PAST_TENSE[@cmd].capitalize + " " + @successes.to_s + \
        (@successes != 1 ? " records, " : " record, ") + @failures.to_s + " failed"
      puts "Records written to " + d_filename if any_records
      puts "Log written to " + s_filename
    end
    
    # Handle success or failure for each API call
    # TODO?: Use caller_locations(1,1)[0].label instead of @cmd
    def manage_record_result(id, result)
      if @client.is_success?
        @response_data.root << result.at_xpath(RECORD_XPATH,
          "marc" => XMLNS_MARC
        )
        @response_status << id + ": " + PAST_TENSE[@cmd] + "\n"
        puts id + ": " + PAST_TENSE[@cmd] if @global_opts[:verbose]
        @successes += 1
      else
        @response_status << id + ": failed\n"
        @response_status << result.to_s
        puts id + ": failed" if @global_opts[:verbose]
        @failures += 1
      end
    end
    
    def manage_holding_result(id, result)
      if @client.is_success?
        @response_status << id + ": holding set\n"
        puts id + ": holding set" if @global_opts[:verbose]
        #@successes += 1
      else
        @response_status << id + ": set holding failed\n"
        @response_status << result.to_s
        puts id + ": set holding failed" if @global_opts[:verbose]
        #@failures += 1
      end
    end
    
    # Read API operation
    def read(input)
      @cmd = "read"
      numbers = []

      # Extract digit strings from file or command-line input
      if File.exists?(input)
        File.open(input, "r").each { |line| 
          line.scan(/[\d]+/) { |match| numbers << match }
        }
      else
        input.scan(/[\d]+/) { |match| numbers << match }
      end
      
      # Retrieve records
      numbers.each do |number|        
        r = @client.WorldCatGetBibRecord(
          :oclcNumber => number,
          :holdingLibraryCode => @credentials["holdingLibraryCode"],
          :schema => @credentials["schema"],
          :instSymbol => @credentials["instSymbol"]
        )
        @debug_info << @client.debug_info + "\n\n"
        rc = Nokogiri::XML::Document.parse(@client.LastResponseCode.body)
        manage_record_result(number, rc)
        
      end
   
      log_output
    end
 
    # Create API operation
    def create(input)
      @cmd = "create"
      records = {}
      numbers = []
      
      # Extract records into hash
      input.xpath(RECORD_XPATH, "marc" => XMLNS_MARC).each do |record|
        id = record.at_xpath(ID_XPATH, "marc" => XMLNS_MARC).text
        records[id] = record
      end

      # Submit records
      records.each_pair do |id, record|
        if record.namespace_definitions.length == 0
          record["xmlns:marc"] = XMLNS_MARC
        end
        r = @client.WorldCatAddBibRecord(
          :holdingLibraryCode => @credentials["holdingLibraryCode"],
          :schema => @credentials["schema"],
          :instSymbol => @credentials["instSymbol"],
          :xRecord => record.to_s
        )
        @debug_info << @client.debug_info + "\n\n" + record.to_s + "\n\n"
        rc = Nokogiri::XML::Document.parse(@client.LastResponseCode.body)
        manage_record_result(id, rc)
        number = rc.at_xpath(WC_URL_XPATH)
        numbers << number.to_s.slice(/[\d]+/)
      end
      
      # Call holdings operation
      set_holdings(numbers)
     
      log_output
    end
    
    # Set holdings API operation
    # TODO: Write as stand-alone for set of pre-existing OCLC numbers
    # TODO: Use holdings resource batch set functionality
    def set_holdings(input)
      
      input.each do |number|
        hr = client.WorldCatAddHoldings(
          :oclcNumber => number,
          :holdingLibraryCode => @credentials["holdingLibraryCode"],
          :schema => @credentials["schema"],
          :instSymbol => @credentials["instSymbol"]
        )
        @debug_info << @client.debug_info + "\n\n"
        hrc = Nokogiri::XML::Document.parse(@client.LastResponseCode.body)
        manage_holding_result(number, hrc)
      end
        
    end

  end
end

