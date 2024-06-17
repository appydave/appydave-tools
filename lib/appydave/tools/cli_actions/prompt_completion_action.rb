# frozen_string_literal: true

module Appydave
  module Tools
    module CliActions
      # PromptCompletionAction is a CLI action for running a completion prompt against the model
      class PromptCompletionAction < BaseAction
        protected

        def define_options(opts, options)
          opts.on('-p', '--prompt PROMPT', 'The prompt text') { |v| options[:prompt] = v }
          opts.on('-f', '--file FILE', 'The prompt file') { |v| options[:file] = v }
          opts.on('-o', '--output FILE', 'Output file') { |v| options[:output] = v }
          opts.on('-c', '--clipboard', 'Copy result to clipboard') { |_v| options[:clipboard] = true }
          opts.on('-m', '--model MODEL', 'Model to use') { |v| options[:model] = v }
          opts.on('-k', '--placeholders PAIRS', 'Placeholders for interpolation (format: key1=value1,key2=value2)') { |v| options[:placeholders] = v }
        end

        def validate_options(options)
          unless options[:prompt] || options[:file]
            puts 'Missing required options: --prompt or --file. Use -h for help.'
            exit
          end

          if options[:placeholders]
            placeholders = options[:placeholders].split(',').to_h { |pair| pair.split('=') }
            options[:placeholders] = placeholders
          else
            options[:placeholders] = {}
          end
        end

        def execute(options)
          prompt_options = {
            prompt: options[:prompt],
            prompt_file: options[:file],
            platform: options[:platform],
            model: options[:model],
            placeholders: options[:placeholders],
            output_file: options[:output],
            clipboard: options[:clipboard]
          }

          completion = Appydave::Tools::PromptTools::PromptCompletion.new(prompt_options)
          completion.run
        end
      end
    end
  end
end
