wc_metadata_api
===============

Ruby wrapper around the WorldCat Metadata API

Dependencies:
* Requires the OCLC Auth gem.  Get from: https://github.com/OCLC-Developer-Network/oclc-auth-ruby before building.

Test files are found in the tests directories.  Demonstrates all the functions.

At this point, the gem is light on the exception handling.  The current todo:
1) Add better exception handling
2) Include helper functions to simplify data processing and reading (so you don't have to just deal with MARCXML)

Example:
** Get a Bib Record
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


response = client.WorldCatGetBibRecord(:oclcNumber => '879376100', :holdingLibraryCode => holdingLibraryCode, :schema => schema, :instSymbol => instSymbol)


puts response


** Get Local Bib Record
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


response = client.WorldCatReadLocalBibRecord(:oclcNumber =>'338544583', :schema => schema, :holdingLibraryCode => holdingLibraryCode, :instSymbol => instSymbol)
puts response


Questions: reeset@gmail.com
