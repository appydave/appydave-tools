# frozen_string_literal: true

module Appydave
  module Tools
    module LlmContext
      # Struct with keyword_init: true to allow named parameters
      Options = Struct.new(
        :include_patterns,
        :exclude_patterns,
        :format,
        :line_limit,
        :debug,
        :output_target,
        :working_directory,
        :prompt,
        :show_tokens,
        :file_paths,
        :stdin,
        :smart,
        :smart_limit,
        keyword_init: true
      ) do
        def initialize(**args)
          super
          self.include_patterns ||= []
          self.exclude_patterns ||= []
          self.format ||= 'tree,content'
          self.debug ||= 'none'
          self.output_target ||= []
          self.prompt ||= nil
          self.show_tokens ||= false
          self.file_paths ||= []
          self.stdin ||= false
          self.smart ||= false
          self.smart_limit ||= 100_000
        end
      end
    end
  end
end
