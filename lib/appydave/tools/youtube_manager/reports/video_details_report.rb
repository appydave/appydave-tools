# frozen_string_literal: true

module Appydave
  module Tools
    module YouTubeManager
      module Reports
        # Print video details
        class VideoDetailsReport
          include KLog::Logging

          def print(data)
            # log.heading 'Video Details Report'
            # log.subheading 'Video Details Report'
            log.section_heading 'Video Details Report'
            log.kv 'ID', data.id
            log.kv 'Title', data.title
            log.kv 'Description', data.description[0..100]
            log.kv 'Published At', data.published_at
            log.kv 'View Count', data.view_count
            log.kv 'Like Count', data.like_count
            log.kv 'Dislike Count', data.dislike_count
            log.kv 'Comment Count', data.comment_count
            log.kv 'Privacy Status', data.privacy_status
            log.kv 'Channel ID', data.channel_id
            log.kv 'Channel Title', data.channel_title
            log.kv 'Category ID', data.category_id
            log.kv 'Category Title', data.category_title
            log.kv 'Default Audio Language', data.default_audio_language
            log.kv 'Default Language', data.default_language
            log.kv 'Live Broadcast Content', data.live_broadcast_content
            log.kv 'Embeddable', data.embeddable
            log.kv 'License', data.license
            log.kv 'Recording Location', data.recording_location
            log.kv 'Recording Date', data.recording_date
            log.kv 'Tags', data.tags&.join(', ')
          end
        end
      end
    end
  end
end
