# frozen_string_literal: true

module Appydave
  module Tools
    module CliActions
      class BaseAction
        def action(args)
          options = parse_options(args)
          execute(options)
        end

        protected

        def parse_options(args)
          options = {}
          OptionParser.new do |opts|
            opts.banner = "Usage: #{command_usage}"

            define_options(opts, options)

            opts.on_tail('-h', '--help', 'Show this message') do
              puts opts
              exit
            end
          end.parse!(args)

          validate_options(options)
          options
        end

        def command_usage
          "#{self.class.name.split('::').last.downcase} [options]"
        end

        def define_options(opts, options)
          # To be implemented by subclasses
        end

        def validate_options(options)
          # To be implemented by subclasses
        end

        def execute(options)
          # To be implemented by subclasses
        end
      end
    end
  end
end