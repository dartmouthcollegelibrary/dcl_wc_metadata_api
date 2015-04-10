require 'rubygems'
require 'wc_metadata_api'

key = '[your key]'
secret = '[your secret]'
principalid = '[your principal_id]'
principaldns = '[your principal_idns]'
schema = 'LibraryOfCongress'
holdingLibraryCode='[your holding code]'
instSymbol = '[your oclc symbol]'

client = WC_METADATA_API::Client.new(:wskey => key, :secret => secret, :principalID => principalid, :principalDNS => principaldns, :debug =>false)

response = client.WorldCatRetrieveHoldingCodes(:instSymbol => instSymbol)
puts response

