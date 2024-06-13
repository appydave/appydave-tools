# frozen_string_literal: true

module Appydave
  module Tools
    module YouTubeManager
      # Manage YouTube video details
      class GetVideo < YouTubeBase
        attr_reader :video_id
        attr_reader :data

        def get(video_id)
          @data = nil
          @video_id = video_id
          response = @service.list_videos('snippet,contentDetails,status,statistics', id: video_id)
          video = response.items.first

          return unless video

          build_data(video)
        end

        def video?
          !data.nil?
        end

        private

        def build_data(video)
          category_title = get_category_title(video.snippet.category_id)

          data = {
            id: video.id,
            title: video.snippet.title,
            description: video.snippet.description,
            published_at: video.snippet.published_at,
            channel_id: video.snippet.channel_id,
            channel_title: video.snippet.channel_title,
            category_id: video.snippet.category_id,
            tags: video.snippet.tags,
            thumbnails: video.snippet.thumbnails.to_h,
            default_audio_language: video.snippet.default_audio_language,
            default_language: video.snippet.default_language,
            live_broadcast_content: video.snippet.live_broadcast_content,
            category_title: category_title,
            view_count: video.statistics.view_count,
            like_count: video.statistics.like_count,
            dislike_count: video.statistics.dislike_count,
            comment_count: video.statistics.comment_count,
            privacy_status: video.status.privacy_status,
            embeddable: video.status.embeddable,
            license: video.status.license,
            recording_location: video.recording_details&.location,
            recording_date: video.recording_details&.recording_date,
            duration: video.content_details.duration,
            definition: video.content_details.definition,
            caption: video.content_details.caption,
            licensed_content: video.content_details.licensed_content
          }
          get_captions(video.id) # Fetch captions and associate them
          # HAVE NOT FIGURED OUT THE PERMISSION ISSUE WITH THIS YET
          # captions: get_captions(video.id) # Fetch captions and associate them
          @data = Appydave::Tools::YouTubeManager::Models::YouTubeDetails.new(data)
        end

        def get_category_title(category_id)
          response = @service.list_video_categories('snippet', id: category_id)
          category = response.items.first
          category&.snippet&.title
        end

        def get_captions(video_id)
          captions_response = @service.list_captions('id,snippet', video_id)
          captions_response.items.map do |caption|
            # puts "Caption ID: #{caption.id}"
            # puts "Language: #{caption.snippet.language}"
            # puts "Status: #{caption.snippet.status}"
            # puts "Track Kind: #{caption.snippet.track_kind}"
            # puts "Name: #{caption.snippet.name}"
            # puts "Is Auto-Synced: #{caption.snippet.is_auto_synced}"
            # puts "Is CC: #{caption.snippet.is_cc}"
            # puts "Is Draft: #{caption.snippet.is_draft}"
            # puts "Last Updated: #{caption.snippet.last_updated}"

            next unless caption.snippet.status == 'serving'

            caption_data = {
              caption_id: caption.id,
              language: caption.snippet.language,
              name: caption.snippet.name,
              status: caption.snippet.status,
              content: download_caption(caption)
            }
            caption_data
          end.compact
        end

        def download_caption(caption)
          content = ''
          formats = %w[srv1 vtt srt ttml] # Try multiple formats to find a compatible one
          success = false
          formats.each do |format|
            break if content.present?

            begin
              @service.download_caption(caption.id, tfmt: format) do |result, error|
                if error.nil?
                  content = result
                  success = true
                  # else
                  # log.info "An error occurred while downloading caption #{caption.id} with format #{format}: #{error.message}"
                end
              end
            rescue Google::Apis::ClientError => e
              log.error "An error occurred while downloading caption #{caption.id} with format #{format}: #{e.message}"
            end
          end

          log.error 'Error occurred while downloading captions, make sure you have the correct permissions.' unless success

          content
        end
      end
    end
  end
end
