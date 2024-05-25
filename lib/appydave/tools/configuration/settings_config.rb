# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      # Global settings that can be referenced by other configurations or tools
      class SettingsConfig < ConfigBase
        def set(key, value)
          data[key] = value
        end

        def get(key, default = nil)
          data.fetch(key, default)
        end

        # Well known settings

        def ecamm_recording_folder
          get('ecamm-recording-folder')
        end

        def download_folder
          get('download-folder')
        end

        def download_image_folder
          get('download-image-folder') || download_folder
        end
      end
    end
  end
end
