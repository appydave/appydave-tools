# frozen_string_literal: true

require 'yaml'
require 'open3'
require 'fileutils'

module Appydave
  module Tools
    module RandomContext
      # Loads query library, runs each query to check result count,
      # filters to entries with "good" result counts, and picks one randomly.
      class Randomizer
        BUNDLED_CONFIG_PATH = File.expand_path('../../../../config/random-queries.yml', __dir__)
        USER_CONFIG_PATH = File.expand_path('~/.config/appydave/random-queries.yml')

        def initialize(config_path: USER_CONFIG_PATH, meta: false, executor: nil,
                       bundled_config_path: BUNDLED_CONFIG_PATH,
                       bootstrap: config_path == USER_CONFIG_PATH)
          @config_path = config_path
          @meta = meta
          @executor = executor || method(:shell_execute)
          @bundled_config_path = bundled_config_path
          @bootstrap = bootstrap
        end

        # Returns [QueryEntry, results_array] for the picked entry, or nil if no candidates.
        def pick
          candidates = []

          load_entries.each do |entry|
            results = @executor.call(entry.command)
            candidates << [entry, results] if entry.good_count?(results.size)
          end

          candidates.sample
        end

        # Picks a random candidate and prints label + results to stdout.
        def run
          picked = pick
          unless picked
            puts 'No matching queries found'
            return
          end

          entry, results = picked
          puts "Question: \"#{entry.label}\""

          if @meta
            meta_results = @executor.call("#{entry.command} --meta")
            meta_results.each { |line| puts line }
          else
            results.each { |line| puts line }
          end
        end

        private

        def load_entries
          resolved = resolve_config!
          data = YAML.safe_load(File.read(resolved))
          (data['queries'] || []).map { |q| QueryEntry.new(q) }
        end

        def resolve_config!
          return @config_path if File.exist?(@config_path)
          raise "Config not found: #{@config_path}" unless @bootstrap

          FileUtils.mkdir_p(File.dirname(@config_path))
          FileUtils.cp(@bundled_config_path, @config_path)
          @config_path
        end

        def shell_execute(command)
          stdout, _stderr, _status = Open3.capture2(command)
          stdout.strip.split("\n").reject(&:empty?)
        end
      end
    end
  end
end
