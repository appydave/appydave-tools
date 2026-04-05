# frozen_string_literal: true

require 'json'

module Appydave
  module Tools
    module AppContext
      # Loads and resolves named glob patterns from a context.globs.json file.
      #
      # Resolution is 3-tier:
      #   1. Direct glob name  — "services" → globs["services"]
      #   2. Alias match       — "backend"  → aliases["backend"] → ["services", "routes"]
      #   3. Composite match   — "understand" → composites["understand"] → ["context", "docs", ...]
      class GlobsLoader
        attr_reader :project_path, :data

        def initialize(project_path)
          @project_path = project_path
          @data = load_globs_file
        end

        def available?
          !data.nil?
        end

        def globs
          data&.fetch('globs', {}) || {}
        end

        def aliases
          data&.fetch('aliases', {}) || {}
        end

        def composites
          data&.fetch('composites', {}) || {}
        end

        def pattern
          data&.fetch('pattern', nil)
        end

        def project_name
          data&.fetch('project', nil)
        end

        # List all available glob names (direct + aliases + composites)
        def available_names
          names = globs.keys.map { |k| { name: k, type: 'glob' } }
          names += aliases.keys.map { |k| { name: k, type: 'alias' } }
          names += composites.keys.map { |k| { name: k, type: 'composite' } }
          names
        end

        # Resolve a single name through the 3-tier hierarchy.
        # Returns an array of raw glob patterns (strings).
        def resolve(name)
          name = name.strip.downcase

          # Tier 1: direct glob name
          return globs[name] if globs.key?(name)

          # Tier 2: alias → list of glob names
          return aliases[name].flat_map { |glob_name| globs[glob_name] || [] } if aliases.key?(name)

          # Tier 3: composite → list of glob names (or "*" for all)
          if composites.key?(name)
            members = composites[name]
            return globs.values.flatten if members == ['*']

            return members.flat_map { |glob_name| resolve_single_glob(glob_name) }
          end

          # Tier 4: substring fallback
          match = find_substring_match(name)
          return resolve(match) if match

          []
        end

        # Resolve multiple names, expand globs against the filesystem, return absolute paths.
        def expand(names)
          patterns = names.flat_map { |name| resolve(name) }.uniq

          patterns.flat_map { |pat| Dir.glob(File.join(project_path, pat)) }
                  .select { |f| File.file?(f) }
                  .uniq
                  .sort
        end

        private

        def globs_file_path
          File.join(project_path, 'context.globs.json')
        end

        def load_globs_file
          path = globs_file_path
          return nil unless File.exist?(path)

          JSON.parse(File.read(path))
        rescue JSON::ParserError
          nil
        end

        def resolve_single_glob(glob_name)
          globs[glob_name] || []
        end

        def find_substring_match(name)
          all_names = globs.keys + aliases.keys + composites.keys
          all_names.find { |n| n.include?(name) }
        end
      end
    end
  end
end
