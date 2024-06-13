# frozen_string_literal: true

require 'openai'

module Appydave
  module Tools
    module CliActions
      # Action to run a completion prompt against the model
      class PromptCompletionAction < BaseAction
        DEFAULT_MODEL = 'gpt-4o'
        DEFAULT_PLATFORM = 'openai'

        protected

        def define_options(opts, options)
          opts.on('-p', '--prompt PROMPT', 'The prompt text') { |v| options[:prompt] = v }
          opts.on('-f', '--file FILE', 'The prompt file') { |v| options[:file] = v }
          opts.on('-o', '--output FILE', 'Output file') { |v| options[:output] = v }
          opts.on('-c', '--clipboard', 'Copy result to clipboard') { |v| options[:clipboard] = v }
          opts.on('-m', '--model MODEL', "Model to use (default: #{DEFAULT_MODEL})") { |v| options[:model] = v }
          opts.on('-k', '--key-value PAIR', 'Key-value pairs for interpolation (format: key1=value1,key2=value2)') { |v| options[:key_value] = v }
        end

        def validate_options(options)
          unless options[:prompt] || options[:file]
            puts 'Missing required options: --prompt or --file. Use -h for help.'
            exit
          end

          if options[:key_value]
            key_value_pairs = options[:key_value].split(',').to_h { |pair| pair.split('=') }
            options[:key_value] = key_value_pairs
          else
            options[:key_value] = {}
          end
        end

        def execute(options)
          prompt_text = options[:prompt] || File.read(options[:file])
          model = options[:model] || DEFAULT_MODEL
          key_value_pairs = options[:key_value] || {}

          # Interpolate key-value pairs into the prompt
          key_value_pairs.each do |key, value|
            prompt_text.gsub!("{#{key}}", value)
          end

          puts "Prompt: #{prompt_text}"
          puts "Model: #{model}"
          puts "Key-Value Pairs: #{key_value_pairs}"

          # USE Library class to run this type of code
          # client = OpenAI::Client.new(api_key: ENV['OPENAI_API_KEY'])
          # response = client.completions(
          #   engine: model,
          #   parameters: {
          #     prompt: prompt_text,
          #     max_tokens: 100
          #   }
          # )

          # result = response['choices'].first['text'].strip

          # if options[:output]
          #   File.write(options[:output], result)
          #   puts "Output written to #{options[:output]}"
          # end

          # if options[:clipboard]
          #   Clipboard.copy(result)
          #   puts 'Output copied to clipboard'
          # end

          puts 'Result:'
          # puts result unless options[:output]
        end
      end
    end
  end
end
