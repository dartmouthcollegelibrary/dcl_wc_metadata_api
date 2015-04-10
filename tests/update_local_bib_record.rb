require 'rubygems'
require 'wc_metadata_api'

key = '[your key]'
secret = '[your secret]'
principalid = '[your principal_id]'
principaldns = '[your principal_idns]'
schema = 'LibraryOfCongress'
holdingLibraryCode='[your holding code]'
instSymbol = '[your oclc symbol]'



rec =  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
       "<record xmlns=\"http://www.loc.gov/MARC21/slim\">\n" + 
        "<leader>00000n   a2200000   4500</leader>\n" + 
	"<controlfield tag=\"001\">338544583</controlfield>\n" +
        "<controlfield tag=\"004\">879649505</controlfield>\n" + 
        "<controlfield tag=\"005\">20140514221305.3</controlfield>\n" + 
        "<datafield tag=\"500\" ind1=\" \" ind2=\" \">\n" + 
        "<subfield code=\"a\">This is a local record note.</subfield>\n" + 
        "</datafield>\n" + 
	"<datafield tag=\"500\" ind1=\" \" ind2=\" \">\n" + 
	"<subfield code=\"a\">This is a second description field in the local record.</subfield>\n" + 	     "</datafield>\n" + 
        "<datafield tag=\"935\" ind1=\" \" ind2=\" \">\n" + 
        "<subfield code=\"a\">1400104404</subfield>\n" + 
        "</datafield>\n" + 
        "<datafield tag=\"940\" ind1=\" \" ind2=\" \">\n" + 
        "<subfield code=\"a\">OCPSB</subfield>\n" + 
        "</datafield>\n" + 
        "</record>"


client = WC_METADATA_API::Client.new(:wskey => key, :secret => secret, :principalID => principalid, :principalDNS => principaldns, :debug =>false)


response = client.WorldCatUpdateLocalBibRecord(:holdingLibraryCode => holdingLibraryCode, :schema => schema, :instSymbol => instSymbol, :xRecord => rec)

puts client.LastResponseCode.body
