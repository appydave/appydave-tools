# frozen_string_literal: true

module Appydave
  module Tools
    module YouTubeManager
      # Update YouTube video details
      class UpdateVideo < YouTubeBase
        attr_reader :video_details
        attr_reader :snippet

        def initialize(video_details)
          super()
          @video_details = video_details
        end

        def title(title)
          video_details.title = title

          self
        end

        def description(description)
          video_details.description = description

          self
        end

        def tags(tags)
          video_details.tags = tags

          self
        end

        def category_id(category_id)
          video_details.category_id = category_id

          self
        end

        def save
          snippet = video_details.map_video_snippet

          video = Google::Apis::YoutubeV3::Video.new(
            id: video_details.id,
            snippet: snippet
          )

          @service.update_video('snippet', video)
        end
      end
    end
  end
end
