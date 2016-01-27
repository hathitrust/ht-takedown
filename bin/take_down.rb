#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require_relative "../lib/take_down"

job_file = ARGV[0]

if ["help", "-h", "--help"].include?(ARGV[0])
  puts "You must supply a jobfile."
  puts "An example can be found in #{File.join(TakeDown.path, "data/example_jobfile.yml")}"
  exit
end

if job_file && File.exists?(job_file)
  TakeDown.execute(job_file)
else
  puts "Please supply a path to the jobfile"
  exit
end

puts ""