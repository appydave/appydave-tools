# frozen_string_literal: true

module Appydave
  module Tools
    # Build GPT context from various sources
    module GptContext
      # Gathers file names and content based on include and exclude patterns
      class FileCollector
        attr_reader :include_patterns, :exclude_patterns, :format, :working_directory

        def initialize(include_patterns: [], exclude_patterns: [], format: nil, working_directory: nil)
          @include_patterns = include_patterns
          @exclude_patterns = exclude_patterns
          @format = format
          @working_directory = working_directory
        end

        def build
          FileUtils.cd(working_directory) if working_directory && Dir.exist?(working_directory)

          result = case format
                   when 'tree'
                     build_tree
                   when 'both'
                     "#{build_tree}\n\n#{build_content}"
                   else
                     build_content
                   end

          FileUtils.cd(Dir.home) if working_directory

          result
        end

        private

        def build_content
          concatenated_content = []

          include_patterns.each do |pattern|
            Dir.glob(pattern).each do |file_path|
              next if excluded?(file_path) || File.directory?(file_path)

              content = "# file: #{file_path}\n\n#{File.read(file_path)}"
              concatenated_content << content
            end
          end

          concatenated_content.join("\n\n")
        end

        def build_tree
          tree_view = {}

          include_patterns.each do |pattern|
            Dir.glob(pattern).each do |file_path|
              next if excluded?(file_path)

              path_parts = file_path.split('/')
              insert_into_tree(tree_view, path_parts)
            end
          end

          build_tree_pretty(tree_view).rstrip
        end

        def insert_into_tree(tree, path_parts)
          node = tree
          path_parts.each do |part|
            node[part] ||= {}
            node = node[part]
          end
        end

        def build_tree_pretty(node, prefix: '', is_last: true, output: ''.dup)
          node.each_with_index do |(part, child), index|
            connector = is_last && index == node.size - 1 ? '└' : '├'
            output << "#{prefix}#{connector}─ #{part}\n"
            next_prefix = is_last && index == node.size - 1 ? '  ' : '│ '
            build_tree_pretty(child, prefix: "#{prefix}#{next_prefix}", is_last: child.empty? || index == node.size - 1, output: output)
          end
          output
        end

        def excluded?(file_path)
          exclude_patterns.any? { |pattern| File.fnmatch(pattern, file_path, File::FNM_PATHNAME | File::FNM_DOTMATCH) }
        end
      end
    end
  end
end
