# frozen_string_literal: true

module Appydave
  module Tools
    module YouTubeManager
      # Manage YouTube video details
      class GetVideo < YouTubeBase
        attr_reader :video_id
        attr_reader :data
        attr_reader :video

        def get(video_id)
          @video_id = video_id
          response = @service.list_videos('snippet,contentDetails,status,statistics', id: video_id)
          @video = response.items.first

          data = {
            id: video.id,
            title: video.snippet.title,
            description: video.snippet.description,
            published_at: video.snippet.published_at,
            channel_id: video.snippet.channel_id,
            channel_title: video.snippet.channel_title,
            view_count: video.statistics.view_count,
            like_count: video.statistics.like_count,
            dislike_count: video.statistics.dislike_count,
            comment_count: video.statistics.comment_count,
            privacy_status: video.status.privacy_status,
            embeddable: video.status.embeddable,
            license: video.status.license,
            recording_location: video.recording_details&.location,
            recording_date: video.recording_details&.recording_date,
            tags: video.snippet.tags,
            thumbnails: video.snippet.thumbnails.to_h,
            duration: video.content_details.duration,
            definition: video.content_details.definition,
            caption: video.content_details.caption,
            licensed_content: video.content_details.licensed_content
          }

          @data = Appydave::Tools::IndifferentAccessHash.new(data)
        end
      end
    end
  end
end
