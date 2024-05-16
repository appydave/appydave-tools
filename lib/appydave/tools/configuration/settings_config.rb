# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      # Global settings that can be referenced by other configurations or tools
      class SettingsConfig < ConfigBase
        def initialize
          super('settings')
        end

        def set(key, value)
          data[key] = value
        end

        def get(key, default = nil)
          data.fetch(key, default)
        end
      end
    end
  end
end
