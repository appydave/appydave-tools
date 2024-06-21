# frozen_string_literal: true

module Appydave
  module Tools
    module PromptTools
      # PromptCompletion is a class for running a completion prompt against the model
      class PromptCompletion
        include KLog::Logging

        attr_reader :prompt
        attr_reader :prompt_file
        attr_reader :expanded_prompt
        attr_reader :llm
        attr_reader :placeholders
        attr_reader :output_file
        attr_reader :clipboard

        def initialize(options = {})
          setup_options(options)

          validate_options
        end

        def run
          result = run_prompt(expand_prompt)

          log.subheading 'Expanded Prompt'
          puts expanded_prompt
          log.subheading 'Result'
          puts result

          if output_file
            File.write(output_file, result)
            puts "Output written to #{output_file}"
          end

          if clipboard
            Clipboard.copy(result)
            puts 'Output copied to clipboard'
          end

          puts result unless output_file
        end

        private

        def setup_options(options)
          @prompt = options.delete(:prompt)
          @prompt_file = options.delete(:prompt_file)
          @llm = Appydave::Tools::PromptTools::Models::LlmInfo.new(
            platform: options.delete(:llm_platform),
            model: options.delete(:llm_model)
          )
          @placeholders = options.delete(:placeholders) || {}
          @output_file = options.delete(:output_file)
          @clipboard = options.key?(:clipboard) ? options.delete(:clipboard) : false
        end

        def validate_options
          return unless prompt.nil? && prompt_file.nil?

          raise ArgumentError, 'Either prompt or prompt_file must be provided.'
        end

        def expand_prompt
          @expanded_prompt ||= begin
            prompt_content = prompt || File.read(prompt_file)
            placeholders.each do |key, value|
              prompt_content.gsub!("{#{key}}", value)
            end
            prompt_content
          end
        end

        def run_prompt(prompt_content)
          client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_ACCESS_TOKEN', nil))
          response = client.completions(
            engine: llm_model,
            prompt: prompt_content,
            max_tokens: 1000
          )
          response['choices'][0]['text'].strip
        rescue StandardError => e
          puts "Error: Failed to run prompt. #{e.message}"
          exit 1
        end
      end
    end
  end
end
