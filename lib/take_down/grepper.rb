require "securerandom"
module TakeDown
  # This class is responsible for filtering logs for lines that
  # contain an access for a volume AND an app we're searching for.
  class Grepper
    # Create a grepper instance.  
    # @param app_list [Array<String>] List of apps to search
    # @param volume_list [Array<String>] List of volumes to search
    def initialize(app_list, volume_list)
      @app_list = app_list
      @volume_list_path = "/tmp/#{SecureRandom.uuid}"
      build_volume_list_file(volume_list, @volume_list_path)
    end

    # Using the app and volume lists, search all files
    # under the dir_path for successful GET requests
    # that are for both a volume and an app we care about.
    # 
    # Output the full line into the output_file_path.
    # @param dir_path [String] Path of the parent dir of the logs.
    # @param output_file_path [String] Path of the file to put
    #   the results
    def grep!(dir_path, output_file_path)
      `bzgrep -Ff #{@volume_list_path} #{dir_path}/* | grep -E "GET (#{@app_list.join('|')})" > #{output_file_path}`
    end

    private

    # bzgrep won't take a command line list (that I know of), 
    # but it will take a file with a list.  This creates that file.
    def build_volume_list_file(volume_list, path)
      File.write(path, volume_list.join("\n"))
    end


  end
end