> :warning: If we want to collect log data, this is not the way to do it. Do not use this.

# ht-takedown
A tool to collect log data in response to takedown requests

## Usage

1. Examine the rights database to find the time periods each volume was available.
2. Place this code on a machine with appropriate log access.
3. If necessary, ```bundle install --path vendor/bundle```
3. Create a jobfile, using data/example_jobfile.yml as a guide.
4. ```bin/take_down.rb /path/to/your/jobfile```

## Requirements

* sqlite3
* ruby
* bundler
* Local access to logs

## Improvements

1. ~~Grepping the logs takes on the order of 4 hours, but you're most likely
   to experience problems later on in the process.  At present, there's
   no way to pause a job or restart a failed job.~~  
2. Accesses that do not access a page number are represented as accessing
   page -1.  This is probably not correct.
