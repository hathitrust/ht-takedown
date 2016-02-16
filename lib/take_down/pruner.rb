
require "sqlite3"
require "time"
module TakeDown

  class Pruner
    def initialize(db)
      @db = db
    end

    def prune!(volumes)
      delete_safe_times(volumes)
      delete_errant_volumes(volumes)
      return self
    end

    private

    def delete_safe_times(volumes)
      command = "delete from results where volume_id=? and access_date not between datetime(?) and datetime(?);"
      volumes.keys.each do |volume_id|
        volumes[volume_id].each do |time_window|
          puts "Executing: #{command.sub('?', volume_id).sub('?', time_window["start"].iso8601).sub('?', time_window["end"].iso8601)}"
          @db.execute(command, volume_id, time_window["start"].iso8601, time_window["end"].iso8601)
        end
      end
    end


    def delete_errant_volumes(volumes)
      volumes_literal = "\"#{volumes.keys.join('","')}\""
      command = "delete from results where volume_id not in (#{volumes_literal});"
      puts "Executing: #{command}"
      @db.execute(command)
    end

  end
end