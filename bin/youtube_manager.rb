#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

# Process command line arguments for YouTubeVideoManager operations
class YouTubeVideoManagerCLI
  include KLog::Logging

  def initialize
    @commands = {
      'get' => method(:fetch_video_details),
      'update' => method(:update_video_details)
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
    get_video = Appydave::Tools::YouTubeManager::GetVideo.new
    get_video.get(options[:video_id])

    if get_video.video?
      # json = JSON.pretty_generate(details)
      # puts json

      report = Appydave::Tools::YouTubeManager::Reports::VideoDetailsReport.new
      report.print(get_video.data)

      # report = Appydave::Tools::YouTubeManager::Reports::VideoContentReport.new
      # report.print(manager.data)
    else
      log.error "Video not found! Maybe it's private or deleted. ID: #{options[:video_id]}"
    end
  end

  def update_video_details(args)
    options = parse_update_options(args)

    get_video = Appydave::Tools::YouTubeManager::GetVideo.new
    get_video.get(options[:video_id])

    update_video = Appydave::Tools::YouTubeManager::UpdateVideo.new(get_video.data)

    update_video.title(options[:title]) if options[:title]
    update_video.description(options[:description]) if options[:description]
    update_video.tags(options[:tags]) if options[:tags]
    update_video.category_id(options[:category_id]) if options[:category_id]

    update_video.save
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

  def parse_update_options(args)
    options = { video_id: nil }
    OptionParser.new do |opts|
      opts.banner = 'Usage: youtube_video_manager.rb update [options]'

      opts.on('-v', '--video-id ID', 'YouTube Video ID') { |v| options[:video_id] = v }
      opts.on('-t', '--title TITLE', 'Video Title') { |t| options[:title] = t }
      opts.on('-d', '--description DESCRIPTION', 'Video Description') { |d| options[:description] = d }
      opts.on('-g', '--tags TAGS', 'Video Tags (comma-separated)') { |g| options[:tags] = g.split(',') }
      opts.on('-c', '--category-id CATEGORY_ID', 'Video Category ID') { |c| options[:category_id] = c }

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
    puts '  get    Get details for a YouTube video'
    puts '  update Update details for a YouTube video'
    puts "Run 'youtube_video_manager.rb [command] --help' for more information on a command."
  end
end

YouTubeVideoManagerCLI.new.run
