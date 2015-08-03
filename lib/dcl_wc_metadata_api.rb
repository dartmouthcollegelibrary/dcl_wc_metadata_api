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
      begin
        @LastResponseCode.code.start_with?("2") # 200, 201, 207
      rescue NoMethodError
        return false
      end
    end
    
  end
end

# New module introduces a Manager class to iterate through the provided 
# input, calling WC_METADATA_API::Client and recording response and status
# information for each record or record number. Also defines new methods
# for setting and loading API credentials at config/credentials.yml.

module DCL_WC_METADATA_API

  C_FILE = File.dirname(__FILE__) + "/../config/credentials.yml"
  
  def load_credentials
    
  end
  
  def set_credentials(input)
    
  end
  
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
      
      self.set_up_client()
      
      @debug_info = "CLIENT REQUEST(S)"
      @response_status = "RESULT(S)\n\n"
      @response_data = Nokogiri::XML::Document.parse(
        "<collection xmlns=\"http://www.loc.gov/MARC21/slim\">"
      )
      @successes = 0
      @failures = 0
    end
    
    # Set up API client
    def set_up_client()
      c_file = File.dirname(__FILE__) + "/../config/credentials.yml"
      
      if File.exists?(c_file)
        credentials = YAML.load(
          File.open(c_file, "r")
        )
        @credentials = credentials["credentials"]
        
        # Check credentials for "{" and "}" left over from placeholder strings
        invalid_credentials = {}
        @credentials.each_pair do |key, value|
          if value.include?("{") || value.include?("}")
            invalid_credentials[key] = value
          end
        end
        
        # Raise error or create client
        if invalid_credentials.length > 0
          ic = ""
          invalid_credentials.each { |key, value| ic << "#{key}: #{value}\n" }
          Clop::die "Some API credentials appear not to be set. " +
            "Check values of the credentials below.\n#{ic}"
        else
          @client = WC_METADATA_API::Client.new(
            :wskey => @credentials["key"],
            :secret => @credentials["secret"],
            :principalID => @credentials["principalID"],
            :principalDNS => @credentials["principalDNS"],
            :debug => false
          )
        end
      
      else
        Clop::die "API credentials not set. Use config command"
      end
    end
    
    # Write to output file
    def log_output()
      prefix = @global_opts[:prefix] ? (@global_opts[:prefix] + "-") : ""
      any_records = (@successes > 0 ? true : false) # Check for any successes
      t = Time.now.strftime("%Y%m%d%H%M%S")
      
      # Data
      if any_records
        d_filename = prefix + "wc-" + @cmd + "-" + t + ".xml"
        d = File.new(d_filename, "w+:UTF-8")
        d.write(@response_data)
        d.close
      end
      
      # Status log
      s_filename = prefix + "wc-" + @cmd + "-" + t + "-log.txt"
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
        begin
          r = @client.WorldCatGetBibRecord(
            :oclcNumber => number,
            :holdingLibraryCode => @credentials["holdingLibraryCode"],
            :schema => @credentials["schema"],
            :instSymbol => @credentials["instSymbol"]
          )
          rc = Nokogiri::XML::Document.parse(@client.LastResponseCode.body)
        rescue TypeError, URI::Error => e
          @response_status << e.message + "\n"
        ensure
          @debug_info << @client.debug_info.to_s + "\n\n"
          manage_record_result(number, rc)
        end
      end
      
      log_output
    end
    
    # Create API operation
    def create(input)
      @cmd = "create"
      records = {}
      numbers = []
      
      # Extract records into hash
      set = input.xpath(RECORD_XPATH, "marc" => XMLNS_MARC)
      set.each do |record|
        if record.at_xpath(ID_XPATH, "marc" => XMLNS_MARC).nil?
          id = set.index(record).to_s # Use record's index as backup ID
        else
          id = record.at_xpath(ID_XPATH, "marc" => XMLNS_MARC).text
        end
        records[id] = record
      end
      
      # Submit records
      records.each_pair do |id, record|
        begin
          if record.namespace_definitions.length == 0
            record["xmlns:marc"] = XMLNS_MARC
          end
          r = @client.WorldCatAddBibRecord(
            :holdingLibraryCode => @credentials["holdingLibraryCode"],
            :schema => @credentials["schema"],
            :instSymbol => @credentials["instSymbol"],
            :xRecord => record.to_s
          )
          rc = Nokogiri::XML::Document.parse(@client.LastResponseCode.body)
          number = rc.at_xpath(WC_URL_XPATH)
          numbers << number.to_s.slice(/[\d]+/)
        rescue TypeError, URI::Error => e
          @response_status << e.message + "\n"
        ensure
          @debug_info << @client.debug_info.to_s + "\n\n" + record.to_s + "\n\n"
          manage_record_result(id, rc)
        end
      end
      
      # Call holdings operation
      set_holdings(numbers)
      
      log_output
    end
    
    # Set holdings API operation
    def set_holdings(input)
    
      input.each do |number|
        begin
          hr = client.WorldCatAddHoldings(
            :oclcNumber => number,
            :holdingLibraryCode => @credentials["holdingLibraryCode"],
            :schema => @credentials["schema"],
            :instSymbol => @credentials["instSymbol"]
          )
          hrc = Nokogiri::XML::Document.parse(@client.LastResponseCode.body)
        rescue TypeError, URI::Error => e
          @response_status << e.message + "\n"
        ensure
          @debug_info << @client.debug_info.to_s + "\n\n"
          manage_holding_result(number, hrc)
        end
      end
      
    end
    
  end
end

