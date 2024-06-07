# frozen_string_literal: true

module Appydave
  module Tools
    module YouTubeManager
      module Reports
        # Report on video content
        class VideoContentReport
          include KLog::Logging

          def print(data)
            # log.heading 'Video Details Report'
            log.subheading data[:title]
            log.kv 'Published At', data[:published_at]
            log.kv 'View Count', data[:view_count]
            log.kv 'Like Count', data[:like_count]
            log.kv 'Dislike Count', data[:dislike_count]
            log.kv 'Tags', data[:tags].join(', ')
            log.line
            puts data[:description]
            log.line
          end
        end
      end
    end
  end
end
