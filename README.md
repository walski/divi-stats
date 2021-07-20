# DIVI Stats

Process ICU occupation stats from Germany using the [daily reports from the DIVI database](https://www.divi.de/register/tagesreport) ([Wikipedia](https://de.wikipedia.org/wiki/Deutsche_Interdisziplin%C3%A4re_Vereinigung_f%C3%BCr_Intensiv-_und_Notfallmedizin))

**100% work in progress**

## Usage

### Download all CSVs

```ruby
# First download/cache all details pages (mandatory)
DiviStats::CsvPuller.new.download_all_pages
# Then download/cache all CSVs
DiviStats::CsvPuller.new.download_all_csvs
```


### Build Data DB from downloaded CSVs

```ruby
db = DiviStats::ParseCsvs.new.build_db; nil
```