# frozen_string_literal: true

require 'active_model'

module Appydave
  module Tools
    module YouTubeManager
      module Models
        # Model to store YouTube video details
        class YouTubeDetails
          include ActiveModel::Model
          include ActiveModel::Attributes

          attribute :id, :string
          attribute :title, :string                         # snippet
          attribute :description, :string                   # snippet
          attribute :published_at, :datetime                # snippet
          attribute :channel_id, :string                    # snippet
          attribute :channel_title, :string                 # snippet
          attribute :category_id, :string                   # snippet

          attribute :default_audio_language                 # snippet
          attribute :default_language                       # snippet
          attribute :live_broadcast_content                 # snippet

          attribute :tags, array: true                      # snippet
          attribute :thumbnails, :hash                      # snippet

          attribute :category_title, :string
          attribute :view_count, :integer
          attribute :like_count, :integer
          attribute :dislike_count, :integer
          attribute :comment_count, :integer
          attribute :privacy_status, :string
          attribute :embeddable, :boolean
          attribute :license, :string
          attribute :recording_location, :string
          attribute :recording_date, :datetime
          attribute :duration, :string
          attribute :definition, :string
          attribute :caption, :boolean
          attribute :licensed_content, :boolean
          attribute :captions, :array # , default: []

          def initialize(attributes = {})
            super
            self.captions = attributes[:captions].map { |caption| Captions.new(caption) } if attributes[:captions]
          end

          def map_video_snippet
            {
              title: title,
              description: description,
              category_id: category_id,
              tags: tags || [],
              thumbnails: thumbnails
            }
          end

          def to_h
            {
              id: id,
              title: title,
              description: description,
              published_at: published_at,
              channel_id: channel_id,
              channel_title: channel_title,
              category_id: category_id,
              category_title: category_title,
              default_audio_language: default_audio_language,
              default_language: default_language,
              live_broadcast_content: live_broadcast_content,
              tags: tags,
              thumbnails: thumbnails,
              view_count: view_count,
              like_count: like_count,
              dislike_count: dislike_count,
              comment_count: comment_count,
              privacy_status: privacy_status,
              embeddable: embeddable,
              license: license,
              recording_location: recording_location,
              recording_date: recording_date,
              duration: duration,
              definition: definition,
              caption: caption,
              licensed_content: licensed_content
            }
            # captions: captions.map(&:to_h)
          end
        end
      end
    end
  end
end
