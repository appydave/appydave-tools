# frozen_string_literal: true

module Appydave
  module Tools
    module CliActions
      # Action to update a YouTube video metadata (title, description, tags, category)
      class UpdateVideoAction < BaseAction
        protected

        def define_options(opts, options)
          opts.on('-v', '--video-id ID', 'YouTube Video ID') { |v| options[:video_id] = v }
          opts.on('-t', '--title TITLE', 'Video Title') { |t| options[:title] = t }
          opts.on('-d', '--description DESCRIPTION', 'Video Description') { |d| options[:description] = d }
          opts.on('-g', '--tags TAGS', 'Video Tags (comma-separated)') { |g| options[:tags] = g.split(',') }
          opts.on('-c', '--category-id CATEGORY_ID', 'Video Category ID') { |c| options[:category_id] = c }
        end

        def validate_options(options)
          return if options[:video_id]

          puts 'Missing required options: --video-id. Use -h for help.'
          exit
        end

        def execute(options)
          get_video = Appydave::Tools::YouTubeManager::GetVideo.new
          get_video.get(options[:video_id])

          if get_video.video?
            update_video = Appydave::Tools::YouTubeManager::UpdateVideo.new(get_video.data)

            update_video.title(options[:title]) if options[:title]
            update_video.description(options[:description]) if options[:description]
            update_video.tags(options[:tags]) if options[:tags]
            update_video.category_id(options[:category_id]) if options[:category_id]

            update_video.save
            puts "Video updated successfully. ID: #{options[:video_id]}"
          else
            puts "Video not found! Maybe it's private or deleted. ID: #{options[:video_id]}"
          end
        end
      end
    end
  end
end
