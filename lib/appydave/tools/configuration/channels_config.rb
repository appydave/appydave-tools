# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      # Channels configuration
      class ChannelsConfig < ConfigBase
        def initialize
          super('channels')
        end

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

        private

        def default_data
          { 'channels' => {} }
        end

        def default_channel_info
          {
            'code' => '',
            'name' => '',
            'youtube_handle' => ''
          }
        end

        # Type-safe class to access channel properties
        class ChannelInfo
          attr_accessor :key, :code, :name, :youtube_handle

          def initialize(key, data)
            @key = key
            @code = data['code']
            @name = data['name']
            @youtube_handle = data['youtube_handle']
          end

          def to_h
            {
              'code' => @code,
              'name' => @name,
              'youtube_handle' => @youtube_handle
            }
          end
        end
      end
    end
  end
end
