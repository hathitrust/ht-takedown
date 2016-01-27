require_relative "./queryer"
require "time"

module TakeDown

  class Reporter

    def initialize(queryer)
      @queryer = queryer
      @data = nil
      @total_accesses_by_volume = nil
      @total_users_by_volume = nil
      @report = nil
    end


    def add_volume_to_report(volume_id, start_time, end_time)
      data[volume_id] ||= {}
      data[volume_id][:total_accesses] ||= 0
      data[volume_id][:start] = start_time
      data[volume_id][:end] = end_time
    end


    def report
      @report ||= build_report
    end


    private


    def build_report
      report = []
      report[0] = "Total accesses across all volumes: #{data[:total_accesses]}"
      report[0] += "\nMaximum total users across all volumes: #{data[:total_users]}"
      (data.keys - [:total_accesses, :total_users]).each do |volume_id|
        report << report_for_volume(volume_id)
      end
      return report.join("\n\n----------------------------------------------------------------------\n\n") + "\n\n"
    end


    def data
      @data ||= collect_data
    end


    def collect_data
      data = {}
      data[:total_accesses] = @queryer.total_accesses
      data[:total_users] = @queryer.total_max_users

      @queryer.total_accesses_by_volume.each do |volume_id, num_acceses|
        data[volume_id] = {}
        data[volume_id][:total_accesses] = num_acceses
        data[volume_id][:pages] = @queryer.pages_for_volume(volume_id) || []
        data[volume_id][:accesses] = @queryer.accesses_for_volume(volume_id)
      end

      @queryer.total_max_users_by_volume.each do |volume_id, num_users|
        data[volume_id][:total_users] = num_users
      end
      return data
    end


    def report_for_volume(volume_id)
      report = "Identifier: #{volume_id}"
      report += "\n\tAvailability began: #{data[volume_id][:start]}"
      report += "\n\tAvailability ended: #{data[volume_id][:end]}"
      if data[volume_id][:total_accesses] > 0
        report += "\n\tThere were #{data[volume_id][:total_accesses]} accesses during this period "
        report += "for at most #{data[volume_id][:total_users]} users."
        report += "\n\tPages accessed: #{data[volume_id][:pages].size} total:"
        data[volume_id][:pages].sort.each_slice(10).each do |segment|
          report += "\n\t\t#{segment.join(",")}"
        end
        report += "\n\tDetailed access information:"
        report += "\n\t\tpage_number | access date | anonymized ip"
        data[volume_id][:accesses].each do |access|
          report += "\n\t\t#{access.join(" | ")}"
        end
      else
        report += "\n\tThis volume was not accessed during this period."
      end
      return report
    end


  end

end