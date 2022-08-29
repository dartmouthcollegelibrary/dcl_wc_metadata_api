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
require 'csv'

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

  C_DIR = File.expand_path("../../config", __FILE__)
  C_FILE = C_DIR + "/credentials.yml"

  # Load credentials
  def DCL_WC_METADATA_API.load_credentials
    if File.exists?(C_FILE)
      yaml = YAML.load(File.open(C_FILE, "r"))
      yaml ? yaml["credentials"] : {}
    else
      {}
    end
  end

  # Check for presence of all required credentials
  def DCL_WC_METADATA_API.validate_credentials
    credentials = load_credentials
    req_keys = ["key", "secret", "principalID", "principalDNS", "schema",
      "holdingLibraryCode", "instSymbol"]
    missing_keys = req_keys - credentials.keys
    if missing_keys.empty?
      credentials
    else
      Clop::die "Some API credentials appear not to be set." +
        " Please set the values of: #{missing_keys.join(", ")}" +
        " using the config command"
    end
  end

  # Display credentials
  def DCL_WC_METADATA_API.display_credentials
    credentials = load_credentials
    if credentials.empty?
      Clop::die "No credentials are set. Use the config command"
    else
      credentials.each { |key, value| puts "#{key}: #{value}\n" }
    end
  end

  # Set or update credentials
  def DCL_WC_METADATA_API.set_credentials(input)
    Dir.mkdir(C_DIR) if !Dir.exist?(C_DIR) # Create /config if it doesn't exist

    new = {}
    strings = input.select { |s| s.include?("=") } # Basic data validation
    Clop::die "No <name>=<value> pairs found in input" if strings.length == 0
    strings.each do |string|
      pair = string.split("=", 2) # Limit because secrets may include "="
      new[pair[0]] = pair[1]
    end

    # Combine user input with any existing credentials and write to file
    current = load_credentials
    combined = !current.empty? ? current.merge(new) : new
    credentials = { "credentials" => combined }
    output = File.open(C_FILE, "w+")
    YAML.dump(credentials, output)
    output.close
    puts "Credentials set."
  end

  class Manager

    attr_reader :global_opts
    attr_accessor :credentials, :client, :cmd
    attr_accessor :debug_info, :response_status, :response_data
    attr_accessor :successes, :failures

    XMLNS_MARC = "http://www.loc.gov/MARC21/slim"
    RECORD_XPATH = "//marc:record"
    OCLC_NUM_XPATH = "marc:controlfield[@tag='001']"
    ID_XPATH = "marc:datafield[@tag='035']/marc:subfield[@code='a']"
    WC_URL_XPATH = "//xmlns:id" # In returned Atom XML wrapper
    PAST_TENSE = { "read" => "read", "create" => "created",
      "update" => "updated", "set" => "set", "unset" => "unset",
      "check" => "matched", "validate" => "validated" }

    # Set up API client
    def initialize(options={})
      @global_opts = options # Provided via command line
      @credentials = DCL_WC_METADATA_API.validate_credentials
      @client = WC_METADATA_API::Client.new(
        :wskey => @credentials["key"],
        :secret => @credentials["secret"],
        :principalID => @credentials["principalID"],
        :principalDNS => @credentials["principalDNS"],
        :debug => false
      )
      @debug_info = "CLIENT REQUEST(S)"
      if @global_opts[:csv]
        @response_status = ["Record Number", "Status",  "Response"].to_csv
      else
        @response_status = "RESULT(S)\n\n"
      end
      @response_data = Nokogiri::XML::Document.parse(
        "<collection xmlns=\"http://www.loc.gov/MARC21/slim\">"
      )
      @successes = 0
      @failures = 0
    end

    # Write to output file
    def log_output()
      prefix = @global_opts[:prefix] ? (@global_opts[:prefix] + "-") : ""
      t = Time.now.strftime("%Y%m%d%H%M%S")

      # Check for any returned records
      if (@successes > 0 and not ["set", "unset", "check"].include?(@cmd))
        any_records = true
      else
        any_records = false
      end

      # Data
      if any_records
        data_filename = prefix + "wc-" + @cmd + "-" + t + ".xml"
        data = File.new(data_filename, "w+:UTF-8")
        data.write(@response_data)
        data.close
      end

      status_extension = @global_opts[:csv] ? ".csv" : ".txt"
      status_filename = prefix + "wc-" + @cmd + "-" + t + "-log" + status_extension

      # Summary
      summary = ""
      summary << <<~SUMMARY
      OCLC WorldCat Metadata API: #{@cmd.capitalize} operation
      #{PAST_TENSE[@cmd].capitalize} #{@successes.to_s} #{@successes != 1 ? "records" : "record"} and #{@failures.to_s} failed
      #{"Records written to " + data_filename if any_records}
      Log written to #{status_filename}
      SUMMARY

      # Status log
      status = File.new(status_filename, "w+:UTF-8")
      status.write(@debug_info) if @global_opts[:debug]
      status.write(summary + "\n")
      status.write(@response_status)
      status.close

      puts summary
    end

    # Handle success or failure for each API call
    def manage_record_result(id, result)
      separator = @global_opts[:csv] ? "," : ": "
      if @client.is_success?
        @response_data.root << result.at_xpath(RECORD_XPATH,
          "marc" => XMLNS_MARC
        )
        @response_status << id + separator + PAST_TENSE[@cmd] + "\n"
        puts id + separator + PAST_TENSE[@cmd] if @global_opts[:verbose]
        @successes += 1
      else
        if @global_opts[:csv]
          @response_status << [id, "failed", result.to_s].to_csv
        else
          @response_status << id + separator + "failed\n"
          @response_status << result.to_s
        end
        puts id + separator + "failed" if @global_opts[:verbose]
        @failures += 1
      end
    end

    def manage_holding_result(id, result)
      separator = @global_opts[:csv] ? "," : ": "
      if @client.is_success?
        @response_status << id + separator + "holding updated\n"
        puts id + separator + "holding updated" if @global_opts[:verbose]
        @successes += 1 if ["set", "unset"].include?(@cmd)
      else
        if @global_opts[:csv]
          @response_status << [id, "update holding failed", result.to_s].to_csv
        else
          @response_status << id + separator + "update holding failed\n"
          @response_status << result.to_s
        end
        puts id + separator + "update holding failed" if @global_opts[:verbose]
        @failures += 1 if ["set", "unset"].include?(@cmd)
      end
    end

    def manage_check_result(id, result)
      found = result["entries"][0]["content"]["found"]
      merged = result["entries"][0]["content"]["merged"]
      returnedNumber = result["entries"][0]["content"]["currentOclcNumber"]
      detail = result["entries"][0]["content"]["detail"]
      separator = @global_opts[:csv] ? "," : ": "

      if @client.is_success? and found and returnedNumber == id
        @response_status << id + separator + "#{returnedNumber}\n"
        puts id + separator + "#{returnedNumber}" if @global_opts[:verbose]
        @successes += 1 if @cmd == "check"
      else
        if merged
          @response_status << id + separator + "merged with #{returnedNumber}\n"
          puts id + separator + "merged with #{returnedNumber}" if @global_opts[:verbose]
        else
          if detail.nil?
            @response_status << id + separator + "number check failed\n"
            puts id + separator + "number check failed" if @global_opts[:verbose]
          else
            if @global_opts[:csv]
              @response_status << [id, "number check failed (\"#{detail}\")", result.to_s].to_csv
            else
              @response_status << id + separator + "number check failed (\"#{detail}\")\n"
              @response_status << result.to_s + "\n"
            end
            puts id + separator + "number check failed (\"#{detail}\")" if @global_opts[:verbose]
          end
        end
        @failures += 1 if @cmd == "check"
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
        Clop::die "No record numbers found in input" if numbers.length == 0
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
        rescue NoMethodError, TypeError, URI::Error => e
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
        rescue NoMethodError, TypeError, URI::Error => e
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

    # Update API operation
    def update(input)
      @cmd = "update"
      records = {}
      numbers = []

      # Extract records into hash
      set = input.xpath(RECORD_XPATH, "marc" => XMLNS_MARC)
      set.each do |record|
        id = record.at_xpath(OCLC_NUM_XPATH, "marc" => XMLNS_MARC).text.slice(/[\d]+/) # Use OCLC number as ID
        records[id] = record
      end

      # Submit records
      records.each_pair do |id, record|
        begin
          if record.namespace_definitions.length == 0
            record["xmlns:marc"] = XMLNS_MARC
          end
          record_id = record.at_xpath(OCLC_NUM_XPATH, "marc" => XMLNS_MARC)
          record_id.content = id # Strip prefix from 001
          r = @client.WorldCatUpdateBibRecord(
            :holdingLibraryCode => @credentials["holdingLibraryCode"],
            :schema => @credentials["schema"],
            :instSymbol => @credentials["instSymbol"],
            :xRecord => record.to_s
          )
          rc = Nokogiri::XML::Document.parse(@client.LastResponseCode.body)
          number = rc.at_xpath(WC_URL_XPATH)
          numbers << number.to_s.slice(/[\d]+/)
        rescue NoMethodError, TypeError, URI::Error => e
          @response_status << e.message + "\n"
        ensure
          @debug_info << @client.debug_info.to_s + "\n\n" + record.to_s + "\n\n"
          manage_record_result(id, rc)
        end
      end

      log_output
    end

    # Set API operation
    def set(input)
      @cmd = "set"
      numbers = []

      # Extract digit strings from file or command-line input
      if File.exists?(input)
        File.open(input, "r").each { |line|
          line.scan(/[\d]+/) { |match| numbers << match }
        }
      else
        input.scan(/[\d]+/) { |match| numbers << match }
        Clop::die "No record numbers found in input" if numbers.length == 0
      end

      # Set holdings
      set_holdings(numbers)

      log_output
    end

    # Unset API operation
    def unset(input)
      @cmd = "unset"
      numbers = []

      # Extract digit strings from file or command-line input
      if File.exists?(input)
        File.open(input, "r").each { |line|
          line.scan(/[\d]+/) { |match| numbers << match }
        }
      else
        input.scan(/[\d]+/) { |match| numbers << match }
        Clop::die "No record numbers found in input" if numbers.length == 0
      end

      # Set holdings
      unset_holdings(numbers)

      log_output
    end

    # Check API operation
    def check(input)
      @cmd = "check"
      numbers = []

      # Extract digit strings from file or command-line input
      if File.exists?(input)
        File.open(input, "r").each { |line|
          line.scan(/[\d]+/) { |match| numbers << match }
        }
      else
        input.scan(/[\d]+/) { |match| numbers << match }
        Clop::die "No record numbers found in input" if numbers.length == 0
      end

      # Check record numbers
      numbers.each do |number|
        begin
          cr = client.WorldCatCheckControlNumbers(
            :oclcNumber => number
          )
          crc = JSON.parse(@client.LastResponseCode.body)
        rescue NoMethodError, TypeError, URI::Error, JSON::ParserError => e
          @response_status << e.message + "\n"
        ensure
          @debug_info << @client.debug_info.to_s + "\n\n"
          manage_check_result(number, crc)
        end
      end

      log_output
    end

    # Validate API operation
    def validate(input)
      @cmd = "validate"
      records = {}

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
          r = @client.WorldCatValidateFull(
            :xRecord => record.to_s
          )
          rc = Nokogiri::XML::Document.parse(@client.LastResponseCode.body)
        rescue NoMethodError, TypeError, URI::Error => e
          @response_status << e.message + "\n"
        ensure
          @debug_info << @client.debug_info.to_s + "\n\n" + record.to_s + "\n\n"
          manage_record_result(id, rc)
        end
      end

      log_output
    end

    # Set holdings API operation
    def set_holdings(input)
      numbers = input.compact # Remove any nil values from create/update errors

      numbers.each do |number|
        begin
          hr = client.WorldCatAddHoldings(
            :oclcNumber => number,
            :holdingLibraryCode => @credentials["holdingLibraryCode"],
            :schema => @credentials["schema"],
            :instSymbol => @credentials["instSymbol"]
          )
          hrc = Nokogiri::XML::Document.parse(@client.LastResponseCode.body)
        rescue NoMethodError, TypeError, URI::Error => e
          @response_status << e.message + "\n"
        ensure
          @debug_info << @client.debug_info.to_s + "\n\n"
          manage_holding_result(number, hrc)
        end
      end

    end

    # Unset holdings API operation
    def unset_holdings(input)
      numbers = input.compact # Remove any nil values from create/update errors

      numbers.each do |number|
        begin
          hr = client.WorldCatDeleteHoldings(
            :oclcNumber => number,
            :holdingLibraryCode => @credentials["holdingLibraryCode"],
            :schema => @credentials["schema"],
            :instSymbol => @credentials["instSymbol"]
          )
          hrc = Nokogiri::XML::Document.parse(@client.LastResponseCode.body)
        rescue NoMethodError, TypeError, URI::Error => e
          @response_status << e.message + "\n"
        ensure
          @debug_info << @client.debug_info.to_s + "\n\n"
          manage_holding_result(number, hrc)
        end
      end

    end

  end
end
