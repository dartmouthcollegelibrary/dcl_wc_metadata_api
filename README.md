# dcl_wc_metadata_api

Command-line Ruby executable for the Bibliographic Resource and Holdings Resource components of the [WorldCat Metadata API](http://www.oclc.org/developer/develop/web-services/worldcat-metadata-api.en.html). Intended to support batch creation, updating, validation, and download of records in MARCXML. Developed for and in production use at the Dartmouth College Library.

Built upon Terry Reese's [wc-metadata-api](https://github.com/reeset/wc_metadata_api/) and OCLC's [oclc-auth-ruby](https://github.com/OCLC-Developer-Network/oclc-auth-ruby). Bundled with copies of those libraries, distributed under the Apache 2.0 license.

Suggestions, comments, or questions? Contact Shaun Akhtar at <shaun.y.akhtar@dartmouth.edu>.

## Usage

```
dcl-wc-metadata-api [options] <command> <input>
dcl-wc-metadata-api config [<name>=<value> ...]
```

Commands include:

* `read`: Download record(s) from OCLC
* `create`: Upload new record(s) to OCLC and set holding(s)
* `update`: Upload modified record(s) to OCLC
* `set`: Set OCLC holdings
* `unset`: Unset OCLC holdings
* `check`: Get current OCLC number
* `validate`: Perform full OCLC validation (e.g. before create or update)
* `config`: Set or display WSKey credentials and API preferences

For read, set, unset, or check, `<input>` is one or more OCLC numbers (separated only by a comma) or the path of a file containing a list of OCLC numbers, one per line.

For create, update, or validate, `<input>` is the path of a valid MARCXML file containing one or more records.

All records downloaded by a command are saved to a single file in the current working directory.

Options include:

* `-v, --verbose`: Print success status for each item
* `-d, --debug`: Save request URL and body to output log
* `-p, --prefix=<s>`: Append string to output filenames
* `-c, --csv`: Format log as CSV
* `-h, --help`: Show this message

## Examples

### Retrieve records from text file containing OCLC numbers

```
# numbers.txt

908406310
908450886
9000000000000 # Not (yet) a real record number
908450913
```

```
$ dcl-wc-metadata-api -v read numbers.txt

908406310: read
908450886: read
9000000000000: failed
908450913: read
OCLC WorldCat Metadata API: Read operation
Read 3 records and 1 failed
Records written to wc-read-20150723112649.xml
Log written to wc-read-20150723112649-log.txt
```

```xml
# wc-read-20150723112649.xml

<?xml version="1.0"?>
<collection xmlns="http://www.loc.gov/MARC21/slim">
  <record>
        <leader>00000nkm a2200000Ki 4500</leader>
        <controlfield tag="001">ocn908406310</controlfield>
...
```

```xml
# wc-read-20150723112649-log.txt

RESULT(S)

908406310: read
908450886: read
9000000000000: failed
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<error xmlns="http://worldcat.org/xmlschemas/response">
    <code type="application">WS-404</code>
    <message>Unable to locate resource: 9000000000000.</message>
</error>
908450913: read
```

### Create in WorldCat and set holdings on a MARCXML record

```xml
# dwcposters-c078-marc.xml

<?xml version="1.0" encoding="UTF-8"?>
<marc:record xmlns:marc="http://www.loc.gov/MARC21/slim">
   <marc:leader>     nkm  22     Ki 4500</marc:leader>
   <marc:controlfield tag="007">cr||n|</marc:controlfield>
   <marc:controlfield tag="008">150120s1938    xx |||| ||||| o|||ineng d</marc:controlfield>
   <marc:datafield tag="035" ind1=" " ind2=" ">
      <marc:subfield code="a">(DRB)dwcposters-c078</marc:subfield>
   </marc:datafield>
...
```

```
$ dcl-wc-metadata-api create ~/Desktop/dcl-ruby/input/dwcposters-c078-marc.xml

OCLC WorldCat Metadata API: Create operation
Created 1 record and 0 failed
Records written to wc-create-20150803155439.xml
Log written to wc-create-20150803155439-log.txt
```

```xml
# wc-create-20150803155439.xml

<?xml version="1.0"?>
<collection xmlns="http://www.loc.gov/MARC21/slim">
  <record>
        <leader>00000nkm a2200000Ki 4500</leader>
        <controlfield tag="001">ocn915392573</controlfield>
        <controlfield tag="003">OCoLC</controlfield>
        <controlfield tag="005">20150803155434.9</controlfield>
...
```

```
# wc-create-20150803155439-log.txt

RESULT(S)

(DRB)dwcposters-c078: created
915392573: holding set
```

### Set holdings from text file containing OCLC numbers

```
# numbers.txt

12561
97196
108489
181693
234613
```

```
$ dcl-wc-metadata-api -v set numbers.txt

12561: holding set
97196: set holding failed
108489: holding set
181693: holding set
234613: holding set
OCLC WorldCat Metadata API: Set operation
Set 4 records and 1 failed

Log written to wc-set-20220105151005-log.txt
```

```xml
# wc-set-20220105151005-log.txt

RESULT(S)

12561: holding set
97196: set holding failed
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<error xmlns="http://worldcat.org/xmlschemas/response">
    <code type="application">WS-409</code>
    <message>Trying to set hold while holding already exists</message>
</error>
108489: holding set
181693: holding set
234613: holding set
```

### Unset holdings from text file containing OCLC numbers

```
# numbers.txt

8077859
8096970
8726774
```

```
$ dcl-wc-metadata-api -v unset numbers.txt

8077859: holding updated
8096970: holding updated
8726774: update holding failed
OCLC WorldCat Metadata API: Unset operation
Unset 2 records and 1 failed

Log written to wc-unset-20220802152902-log.txt
```

```xml
# wc-unset-20220802152902-log.txt

RESULT(S)

8077859: holding updated
8096970: holding updated
8726774: update holding failed
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<error xmlns="http://worldcat.org/xmlschemas/response">
    <code type="application">WS-409</code>
    <message>Trying to unset hold while holding does not exist</message>
</error>
```

### Check records from text file containing OCLC numbers

```
# numbers.txt

1
6567842 # Has been merged
9000000000000 # Not (yet) a real record number
```

```
$ dcl-wc-metadata-api -c -v check numbers.txt

1,1
6567842,merged with 1
9000000000000,number check failed ("Record not found.")
OCLC WorldCat Metadata API: Check operation
Matched 1 record and 2 failed

Log written to wc-check-20220829154121-log.csv
```

```
# wc-check-20220829154121-log.csv

Record Number,Status,Response
1,1,
6567842,merged with 1,
9000000000000,number check failed ("Record not found."),{"entries"=>[{"title"=>"9000000000000", "content"=>{"requestedOclcNumber"=>"9000000000000", "currentOclcNumber"=>"9000000000000", "institution"=>"DRB", "status"=>"HTTP 404 Not Found", "detail"=>"Record not found.", "id"=>"http://worldcat.org/oclc/9000000000000", "found"=>false, "merged"=>false}, "updated"=>"2022-08-29T19:41:21.033Z"}], "extensions"=>[{"name"=>"os:totalResults", "attributes"=>{"xmlns:os"=>"http://a9.com/-/spec/opensearch/1.1/"}, "children"=>["1"]}, {"name"=>"os:startIndex", "attributes"=>{"xmlns:os"=>"http://a9.com/-/spec/opensearch/1.1/"}, "children"=>["1"]}, {"name"=>"os:itemsPerPage", "attributes"=>{"xmlns:os"=>"http://a9.com/-/spec/opensearch/1.1/"}, "children"=>["1"]}]}
```

### Validate batch of MARCXML records

```xml
# marc-batch-2018062514413340.xml

<?xml version="1.0" encoding="UTF-8"?>
<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">
   <marc:record>
      <marc:leader>     nem  22     Ka 4500</marc:leader>
...
```

```
$ dcl-wc-metadata-api validate marc-batch-2018062514413340.xml

OCLC WorldCat Metadata API: Validate operation
Validated 164 records and 14 failed
Records written to wc-validate-20181002114734.xml
Log written to wc-validate-20181002114734-log.txt
```

```xml
# wc-validate-20181002114734.xml

<?xml version="1.0"?>
<collection xmlns="http://www.loc.gov/MARC21/slim">
  <record>
        <leader>00000nem a2200000Ka 4500</leader>
...
```

```
# wc-validate-20181002114734-log.txt

RESULT(S)

(DRB)Burnt_Mountain_1993: validated
(DRB)Connecticut_River_1828: validated
(DRB)DOC_Trails_1990: failed
<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:oclc="http://worldcat.org/xmlschemas/response">
...
<oclc:error>
  <oclc:code type="application">CAT-VALIDATION</oclc:code>
  <oclc:message>Record is invalid</oclc:message>
  <oclc:detail type="application/xml">
    <validationErrors xmlns="">
      <validationError type="variable field">
        <field occurrence="2" name="043"/>
        <message>043 occurs too many times.</message>
      </validationError>
    </validationErrors>
  </oclc:detail>
</oclc:error>
```

## Installation

Requires Ruby 2.0.0 or greater. Developed on Ruby 2.0.0p576, Ruby 2.4.3p205, and Ruby 2.7.5p203.

```
$ git clone https://github.com/dartmouthcollegelibrary/dcl_wc_metadata_api.git
$ cd dcl_wc_metadata_api
$ gem build dcl_wc_metadata_api.gemspec
$ gem install dcl_wc_metadata_api-<VERSION-NUMBER>.gem
```

External dependencies:

* json
* nokogiri
* rest-client

## API Key and Institutional Data Configuration

A [WSKey](https://platform.worldcat.org/wskey/) with production environment credentials for the WorldCat Metadata API is required. For general information about WSKeys, see the [OCLC Developer Network site](https://www.oclc.org/developer/home.en.html).

Before any other commands, config must be used to set the following fields: `key`, `secret`, `principalID`, `principalDNS`, `schema`, `holdingLibraryCode`, `instSymbol`. Without any arguments, config displays the fields currently set.

Example:

```
$ dcl-wc-metadata-api config key=my-key secret=my-secret principalID=my-id principalDNS=my-dns schema=LibraryOfCongress holdingLibraryCode=DRBB instSymbol=DRB
```

Credentials are currently stored at /config/credentials.yml in the gem's installation directory.

## License

Copyright 2015 Trustees of Dartmouth College

Made available under the Apache License, version 2.0. For details, see [LICENSE](https://github.com/akhtars/dcl_wc_metadata_api/blob/master/LICENSE).
