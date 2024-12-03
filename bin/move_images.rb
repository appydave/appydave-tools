#!/usr/bin/env ruby
# frozen_string_literal: true

# CHAT: https://chatgpt.com/c/67038d52-9928-8002-8063-5616f7fe7aef

# !/usr/bin/env ruby

require 'fileutils'
require 'optparse'

# Default base directory
base_dir = '/Volumes/Expansion/Sync/tube-channels/video-projects'

# Common subfolder names (for reference, not enforced)
# Common subfolders: intro, outro, content, teaser, thumb

# Parse command-line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} -f <folder> <section> <prefix>"

  opts.on('-f FOLDER', '--folder FOLDER', 'Specify the subfolder under video-projects') do |folder|
    options[:folder] = folder
  end
end.parse!

# Ensure the folder option is provided
unless options[:folder]
  puts 'You must specify a folder using the -f option'
  exit 1
end

# Set source and destination directories
source_dir = File.expand_path('~/Sync/smart-downloads/download-images')
dest_dir = File.join(base_dir, options[:folder], 'assets')

# Get input parameters
section = ARGV[0]
prefix = ARGV[1]

unless prefix && section
  puts "Usage: #{$PROGRAM_NAME} -f <folder> <section> <prefix>"
  exit 1
end

# Ensure the section subfolder exists
section_dir = File.join(dest_dir, section)
puts "Creating subfolder if it doesn't exist: #{section_dir}"
FileUtils.mkdir_p(section_dir)

puts "Source directory: #{source_dir}"

# Find and move the images
Dir.glob("#{source_dir}/*.jpg").each_with_index do |file, index|
  puts "Processing #{file}, #{index}"
  new_filename = "#{prefix}-#{section}-#{index + 1}.jpg"
  puts "New filename: #{new_filename}"
  destination = File.join(section_dir, new_filename)
  puts "Destination: #{destination}"
  FileUtils.mv(file, destination)
  puts "Moved #{file} to #{destination}"
end
