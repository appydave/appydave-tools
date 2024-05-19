# frozen_string_literal: true

module Appydave
  module Tools
    # Project, channel, and file name management
    module NameManager
      # Parses and generates project names for Appydave video projects
      class ProjectName
        attr_reader :sequence, :channel_code, :project_name

        def initialize(file_name)
          parse_file_name(file_name)
        end

        def generate_name
          if channel_code
            "#{sequence}-#{channel_code}-#{project_name}"
          else
            "#{sequence}-#{project_name}"
          end.downcase
        end

        def to_s
          generate_name
        end

        private

        def parse_file_name(file_name)
          file_name = File.basename(file_name, File.extname(file_name))
          parts = file_name.split('-')

          @sequence = parts[0]
          @project_name = parts[-1]
          @channel_code = parts.length == 3 ? parts[1] : nil
        end
      end
    end
  end
end
