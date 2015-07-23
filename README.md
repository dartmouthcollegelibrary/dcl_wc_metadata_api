# dcl_wc_metadata_api

WorldCat Metadata API command-line Ruby executable. Intended to support batch creation and download of records in MARCXML. Developed for and in production use at the Dartmouth College Library.

Built upon Terry Reese's [wc-metadata-api](https://github.com/reeset/wc_metadata_api/) and OCLC's [oclc-auth-ruby](https://github.com/OCLC-Developer-Network/oclc-auth-ruby). Bundled with copies of those libraries, distributed under the Apache 2.0 license.

Suggestions, comments, or questions? Contact Shaun Akhtar at shaun.y.akhtar@dartmouth.edu.

## Usage

  dcl-wc-metadata-api [options] <command> <input>

Commands include:

* `read`: Download record(s) from OCLC
* `create`: Upload new record(s) to OCLC and set holding(s)

For read, `<input>` is one or more OCLC numbers (separated only by a comma) or the path of a file containing a list of OCLC numbers, one per line.

For create, `<input>` is the path of a valid MARCXML file containing one or more records.

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

## Installation

Requires Ruby 2.0.0 or greater.

```
git clone https://github.com/akhtars/dcl_wc_metadata_api.git
cd dcl_wc_metadata_api
gem install dcl_wc_metadata_api-<VERSION-NUMBER>.gem
```

External dependencies:

* json
* nokogiri
* rest-client

## API Key and Institutional Data Configuration

A [WSKey](https://platform.worldcat.org/wskey/) with production environment credentials for the WorldCat Metadata API is required. For general information about WSKeys, see the [OCLC Developer Network site](https://www.oclc.org/developer/home.en.html).

key, secret, principalID, principalDNS, holdingLibraryCode, instSymbol

