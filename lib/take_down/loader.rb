
require "sqlite3"
require "time"
require "uri"
require "cgi"

module TakeDown

  class Loader
    def initialize(db_path)
      @line_regex = /\A([^ ]+) [^ ]+ [^ ]+ \[([^\]]*)\] "([^"]*)" ([\d]+) (\d+|-) "[^"]*" "[^"]*"/
      @mfp_regex =  /\A\w+\s(.*)\s\S+\z/
      @db_path = db_path
      @db = nil
    end


    def get_db
      @db ||= create_db
    end


    def load!(access_log_file_path)
      @db = get_db
      current_line = 0
      File.foreach(access_log_file_path) do |line|
        begin
          item = parse_line(line)
        rescue ArgumentError, NoMethodError => e
          puts "#{current_line}::PARSE::#{e.class}::#{line}"
          current_line += 1
          next
        end


        begin
          item[:http_code] = Integer(item[:http_code])
          item[:page_number] = item[:page_number].collect {|p| Integer(p)} # Workaround for this array
          if item[:volume_id] == "1"                               # being randomly frozen, unsure why
            puts "failed on line #{current_line}:::#{item.inspect}"
          end
          if item[:volume_id] && item[:http_code] >= 200 && item[:http_code] < 300
            insert(@db, item[:volume_id], item[:page_number], item[:access_date], item[:ip_token])
          end
        rescue TypeError, SQLite3::ConstraintException => e
          puts "#{current_line}::#{e.class}:::#{item.inspect}"
        end
        current_line += 1
      end
      return self
    end


    # private

    def create_db
      if File.exists? @db_path
        `rm -f #{@db_path}`
      end
      db = SQLite3::Database.new @db_path
      db.execute <<-SQL
        create table results (
          volume_id varchar(40) NOT NULL,
          page_number int NOT NULL,
          access_date datetime NOT NULL,
          ip_token varchar(30) NOT NULL
        );
      SQL
      return db
    end


    def insert(db, volume_id, page_number, access_date, ip_token)
      command = "insert into results values (?, ?, datetime(?), ?);"
      db.execute(command, volume_id, page_number, access_date, ip_token)
    end


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