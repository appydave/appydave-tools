# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      module Models
        # Channels configuration
        class ChannelsConfig < ConfigBase
          # Retrieve channel information by channel code (string or symbol)
          def get_channel(channel_key)
            channel_key = channel_key.to_s
            info = data['channels'][channel_key] || default_channel_info
            ChannelInfo.new(channel_key, info)
          end

          # Set channel information
          def set_channel(channel_key, channel_info)
            data['channels'] ||= {}
            data['channels'][channel_key.to_s] = channel_info.to_h
          end

          # Retrieve a list of all channels
          def channels
            data['channels'].map do |key, info|
              ChannelInfo.new(key, info)
            end
          end

          def key?(key)
            key = key.to_s
            data['channels'].key?(key)
          end

          def code?(code)
            code = code.to_s
            data['channels'].values.any? { |info| info['code'] == code }
          end

          def print
            log.heading 'Channel Configuration'

            tp channels, :key, :code, :name, :youtube_handle
          end

          private

          def default_data
            { 'channels' => {} }
          end

          def default_channel_info
            {
              'code' => '',
              'name' => '',
              'youtube_handle' => '',
              'locations' => {
                'content_projects' => '',
                'video_projects' => '',
                'published_projects' => '',
                'abandoned_projects' => ''
              }
            }
          end

          # Type-safe class to access channel properties
          class ChannelInfo
            attr_accessor :key, :code, :name, :youtube_handle, :locations

            def initialize(key, data)
              @key = key
              @code = data['code']
              @name = data['name']
              @youtube_handle = data['youtube_handle']
              @locations = ChannelLocation.new(data['locations'] || {})
            end

            def to_h
              {
                'code' => @code,
                'name' => @name,
                'youtube_handle' => @youtube_handle,
                'locations' => locations.to_h
              }
            end
          end

          # Type-safe class to access channel location properties
          class ChannelLocation
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
