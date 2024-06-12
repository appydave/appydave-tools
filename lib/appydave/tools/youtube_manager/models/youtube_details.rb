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
          attribute :title, :string
          attribute :description, :string
          attribute :published_at, :datetime
          attribute :channel_id, :string
          attribute :channel_title, :string
          attribute :view_count, :integer
          attribute :like_count, :integer
          attribute :dislike_count, :integer
          attribute :comment_count, :integer
          attribute :privacy_status, :string
          attribute :embeddable, :boolean
          attribute :license, :string
          attribute :recording_location, :string
          attribute :recording_date, :datetime
          attribute :tags, array: true
          attribute :thumbnails, :hash
          attribute :duration, :string
          attribute :definition, :string
          attribute :caption, :boolean
          attribute :licensed_content, :boolean
          # attribute :captions, :array, default: []

          # def initialize(attributes = {})
          #   super
          #   self.captions = attributes[:captions].map { |caption| Captions.new(caption) } if attributes[:captions]
          # end
        end
      end
    end
  end
end
