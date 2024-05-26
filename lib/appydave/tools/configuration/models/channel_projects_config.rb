# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      module Models
        # Channel projects configuration
        class ChannelProjectsConfig < ConfigBase
          # Retrieve channel information by channel name (string or symbol)
          def get_channel_info(channel_name)
            channel_name = channel_name.to_s
            ChannelInfo.new(data['channel_projects'][channel_name] || default_channel_info)
          end

          # Set channel information
          def set_channel_info(channel_name, channel_info)
            data['channel_projects'] ||= {}
            data['channel_projects'][channel_name.to_s] = channel_info.to_h
          end

          # Retrieve a list of all channel projects
          def channel_projects
            data['channel_projects'].map do |_name, info|
              ChannelInfo.new(info)
            end
          end

          private

          def default_data
            { 'channel_projects' => {} }
          end

          def default_channel_info
            {
              'content_projects' => '',
              'video_projects' => '',
              'published_projects' => '',
              'abandoned_projects' => ''
            }
          end

          # Type-safe class to access channel info properties
          class ChannelInfo
            attr_accessor :content_projects, :video_projects, :published_projects, :abandoned_projects

            def initialize(data)
              @content_projects = data['content_projects']
              @video_projects = data['video_projects']
              @published_projects = data['published_projects']
              @abandoned_projects = data['abandoned_projects']
            end

            def to_h
              {
                'content_projects' => @content_projects,
                'video_projects' => @video_projects,
                'published_projects' => @published_projects,
                'abandoned_projects' => @abandoned_projects
              }
            end
          end
        end
      end
    end
  end
end
