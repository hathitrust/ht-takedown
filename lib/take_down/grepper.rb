require "securerandom"
module TakeDown
  class Grepper
    def initialize(app_list, volume_list)
      @app_list = app_list
      @volume_list_path = "/tmp/#{SecureRandom.uuid}"
      build_volume_list_file(volume_list, @volume_list_path)
    end

    def grep!(dir_path, output_file_path)
      `bzgrep -Ff #{@volume_list_path} #{dir_path}/* | grep -E "GET (#{@app_list.join('|')})" > #{output_file_path}`
    end

    private

    def build_volume_list_file(volume_list, path)
      File.write(path, volume_list.join("\n"))
    end


  end
end