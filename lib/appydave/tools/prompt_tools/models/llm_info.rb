# frozen_string_literal: true

module Appydave
  module Tools
    module PromptTools
      module Models
        # What LLM are we using?
        class LlmInfo < Appydave::Tools::Types::BaseModel
          attribute :platform, :string, default: 'openai'
          attribute :model, :string, default: 'gpt-4o'
        end
      end
    end
  end
end
