
# ons_postcode_extractor

A command-line Ruby app that extracts, filters, and enriches data from the Office of National Statistics (ONS) Postcode Directory (ONSPD) CSV files.

## Usage
To run this app, **you must have Ruby version 3.3.0 or higher installed locally**.

Fork this directory and pull to your local machine.

Ensure that all app dependencies are installed by running:
```
bundle install
```

To execute the app on an input CSV file, run the following, replacing the path with the path to the downloaded ONS data.

```
ons_postcode_extractor process path/to/ONSPD.csv
```
The app currently only works with CSV files.  It accepts an input file path, and will produce an output file in the same directory.

### Downloading as ZIP
If you download the repo as a ZIP file, you may need to run the following before you can execute the process job:
```
chmod +x bin/ons_postcode_extractor
```

## Background
This application is designed to process the ONS's Postcode Directory, which is published in a variety of formats, including CSV.

The data set is published periodically, or is available as a live dataset from ONS's site, free of charge.

The data, in its entirety, is an incredibly large set, with a CSV file in excess of 800MB.

The purpose of this app is to extract pertinent data for each active, geographic postcode from this large set.

## ONS Data
The LIVE ONSPD can be downloaded here: https://open-geography-portalx-ons.hub.arcgis.com/datasets/ons::online-ons-postcode-directory-live/about

In addition, ONS periodically publishes a full data set, which is broken up into postcode areas.

The latest available as of October 2025, is the Aug 2025 data set: https://geoportal.statistics.gov.uk/datasets/295e076b89b542e497e05632706ab429/about

The data is re-released roughly every quarter.

## Functionality
This app extracts certain columns, removes non-geographic and terminated data, and adds additional information.

### Retained Columns
The extractor retains the following columns from the ONSPD:
- `pcsd`
  - The formatted postcode, in readable text
  - e.g. 'WD18 2BB', 'SW1A 1SA', etc.
- `dointr`
  - The date that the postcode was introduced in `YYYYMM`
- `east1m`
  - The Easting coordinate (in metres) of the postcode centroid, based on the Ordnance Survey National Grid reference system (OSGB36). It represents the distance east from the grid origin.
- `north1m`
  - The Northing coordinate (in metres) of the postcode centroid, based on the same OS National Grid system. It represents the distance north from the grid origin.
- `lat`
  - The latitude coordinate of the central point of the postcode.
- `long`
  - The longitude coordinate of the central point of the postcode.
- `lad25cd`
  - The ONS code for the Local Authority that the postcode falls within.

### Additional Columns
In addition to these extracted columns, the app will also add the following:
- `local_authority`
  - The name of the Local Authority that corresponds to the `lad25cd`.
- `town`
  - The [Post Town](https://en.wikipedia.org/wiki/Post_town) that the postcode falls within.

### Removed Data
#### Terminated Postcodes
The ONSPD contains not only active postcodes, but all terminated ones as well.  Terminated postcodes are defunct, and their termination is confirmed within the ONSPD by the presence of a DOTERM value (the date that the postcode was terminated).

The app will remove any terminated postcodes from the output CSV.

#### Non-Geographic Postcodes
A number of postcodes exist as non-geographic locations.  Often, these are things like PO Boxes or postcodes for specific governmental institutions.

Non-geographic postcodes can be identified within the ONSPD by their coordinates, which will have a latitude of either 100 or 99.9999.

The app removes all non-geographic postcodes from the output CSV.

### Warnings & Errors
#### Missing Columns
ONS sometimes alters the format of their data (for example, the `EAST1M` and `NORTH1M` columns recently replaced `OSEAST1M` and `OSNRTH1M`).

Should this occur, the app will error and exit gracefully:
```
"❌ #{message} - ONS data structure may have changed. Consult README."
```
The `message` will be the details of the `MissingColumnsError` that has been raised, which will include any expected columns that are missing.

If this occurs, the column header can be altered within the downloaded file to patch in the immediate.

However, if it is confirmed that ONS has changed the data structure, or header names, an issue should be raised, or a pull request made with the alteration.
#### Bad Command or Missing / Invalid File
The app will exit gracefully, if an invalid command is passed in.

Currently, the only valid command is `process`.

Likewise, if no file path is provided, or the path does not link to a valid file, the app will also exit.

### Unknown LAD25CD (Local Authority ID)
This is the unique ONS code for a Local Authority.  Local Authorities are sometimes changed, divided, or created, and the app may not have all of the latest codes.

If an unknown LAD25CD is included in the input file, the following warning will appear:
```
"⚠️ LAD25CD #{ons_reference} not found. List of references may need to be updated."
```

If a new code has been created, an issue should be reported, or the new authority added to the `data/local_authorities.rb` hash of authorities, and a pull request made.

### Invalid Postcode Warning
The app uses the [`uk_postcode`](https://github.com/threedaymonk/uk_postcode) gem to parse and validate the postcodes within the ONSPD.

Should a postcode appear to be invalid or incomplete, a warning will appear.  For example, if the input postcode is `'BATMAN'`, the following warning will appear:
```
"⛔️ Postcode Failed Validation: BATMAN. Check data."
```
As the ONSPD includes an active list of all postcodes, it is unlikely that this warning will appear, unless the data is altered.

### Unknown Outcode
The app applies a town value, based on Regex matchers for each postcode outcode.

New postcode outcodes are sometimes created by Royal Mail, and, if that is the case, then the matches may not find a town that matches the pattern.  If that is the case, then a warning will appear.  For example, if a new postcode area E23 is created, the following will appear:

```
"⚠️ Outcode E23 not found. Regex data may need to be updated."
```
If this occurs, then an issue should be raised, or a pull request made with the amended Regex matcher.

### Multiple Town Matches
Some postcode outcodes cover more than one Post Town (for example, the BR2 postcode covers both Bromley and Keston).  In the unlikely event that a new postcode matches more than one Regex pattern, the following warning will appear.  For example, if BR2 6AA matched more than one pattern, the following will appear.
```
"⚠️ Multiple possible matches for BR2 6AA. Regex data may need to be updated."
```
If this occurs, then an issue should be raised, or a pull request made with the amended Regex matcher.

## Limitations of Town Matchers
There are a handful of instances where a postcode outcode covers many different Post Towns, with very granular levels of assignment.

For example, the outcode SY24:
| Postcode | Post Town |
|-----------|-----------|
| SY24 5AA   | Bow Street   |
| SY24 5EA   | Talybont   |
| SY24 5JA   | Borth  |

Every effort is made to correctly match postcodes even where the split is this granular.  However, new postcodes may be created that do not accurately match the existing patterns.

If this is noted, and you believe a town value to be incorrectly assigned to a postcode, then an issue should be raised, or a pull request made with the amended Regex matcher.

## Adding New Features
The app is currently limited to extracting these specific pieces of data.  However, further features should be added to allow the user to select other data they wish to extract.

It should also be possible to add more data to the app to match different ONS data codes to a named instance in the pertinent table.

For example, the name of the Local Authority is already provided.  We could also look to apply other data, such as the Police Force.

### Testing
The app utilises an RSpec suite of tests.  Any significant alterations to the code, including bug fixes or new features, should be fully tested with new specs covering the functionality.
