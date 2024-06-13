#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

# Process command line arguments for Prompt operations
class PromptToolsCLI
  def initialize
    @commands = {
      'completion' => Appydave::Tools::CliActions::PromptCompletionAction.new
    }
  end

  def run
    command, *args = ARGV
    if @commands.key?(command)
      @commands[command].action(args)
    else
      puts "Unknown command: #{command}"
      print_help
    end
  end

  private

  def print_help
    puts 'Usage: prompt_tools.rb [command] [options]'
    puts 'Commands:'
    puts '  completion    Run a completion prompt against the model'
    puts "Run 'prompt.rb [command] --help' for more information on a command."
  end
end

PromptToolsCLI.new.run
