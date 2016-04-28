
require "sqlite3"
require "time"
require "uri"
require "cgi"

module TakeDown

  # This class is responsible for parsing log lines and 
  # inserting the results into a database. 
  class Loader
    
    # Create a Loader
    # @param db_path [String] Path of where to create the database.
    def initialize(db_path)
      @line_regex = /\A([^ ]+) [^ ]+ [^ ]+ \[([^\]]*)\] "([^"]*)" ([\d]+) (\d+|-) "[^"]*" "[^"]*"/
      @mfp_regex =  /\A\w+\s(.*)\s\S+\z/
      @db_path = db_path
      @db = nil
    end

    
    # @return [SQLite3::Database]
    def get_db
      @db ||= create_db
    end


    # Parse and load all lines from the given file into
    # the database.  Note that accesses without a page number
    # are assigned the page number -1.
    # @param access_log_file_path [String] Path to the file
    #  containing the access log lines.
    # @return [Loader]
    def load!(access_log_file_path)
      @db = get_db
      current_line = 0
      File.foreach(access_log_file_path) do |line|
        begin
          item = parse_line(line)
        rescue ArgumentError, NoMethodError => e
          error_line("PARSE", current_line, [], line, e)
          current_line += 1
          next
        end


        begin
          item[:http_code] = Integer(item[:http_code])
          item[:page_number] = item[:page_number].collect do |p|
            # We don't use collect! because this array gets frozen somehow.
            if [nil, ""].include?(p)
              p = -1
              error_line("NOPAGE", current_line, item, line, -1)
            end
            Integer(p)
          end

          if item[:volume_id] == "1"
            error_line(current_line, item, line, nil)
          end

          if item[:volume_id] && item[:http_code] >= 200 && item[:http_code] < 300
            insert(@db, item[:volume_id], item[:page_number], item[:access_date], item[:ip_token])
          end

        rescue ArgumentError, TypeError, SQLite3::ConstraintException => e
          error_line("INSERT", current_line, item, line, e)
        end
        current_line += 1
      end
      return self
    end


    # private

    # Give a reasonable error output if a line can't be parsed.
    def error_line(comment, line_number, item, line, exception = nil)
      puts "#{comment}::#{line_number}::#{exception.class}::#{item}::::#{line}"
    end


    # Create the database.
    # @return [SQLite3::Database]
    def create_db
      if File.exists? @db_path
        raise RuntimeError, "Database at #{@db_path} exists, delete it or skip this step."
      else
        db = SQLite3::Database.new @db_path
        db.execute <<-SQL
        create table results (
          volume_id varchar(40) NOT NULL,
          page_number int NOT NULL,
          access_date datetime NOT NULL,
          ip_token varchar(30) NOT NULL
        );
        SQL
      end
      return db
    end


    # Insert a parsed record into the database.
    def insert(db, volume_id, page_number, access_date, ip_token)
      command = "insert into results values (?, ?, datetime(?), ?);"
      db.execute(command, volume_id, page_number, access_date, ip_token)
    end


    # Parse a single line.
    def parse_line(line)
      host_ip, date, method_file_protocol, http_code, _ = @line_regex.match(line).captures
      file = @mfp_regex.match(method_file_protocol).captures[0]
      ip_token = host_ip.split(':')[1]

      date = Time.strptime(date, '%d/%b/%Y:%H:%M:%S %z').iso8601
      query_params = CGI::parse(URI(file).query)

      return {
        access_date: date,
        ip_token: ip_token,
        page_number: query_params["seq"] || -1,
        http_code: http_code,
        volume_id: query_params["id"]
      }
    end


  end
end