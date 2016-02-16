require_relative "take_down/grepper"
require_relative "take_down/loader"
require_relative "take_down/pruner"
require_relative "take_down/queryer"
require_relative "take_down/reporter"
require_relative "take_down/job"
require "yaml"
require "pathname"

module TakeDown
  def self.path
    @path ||= Pathname.new(__FILE__).parent.parent.realdirpath.to_s
  end

  def self.execute(job_file)
    # load files
    job = Job.new(YAML.load_file(job_file))
    app_list = YAML.load_file(File.join(path, "data/app_list.yml" ))[:apps]
    
    # create an output directory
    output_dir = File.join(job[:output_dir], job[:ticket])
    `mkdir -p #{output_dir}`
    access_log_dir = File.join(output_dir, ".access_logs")
    `mkdir -p #{access_log_dir}`
    
    # detect progress
    progress_file = File.join(output_dir, "progress.yml")
    progress = Job.new(YAML.load_file(progress_file))

    # setup the grepper
    grepper = Grepper.new(app_list, job[:volumes].keys)

    # Get the folders we need
    log_dirs = Dir.entries(job[:parent_dir]).select { |entry| File.directory? File.join(job[:parent_dir], entry )}
    log_dirs -= [".", ".."]
    log_dirs -= (job[:skip_dirs] || [])

    # Begin grepping folders
    unless progress[:grepper]
      grepped_access_logs = []
      log_dirs.each do |relative_dir|
        output_file_path = File.join access_log_dir, "#{relative_dir}-access.log"
        grepped_access_logs << output_file_path
        grepper.grep!(File.join(job[:parent_dir], relative_dir), output_file_path)
      end
      progress[:grepper] = true
      File.write(progress_file, progress.to_yaml)
    end

    # Load into sql
      db_path = File.join output_dir, ".results.db"
      loader = Loader.new(db_path)
    unless progress[:loader]
      grepped_access_logs.each do |grepped_access_log|
        loader.load!(grepped_access_log)
      end
      progress[:loader] = true
      File.write(progress_file, progress.to_yaml)
    end


    # Prune things we don't want
    unless progress[:pruner]
      pruner = Pruner.new(loader.get_db)
      pruner.prune!(job[:volumes])
      progress[:pruner] = true
      File.write(progress_file, progress.to_yaml)
    end

    # Gather report data
    reporter = Reporter.new(Queryer.new(loader.get_db))
    job[:volumes].keys.each do |volume_id|
      job[:volumes][volume_id].each do |time_window|
        start_time = time_window[:start]
        end_time = time_window[:end]
        reporter.add_volume_to_report(volume_id, start_time, end_time)
      end
    end

    # Write the report
    File.write(File.join(output_dir, "report.txt"), reporter.report)

    # Cleanup temporary files
    `rm -f #{File.join(access_log_dir, "*")}`
    `rm -f #{db_path}`
  end
end

