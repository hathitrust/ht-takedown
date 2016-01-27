
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
          @db.execute(command, volume_id, time_window[:start], time_window[:stop])
        end
      end
    end


    def delete_errant_volumes(volumes)
      volumes_literal = "\"#{volumes.keys.join('","')}\""
      command = "delete from results where volume_id not in (#{volumes_literal});"
      @db.execute(command)
    end

  end
end