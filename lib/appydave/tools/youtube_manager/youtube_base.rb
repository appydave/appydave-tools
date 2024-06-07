# frozen_string_literal: true

module Appydave
  module Tools
    module YouTubeManager
      # Base class for YouTube API management
      class YouTubeBase
        def initialize
          @service = Google::Apis::YoutubeV3::YouTubeService.new
          @service.client_options.application_name = 'YouTube Video Manager'
          @service.authorization = Authorization.authorize
        end
      end
    end
  end
end
