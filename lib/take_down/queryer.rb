
require "sqlite3"
require "time"

module TakeDown

  class Queryer
    def initialize(db)
      @db = db
    end

    # Total number of accesses
    # @return [Fixnum]
    def total_accesses
      command = <<-SQL
        select count(*)
        from results;
      SQL
      @db.execute(command)[0][0]
    end


    # Total number of unique ip tokens
    # This is the maximum number of users
    # that accessed the volumes
    # @return [Fixnum]
    def total_max_users
      command = <<-SQL
        select count(distinct ip_token)
        from results;
      SQL
      @db.execute(command)[0][0]
    end


    # By volume, number of total accesses
    # @return [Array<Array<String, Fixnum>>] Array of
    #   arrays of volume_id, count(accesses)
    def total_accesses_by_volume
      command = <<-SQL
        select volume_id, count(*)
        from results
        group by volume_id;
      SQL
      @db.execute(command)
    end


    # By volume, max number of unique users
    # @return [Array<Array<String, Fixnum>>] Array of
    #   arrays of volume_id, count(users)
    def total_max_users_by_volume
      command = <<-SQL
        select volume_id, count(distinct ip_token)
        from results
        group by volume_id;
      SQL
      @db.execute(command)
    end


    # By volume, get the accessed pages
    # @return [Array<Array<Fixnum>> ]
    #   Array of arrays of page_number
    def pages_for_volume(volume_id)
      command = <<-SQL
        select distinct page_number
        from results
        where volume_id=?
      SQL
      @db.execute(command, volume_id).flatten
    end


    # For the given volume, show each access.
    # @param volume_id [String]
    # @return [Array<Array<Fixnum, Time, String>>]
    #   Array of arrays of page_number, access_date, ip_token
    def accesses_for_volume(volume_id)
      command = <<-SQL
        select page_number, access_date, ip_token
        from results
        where volume_id=?
        order by page_number asc, ip_token desc;
      SQL
      @db.execute(command, volume_id)
    end


    # For the given user token, show each access.
    # @param ip_token [String]
    # @return [Array<Array<String, Fixnum, Time>>]
    #   Array of arrays of volume_id, page_number, access_date
    def accesses_for_user(ip_token)
      command = <<-SQL
        select volume_id, page_number, access_date
        from results
        where ip_token=?
        order by volume_id asc, page_number asc;
      SQL
      @db.execute(command, ip_token)
    end

  end

end