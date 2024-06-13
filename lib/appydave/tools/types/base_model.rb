# frozen_string_literal: true

module Appydave
  module Tools
    module Types
      # Used by the ActiveModel attributes API to cast values to hashes
      class BaseModel
        include ActiveModel::Model
        include ActiveModel::Attributes
      end
    end
  end
end
