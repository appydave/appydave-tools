# frozen_string_literal: true

module Appydave
  module Tools
    module CliActions
      class GetVideoAction < BaseAction
        protected

        def define_options(opts, options)
          opts.on('-v', '--video-id ID', 'YouTube Video ID') { |v| options[:video_id] = v }
        end

        def validate_options(options)
          unless options[:video_id]
            puts 'Missing required options: --video-id. Use -h for help.'
            exit
          end
        end

        def execute(options)
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
            puts "Video not found! Maybe it's private or deleted. ID: #{options[:video_id]}"
          end
        end
      end
    end
  end
end
