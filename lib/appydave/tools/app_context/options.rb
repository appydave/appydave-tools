# frozen_string_literal: true

module Appydave
  module Tools
    module AppContext
      # Options struct for app context query tool
      class Options
        attr_accessor :app_names, :glob_names, :pattern_filter,
                      :meta, :list, :list_apps,
                      :debug_level

        def initialize
          @app_names = []
          @glob_names = []
          @pattern_filter = nil
          @meta = false
          @list = false
          @list_apps = false
          @debug_level = 'none'
        end

        def query?
          app_names.any? || !pattern_filter.nil?
        end
      end
    end
  end
end
