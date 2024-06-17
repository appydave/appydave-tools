# frozen_string_literal: true

module Appydave
  module Tools
    # Debuggable is a module for adding debug logging to classes
    module Debuggable
      attr_accessor :debug

      def log_info(message)
        log.info(message) if debug
      end

      def log_kv(key, value)
        log.kv(key, value) if debug
      end

      def log_subheading(message)
        log.subheading(message) if debug
      end
    end
  end
end
