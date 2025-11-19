# frozen_string_literal: true

module Appydave
  module Tools
    module Configuration
      module Models
        # Global settings that can be referenced by other configurations or tools
        class SettingsConfig < ConfigBase
          def set(key, value)
            data[key] = value
          end

          def get(key, default = nil)
            data.fetch(key, default)
          end

          # Well known settings

          def video_projects_root
            get('video-projects-root')
          end

          def ecamm_recording_folder
            get('ecamm-recording-folder')
          end

          def download_folder
            get('download-folder')
          end

          def download_image_folder
            get('download-image-folder') || download_folder
          end

          def current_user
            get('current_user')
          end

          def print
            log.subheading 'Settings Configuration'

            data.each do |key, value|
              log.kv key, value
            end
          end
        end
      end
    end
  end
end
