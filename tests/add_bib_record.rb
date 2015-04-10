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
       "<leader>00000nam a2200000Ia 4500</leader>\n" +
       "<controlfield tag=\"008\">120827s2012    nyua          000 0 eng d</controlfield>\n" +
       "<datafield tag=\"040\" ind1=\" \" ind2=\" \">\n" +
       "<subfield code=\"a\">OCPSB</subfield>\n" +
       "<subfield code=\"c\">OCPSB</subfield>\n" +
       "</datafield>\n" +
       "<datafield tag=\"100\" ind1=\"0\" ind2=\" \">\n" +
       "<subfield code=\"a\">Reese, Terry</subfield>\n" +
       "</datafield>\n" +
       "<datafield tag=\"245\" ind1=\"0\" ind2=\"0\">\n" +
       "<subfield code=\"a\">Record Builder Added This Test Record On 05/14/2014</subfield>\n" +
       "</datafield>\n" +
       "<datafield tag=\"500\" ind1=\" \" ind2=\" \">\n" +
       "<subfield code=\"a\">Original Record has one field.</subfield>\n" +
       "</datafield>\n" +
       "</record>\n"

client = WC_METADATA_API::Client.new(:wskey => key, :secret => secret, :principalID => principalid, :principalDNS => principaldns, :debug =>false)


response = client.WorldCatAddBibRecord(:holdingLibraryCode => holdingLibraryCode, :schema => schema, :instSymbol => instSymbol, :xRecord => rec)

puts client.LastResponseCode.body
