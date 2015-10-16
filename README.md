# dcl_wc_metadata_api

Command-line Ruby executable for the Bibliographic Resource component of the [WorldCat Metadata API](http://www.oclc.org/developer/develop/web-services/worldcat-metadata-api.en.html). Intended to support batch creation and download of records in MARCXML. Developed for and in production use at the Dartmouth College Library.

Built upon Terry Reese's [wc-metadata-api](https://github.com/reeset/wc_metadata_api/) and OCLC's [oclc-auth-ruby](https://github.com/OCLC-Developer-Network/oclc-auth-ruby). Bundled with copies of those libraries, distributed under the Apache 2.0 license.

Suggestions, comments, or questions? Contact Shaun Akhtar at <shaun.y.akhtar@dartmouth.edu>.

## Usage

  dcl-wc-metadata-api [options] <command> <input>
  dcl-wc-metadata-api config [<name>=<value> ...]

Commands include:

* `read`: Download record(s) from OCLC
* `create`: Upload new record(s) to OCLC and set holding(s)
* `update`: Upload modified record(s) to OCLC
* `config`: Set or display WSKey credentials and API preferences

For read, `<input>` is one or more OCLC numbers (separated only by a comma) or the path of a file containing a list of OCLC numbers, one per line.

For create or update, `<input>` is the path of a valid MARCXML file containing one or more records.

All records downloaded by a command are saved to a single file in the current working directory.

Options include:

* `-v, --verbose`: Print success status for each item
* `-d, --debug`: Save request URL and body to output log
* `-p, --prefix=<s>`: Append string to output filenames
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
Read 3 records, 1 failed
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
Created 1 record, 0 failed
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

## Installation

Requires Ruby 2.0.0 or greater. Known to run on Linux. Windows support is forthcoming.

```
$ git clone https://github.com/akhtars/dcl_wc_metadata_api.git
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
