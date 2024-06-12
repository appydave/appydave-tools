# frozen_string_literal: true

module Appydave
  module Tools
    module YoutubeAutomation
      # GPT Agent interacts with OpenAI's GPT API to generate responses based on prompts for YouTube automation.
      class GptAgent
        include Appydave::Tools::Configuration::Configurable

        def initialize(sequence, debug: false)
          @sequence = sequence
          @debug = debug
          @prompts_path = '/Users/davidcruwys/Library/CloudStorage/Dropbox/team-tldr/_common/raw_prompts'
        end

        def run
          step = config.youtube_automation.get_sequence(@sequence)
          unless step
            puts "Error: Step #{@sequence} not found in the configuration."
            exit 1
          end

          prompt_content = read_prompt(step)

          puts "Running sequence: #{@sequence}"
          puts "Prompt file: #{prompt_file}"
          puts "Prompt content:\n#{prompt_content}" if @debug

          response = run_prompt(prompt_content)

          puts "Response:\n#{response}"
          save_response(prompt_file, response)
        end

        private

        def read_prompt(_step)
          File.read(filename)
        rescue Errno::ENOENT
          puts "Error: Prompt file #{filename} not found."
          exit 1
        end

        def run_prompt(prompt_content)
          client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_ACCESS_TOKEN', nil))
          response = client.completions(
            engine: 'davinci-codex',
            prompt: prompt_content,
            max_tokens: 1000
          )
          response['choices'][0]['text'].strip
        rescue StandardError => e
          puts "Error: Failed to run prompt. #{e.message}"
          exit 1
        end

        def save_response(filename, response)
          output_filename = filename.gsub('.md', '-output.md')
          File.write(output_filename, response)
          puts "Response saved to #{output_filename}"
        end
      end
    end
  end
end
