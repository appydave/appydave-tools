#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

# Process command line arguments for YouTubeVideoManager operations
class YouTubeVideoManagerCLI
  include KLog::Logging

  def initialize
    @commands = {
      'get' => method(:fetch_video_details)
      # Additional commands can be added here
    }
  end

  def run
    command, *args = ARGV
    if @commands.key?(command)
      @commands[command].call(args)
    else
      puts "Unknown command: #{command}"
      print_help
    end
  end

  private

  def fetch_video_details(args)
    options = parse_options(args, 'get')
    manager = Appydave::Tools::YouTubeManager::GetVideo.new
    manager.get(options[:video_id])

    if manager.video?
      # json = JSON.pretty_generate(details)
      # puts json

      # report = Appydave::Tools::YouTubeManager::Reports::VideoDetailsReport.new
      # report.print(manager.data)

      report = Appydave::Tools::YouTubeManager::Reports::VideoContentReport.new
      report.print(manager.data)
    else
      log.error "Video not found! Maybe it's private or deleted. ID: #{options[:video_id]}"
    end
  end

  def parse_options(args, command)
    options = { video_id: nil }
    OptionParser.new do |opts|
      opts.banner = "Usage: youtube_video_manager.rb #{command} [options]"

      opts.on('-v', '--video-id ID', 'YouTube Video ID') { |v| options[:video_id] = v }

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.parse!(args)

    unless options[:video_id]
      puts 'Missing required options. Use -h for help.'
      exit
    end

    options
  end

  def print_help
    puts 'Usage: youtube_video_manager.rb [command] [options]'
    puts 'Commands:'
    puts '  get  Get details for a YouTube video'
    # Additional commands can be listed here
    puts "Run 'youtube_video_manager.rb [command] --help' for more information on a command."
  end
end

YouTubeVideoManagerCLI.new.run
