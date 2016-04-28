
require "sqlite3"
require "time"
module TakeDown

  # This class eliminates results that should not 
  # be included.
  class Pruner
    
    # Create a Pruner
    # @param db [SQLite3::Database] A database populated with records.
    def initialize(db)
      @db = db
    end

    # Prune the database to contain only accesses for the volumes we 
    # care about, during the times we care about.
    # @param volumes[Hash<String,Array<Hash<String,Time>>>] A hash
    #   of volumes by volume_id.  Each key should contain an array 
    #   time windows (as Hash<String,Time>), where the keys in the
    #   time window are "start" and "end".
    #   
    #   See the example job file for more info.
    # @return [Pruner]
    def prune!(volumes)
      delete_safe_times(volumes)
      delete_errant_volumes(volumes)
      return self
    end

    private
    
    # Delete accesses to a volume that are not within the
    # time windows we care about.
    def delete_safe_times(volumes)
      volumes.keys.each do |volume_id|
        command = "delete from results where volume_id=?"
        options = [volume_id]
        volumes[volume_id].each do |time_window|
          command += "\n  and access_date not between datetime(?) and datetime(?)"
          options += [time_window["start"].iso8601, time_window["end"].iso8601]
        end
        command += ";"
        command_literal = command
        options.each { |opt| command_literal.sub!(opt)} # Don't ever do this.
        puts "Executing: #{command_literal}\n"
        @db.execute(command, *options)
      end
    end

    
    # Delete accesses of volumes we don't care about.
    # Grepper already does this, but encapsulation and all that jazz.
    def delete_errant_volumes(volumes)
      volumes_literal = "\"#{volumes.keys.join('","')}\""
      command = "delete from results where volume_id not in (#{volumes_literal});"
      puts "Executing: #{command}"
      @db.execute(command)
    end

  end
end