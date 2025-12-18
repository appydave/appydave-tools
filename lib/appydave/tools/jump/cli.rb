# frozen_string_literal: true

module Appydave
  module Tools
    module Jump
      # CLI provides the command-line interface for the Jump tool
      #
      # Uses the Method Dispatch (Full) pattern for 10+ commands with
      # hierarchical help system.
      #
      # @example Usage
      #   cli = CLI.new
      #   cli.run(['search', 'appydave', 'ruby'])
      #   cli.run(['add', '--key', 'my-project', '--path', '~/dev/project'])
      class CLI
        EXIT_SUCCESS = 0
        EXIT_NOT_FOUND = 1
        EXIT_INVALID_INPUT = 2
        EXIT_CONFIG_ERROR = 3
        EXIT_PATH_NOT_FOUND = 4

        attr_reader :config, :path_validator, :output

        def initialize(config: nil, path_validator: nil, output: $stdout)
          @path_validator = path_validator || PathValidator.new
          @output = output
          @config = config
        end

        # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
        def run(args = ARGV)
          command = args.shift

          case command
          when nil, '', '--help', '-h'
            show_main_help
            EXIT_SUCCESS
          when '--version', '-v'
            show_version
            EXIT_SUCCESS
          when 'help'
            show_help(args)
            EXIT_SUCCESS
          when 'search'
            run_search(args)
          when 'get'
            run_get(args)
          when 'list'
            run_list(args)
          when 'add'
            run_add(args)
          when 'update'
            run_update(args)
          when 'remove'
            run_remove(args)
          when 'validate'
            run_validate(args)
          when 'report'
            run_report(args)
          when 'generate'
            run_generate(args)
          when 'info'
            run_info(args)
          else
            output.puts "Unknown command: #{command}"
            output.puts "Run 'jump help' for available commands."
            EXIT_INVALID_INPUT
          end
        rescue StandardError => e
          output.puts "Error: #{e.message}"
          output.puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
          EXIT_CONFIG_ERROR
        end
        # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize

        private

        def load_config
          @config ||= Config.new
        end

        def format_option(args)
          format_index = args.index('--format') || args.index('-f')
          return 'table' unless format_index

          format = args[format_index + 1]
          args.delete_at(format_index + 1)
          args.delete_at(format_index)
          format || 'table'
        end

        def format_output(result, format)
          formatter = case format
                      when 'json'
                        Formatters::JsonFormatter.new(result)
                      when 'paths'
                        Formatters::PathsFormatter.new(result)
                      else
                        Formatters::TableFormatter.new(result)
                      end

          output.puts formatter.format
        end

        def exit_code_for(result)
          return EXIT_SUCCESS if result[:success]

          case result[:code]
          when 'NOT_FOUND'
            EXIT_NOT_FOUND
          when 'INVALID_INPUT', 'DUPLICATE_KEY', 'CONFIRMATION_REQUIRED'
            EXIT_INVALID_INPUT
          when 'PATH_NOT_FOUND'
            EXIT_PATH_NOT_FOUND
          else
            EXIT_CONFIG_ERROR
          end
        end

        # Command implementations

        def run_search(args)
          format = format_option(args)
          query = args.join(' ')

          search = Search.new(load_config)
          result = search.search(query)

          format_output(result, format)
          exit_code_for(result)
        end

        def run_get(args)
          format = format_option(args)
          key = args.first

          unless key
            output.puts 'Usage: jump get <key>'
            return EXIT_INVALID_INPUT
          end

          search = Search.new(load_config)
          result = search.get(key)

          format_output(result, format)
          exit_code_for(result)
        end

        def run_list(args)
          format = format_option(args)

          search = Search.new(load_config)
          result = search.list

          format_output(result, format)
          exit_code_for(result)
        end

        def run_add(args)
          format = format_option(args)
          no_generate = args.delete('--no-generate')
          attrs = parse_location_args(args)

          if attrs[:key].nil?
            output.puts 'Usage: jump add --key <key> --path <path> [options]'
            return EXIT_INVALID_INPUT
          end

          cmd = Commands::Add.new(load_config, attrs, path_validator: path_validator)
          result = cmd.run

          format_output(result, format)

          # Auto-regenerate aliases after successful add
          if result[:success] && !no_generate
            regenerate_result = auto_regenerate_aliases
            output_regenerate_result(regenerate_result) if regenerate_result
          end

          exit_code_for(result)
        end

        def run_update(args)
          format = format_option(args)
          no_generate = args.delete('--no-generate')
          key = args.shift
          attrs = parse_location_args(args)

          unless key
            output.puts 'Usage: jump update <key> [options]'
            return EXIT_INVALID_INPUT
          end

          cmd = Commands::Update.new(load_config, key, attrs, path_validator: path_validator)
          result = cmd.run

          format_output(result, format)

          # Auto-regenerate aliases after successful update
          if result[:success] && !no_generate
            regenerate_result = auto_regenerate_aliases
            output_regenerate_result(regenerate_result) if regenerate_result
          end

          exit_code_for(result)
        end

        def run_remove(args)
          format = format_option(args)
          no_generate = args.delete('--no-generate')
          force = args.delete('--force')
          key = args.first

          unless key
            output.puts 'Usage: jump remove <key> [--force]'
            return EXIT_INVALID_INPUT
          end

          cmd = Commands::Remove.new(load_config, key, force: !force.nil?, path_validator: path_validator)
          result = cmd.run

          format_output(result, format)

          # Auto-regenerate aliases after successful remove
          if result[:success] && !no_generate
            regenerate_result = auto_regenerate_aliases
            output_regenerate_result(regenerate_result) if regenerate_result
          end

          exit_code_for(result)
        end

        def run_validate(args)
          format = format_option(args)
          key = args.first

          cmd = Commands::Validate.new(load_config, key: key, path_validator: path_validator)
          result = cmd.run

          format_output(result, format)
          exit_code_for(result)
        end

        def run_report(args)
          format = format_option(args)
          report_type = args.shift
          filter = args.first

          unless report_type
            output.puts 'Usage: jump report <type> [filter]'
            output.puts 'Types: categories, brands, clients, types, tags, by-brand, by-client, by-type, by-tag, summary'
            return EXIT_INVALID_INPUT
          end

          cmd = Commands::Report.new(load_config, report_type, filter: filter, path_validator: path_validator)
          result = cmd.run

          format_output(result, format)
          exit_code_for(result)
        end

        def run_generate(args)
          format = format_option(args)
          target = args.shift

          # Parse output options
          output_path = extract_option(args, '--output')
          output_dir = extract_option(args, '--output-dir')

          unless target
            output.puts 'Usage: jump generate <target> [--output <file>] [--output-dir <dir>]'
            output.puts 'Targets: aliases, help, ah-help, all'
            return EXIT_INVALID_INPUT
          end

          cmd = Commands::Generate.new(
            load_config,
            target,
            output_path: output_path,
            output_dir: output_dir,
            path_validator: path_validator
          )
          result = cmd.run

          # For generate, if content is present (stdout mode), show it directly
          if result[:content] && !output_path && !output_dir
            output.puts result[:content]
          else
            format_output(result, format)
          end

          exit_code_for(result)
        end

        def run_info(args)
          format = format_option(args)
          result = {
            success: true,
            **load_config.info
          }

          format_output(result, format)
          EXIT_SUCCESS
        end

        # Argument parsing helpers

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
        def parse_location_args(args)
          attrs = {}

          i = 0
          while i < args.length
            case args[i]
            when '--key', '-k'
              attrs[:key] = args[i + 1]
              i += 2
            when '--path', '-p'
              attrs[:path] = args[i + 1]
              i += 2
            when '--jump', '-j'
              attrs[:jump] = args[i + 1]
              i += 2
            when '--brand', '-b'
              attrs[:brand] = args[i + 1]
              i += 2
            when '--client', '-c'
              attrs[:client] = args[i + 1]
              i += 2
            when '--type', '-t'
              attrs[:type] = args[i + 1]
              i += 2
            when '--tags'
              attrs[:tags] = args[i + 1]&.split(',')&.map(&:strip)
              i += 2
            when '--description', '-d'
              attrs[:description] = args[i + 1]
              i += 2
            else
              i += 1
            end
          end

          attrs
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity

        def extract_option(args, flag)
          index = args.index(flag)
          return nil unless index

          value = args[index + 1]
          args.delete_at(index + 1)
          args.delete_at(index)
          value
        end

        # Auto-regenerate helpers

        def auto_regenerate_aliases
          output_path = aliases_output_path
          return nil unless output_path

          cmd = Commands::Generate.new(
            load_config,
            'aliases',
            output_path: output_path,
            path_validator: path_validator
          )
          cmd.run
        end

        def aliases_output_path
          Configuration::Config.configure
          Configuration::Config.settings.aliases_output_path
        rescue StandardError
          nil
        end

        def output_regenerate_result(result)
          return unless result[:success]

          output.puts ''
          output.puts "Backed up: #{result[:backup]}" if result[:backup]
          output.puts "Regenerated: #{result[:path]} (#{result[:lines]} lines)"
        end

        # Help display methods

        def show_version
          output.puts "Jump Location Tool v#{Appydave::Tools::VERSION}"
          output.puts 'Part of appydave-tools gem'
        end

        # rubocop:disable Metrics/MethodLength
        def show_main_help
          output.puts <<~HELP
            Jump - Development Folder Location Manager

            Usage: jump <command> [options]

            Search & Retrieval:
              search <terms>        Fuzzy search across all location metadata
              get <key>             Get location by exact key
              list                  List all locations

            CRUD Operations:
              add                   Add a new location
              update <key>          Update an existing location
              remove <key>          Remove a location (requires --force)

            Validation:
              validate [key]        Check if paths exist

            Reports:
              report <type>         Generate reports (brands, clients, types, tags, etc.)

            Generation:
              generate <target>     Generate shell aliases or help content

            Info:
              info                  Show configuration info

            Options:
              --format <fmt>        Output format: table (default), json, paths
              --help, -h            Show this help
              --version, -v         Show version

            Examples:
              jump search appydave ruby
              jump get ad-tools
              jump add --key my-proj --path ~/dev/my-proj --brand appydave
              jump report brands
              jump generate aliases --output ~/.oh-my-zsh/custom/aliases-jump.zsh

            Run 'jump help <command>' for detailed command help.
          HELP
        end
        # rubocop:enable Metrics/MethodLength

        # rubocop:disable Metrics/CyclomaticComplexity
        def show_help(args)
          topic = args.first

          case topic
          when 'search'
            show_search_help
          when 'add'
            show_add_help
          when 'update'
            show_update_help
          when 'remove'
            show_remove_help
          when 'validate'
            show_validate_help
          when 'report'
            show_report_help
          when 'generate'
            show_generate_help
          else
            show_main_help
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def show_search_help
          output.puts <<~HELP
            jump search - Fuzzy search locations

            Usage: jump search <terms> [--format json|table|paths]

            Searches across all location metadata:
              - Key, path, brand, client, type, tags, description

            Scoring:
              - Exact key match: 100 points
              - Key contains term: 50 points
              - Brand/client alias: 40 points
              - Tag match: 30 points
              - Type match: 20 points
              - Description contains: 10 points
              - Path contains: 5 points

            Examples:
              jump search appydave
              jump search ruby cli
              jump search ss app --format json
          HELP
        end

        def show_add_help
          output.puts <<~HELP
            jump add - Add a new location

            Usage: jump add --key <key> --path <path> [options]

            Required:
              --key, -k <key>       Unique identifier (lowercase, alphanumeric, hyphens)
              --path, -p <path>     Directory path (must start with ~ or /)

            Optional:
              --jump, -j <alias>    Shell alias (default: j + key)
              --brand, -b <brand>   Associated brand
              --client, -c <client> Associated client
              --type, -t <type>     Location type (tool, gem, brand, etc.)
              --tags <t1,t2>        Comma-separated tags
              --description, -d     Human description
              --no-generate         Skip auto-regenerating aliases file

            Auto-Regeneration:
              After a successful add, the aliases file is automatically regenerated
              if 'aliases-output-path' is set in settings.json.

            Examples:
              jump add --key my-project --path ~/dev/my-project
              jump add -k ad-tools -p ~/dev/ad/appydave-tools --brand appydave --type tool
              jump add --key temp-proj --path ~/tmp/proj --no-generate
          HELP
        end

        def show_update_help
          output.puts <<~HELP
            jump update - Update an existing location

            Usage: jump update <key> [options]

            Options:
              --path, -p <path>     New directory path
              --jump, -j <alias>    New shell alias
              --brand, -b <brand>   New brand
              --client, -c <client> New client
              --type, -t <type>     New type
              --tags <t1,t2>        New tags (replaces existing)
              --description, -d     New description
              --no-generate         Skip auto-regenerating aliases file

            Auto-Regeneration:
              After a successful update, the aliases file is automatically regenerated
              if 'aliases-output-path' is set in settings.json.

            Examples:
              jump update my-project --description "Updated description"
              jump update ad-tools --tags ruby,cli,youtube
              jump update my-project --path ~/new/path --no-generate
          HELP
        end

        def show_remove_help
          output.puts <<~HELP
            jump remove - Remove a location

            Usage: jump remove <key> --force [--no-generate]

            Options:
              --force               Required to confirm deletion
              --no-generate         Skip auto-regenerating aliases file

            Auto-Regeneration:
              After a successful remove, the aliases file is automatically regenerated
              if 'aliases-output-path' is set in settings.json.

            Examples:
              jump remove old-project --force
              jump remove temp-project --force --no-generate
          HELP
        end

        def show_validate_help
          output.puts <<~HELP
            jump validate - Check if paths exist

            Usage: jump validate [key]

            Without key: validates all locations
            With key: validates specific location

            Examples:
              jump validate
              jump validate ad-tools
              jump validate --format json
          HELP
        end

        def show_report_help
          output.puts <<~HELP
            jump report - Generate reports

            Usage: jump report <type> [filter]

            Report Types:
              categories    List all category definitions
              brands        List brands with location counts
              clients       List clients with location counts
              types         List types with location counts
              tags          List tags with location counts
              by-brand      Group locations by brand
              by-client     Group locations by client
              by-type       Group locations by type
              by-tag        Group locations by tag
              summary       Overview of all data

            Examples:
              jump report brands
              jump report by-brand appydave
              jump report tags --format json
          HELP
        end

        def show_generate_help
          output.puts <<~HELP
            jump generate - Generate shell aliases or help content

            Usage: jump generate <target> [options]

            Targets:
              aliases     Generate shell alias file (aliases-jump.zsh)
              help        Generate help content for fzf (jump-help.txt)
              ah-help     Generate content for aliases-help.zsh (ah function format)
              all         Generate both aliases and help files

            Options:
              --output <file>       Write to specific file (for aliases, help, ah-help)
              --output-dir <dir>    Write to directory (for all)

            Examples:
              jump generate aliases
              jump generate aliases --output ~/.oh-my-zsh/custom/aliases-jump.zsh
              jump generate help --output ~/.oh-my-zsh/custom/data/jump-help.txt
              jump generate ah-help --output ~/.oh-my-zsh/custom/aliases-help.zsh
              jump generate all --output-dir ~/.oh-my-zsh/custom/
          HELP
        end
      end
    end
  end
end
