# frozen_string_literal: true

require 'active_model'

module Appydave
  module Tools
    module YouTubeManager
      module Models
        # Model to store YouTube video captions (subtitles)
        class Captions
          include ActiveModel::Model
          include ActiveModel::Attributes

          attribute :caption_id, :string
          attribute :language, :string
          attribute :name, :string
          attribute :status, :string
          attribute :content, :string
        end
      end
    end
  end
end
