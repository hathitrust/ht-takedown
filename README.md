# ht-takedown
A tool to collect log data in response to takedown requests

## Usage

1. Examine the rights database to find the time periods each volume was available.
2. Place this code on a machine with appropriate log access.
3. If necessary, ```bundle install --path vendor/bundle```
3. Create a jobfile, using data/example_jobfile.yml as a guide.
4. ```ruby bin/take_down.rb /path/to/your/jobfile```

## Requirements

* sqlite3
* Local access to logs
