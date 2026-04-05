# frozen_string_literal: true

require 'json'

module Appydave
  module Tools
    module AppContext
      # Queries locations.json to find app files via context.globs.json patterns.
      #
      # Follows the same find/find_meta pattern as BrainQuery and OmiQuery.
      class AppQuery
        def initialize(options, jump_config: nil)
          @options = options
          @jump_config = jump_config
        end

        # Return absolute file paths matching the query
        def find
          return [] unless @options.query?

          apps = resolve_apps
          return [] if apps.empty?

          apps.flat_map { |app| expand_app(app) }.uniq.sort
        end

        # Return structured metadata about the query results
        def find_meta
          return [] unless @options.query?

          apps = resolve_apps
          return [] if apps.empty?

          apps.map { |app| build_meta(app) }
        end

        # List all available glob names for a specific app
        def list_globs(app_name)
          location = find_location(app_name)
          return [] unless location

          loader = build_loader(location)
          return [] unless loader.available?

          loader.available_names
        end

        # List all apps that have context.globs.json
        def list_apps
          jump_config.locations
                     .select { |loc| File.exist?(File.join(expand_path(loc.path), 'context.globs.json')) }
                     .map do |loc|
                       loader = build_loader(loc)
                       {
                         'key' => loc.key,
                         'path' => expand_path(loc.path),
                         'pattern' => loader.pattern,
                         'glob_count' => loader.globs.size
                       }
                     end
        end

        private

        def jump_config
          @jump_config ||= Jump::Config.new
        end

        # Resolve app names to Location objects
        def resolve_apps
          if @options.pattern_filter
            resolve_by_pattern(@options.pattern_filter)
          else
            @options.app_names.flat_map { |name| resolve_app(name) }.compact.uniq(&:key)
          end
        end

        # 4-tier app resolution
        def resolve_app(name)
          name_down = name.downcase

          # Tier 1: exact key match
          loc = jump_config.find(name_down)
          return [loc] if loc

          # Tier 2: jump alias match
          loc = jump_config.locations.find { |l| l.jump&.downcase == name_down }
          return [loc] if loc

          # Tier 3: substring match on key
          matches = jump_config.locations.select { |l| l.key.downcase.include?(name_down) }
          return matches unless matches.empty?

          # Tier 4: substring match on description
          jump_config.locations.select { |l| l.description&.downcase&.include?(name_down) }
        end

        def resolve_by_pattern(pattern)
          jump_config.locations.select do |loc|
            loader = build_loader(loc)
            loader.available? && loader.pattern&.downcase == pattern.downcase
          end
        end

        def expand_app(location)
          loader = build_loader(location)
          return [] unless loader.available?

          glob_names = @options.glob_names
          return [] if glob_names.empty?

          loader.expand(glob_names)
        end

        def build_meta(location)
          loader = build_loader(location)
          glob_names = @options.glob_names
          file_count = loader.available? && glob_names.any? ? loader.expand(glob_names).size : 0

          resolved_from = glob_names.map { |n| describe_resolution(loader, n) }.join(', ')

          {
            'app' => location.key,
            'path' => expand_path(location.path),
            'pattern' => loader.pattern,
            'matched_globs' => resolve_glob_names(loader, glob_names),
            'resolved_from' => resolved_from,
            'file_count' => file_count
          }
        end

        def build_loader(location)
          GlobsLoader.new(expand_path(location.path))
        end

        def expand_path(path)
          File.expand_path(path)
        end

        def find_location(app_name)
          results = resolve_app(app_name)
          results&.first
        end

        # Describe how a glob name was resolved (for meta output)
        def describe_resolution(loader, name)
          name = name.strip.downcase
          return "#{name} (glob)" if loader.globs.key?(name)
          return "#{name} (alias)" if loader.aliases.key?(name)
          return "#{name} (composite)" if loader.composites.key?(name)

          "#{name} (fuzzy)"
        end

        # Resolve glob names to their constituent direct glob names
        def resolve_glob_names(loader, names)
          return [] unless loader.available?

          names.flat_map do |name|
            name = name.strip.downcase
            if loader.globs.key?(name)
              [name]
            elsif loader.aliases.key?(name)
              loader.aliases[name]
            elsif loader.composites.key?(name)
              members = loader.composites[name]
              members == ['*'] ? loader.globs.keys : members
            else # rubocop:disable Lint/DuplicateBranch
              [name]
            end
          end.uniq
        end
      end
    end
  end
end
