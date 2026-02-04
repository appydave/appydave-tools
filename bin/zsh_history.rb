#!/usr/bin/env ruby
# frozen_string_literal: true

# ZSH History Tool - Parse, filter, and clean ZSH history

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

# ZSH History CLI - Parse, filter, and clean ZSH history
class ZshHistoryCLI
  def initialize
    @commands = {
      'help' => method(:help_command),
      'show' => method(:show_command),
      'stats' => method(:stats_command),
      'search' => method(:search_command),
      'purge' => method(:purge_command),
      'config' => method(:config_command)
    }
  end

  def run
    command = ARGV[0]

    # Handle --version and -v flags
    if ['--version', '-v'].include?(command)
      puts "zsh_history v#{Appydave::Tools::VERSION}"
      puts 'Part of appydave-tools gem'
      exit
    end

    # Handle --help and -h flags
    if ['--help', '-h'].include?(command)
      show_main_help
      exit
    end

    if command.nil?
      puts 'ZSH History - Parse, filter, and manage shell history'
      puts "Version: #{Appydave::Tools::VERSION}"
      puts ''
      puts 'Usage: zsh_history [command] [options]'
      puts ''
      puts 'Commands:'
      puts '  zsh_history show               # Display wanted commands'
      puts '  zsh_history stats              # Show statistics'
      puts '  zsh_history search <pattern>   # Search history'
      puts '  zsh_history purge              # Rewrite history file (careful!)'
      puts '  zsh_history config             # Manage configuration/profiles'
      puts ''
      puts "Run 'zsh_history help' for more information."
      exit
    end

    if @commands.key?(command)
      @commands[command].call(ARGV[1..])
    else
      puts "Unknown command: #{command}"
      puts ''
      puts 'Available commands: show, stats, search, purge, config, help'
      puts ''
      puts "Run 'zsh_history help' for detailed information."
      exit 1
    end
  end

  private

  # ============================================================
  # HELP COMMAND
  # ============================================================

  # rubocop:disable Metrics/CyclomaticComplexity
  def help_command(args)
    topic = args[0]

    case topic
    when 'show'
      show_show_help
    when 'stats'
      show_stats_help
    when 'search'
      show_search_help
    when 'purge'
      show_purge_help
    when 'config'
      show_config_help
    when 'profiles'
      show_profiles_help
    when 'patterns'
      show_patterns_help
    when 'workflow'
      show_workflow_help
    when nil
      show_main_help
    else
      puts "Unknown help topic: #{topic}"
      puts ''
      puts 'Available help topics:'
      puts '  zsh_history help show       # Display filtered commands'
      puts '  zsh_history help stats      # Show statistics'
      puts '  zsh_history help search     # Search history'
      puts '  zsh_history help purge      # Rewrite history file'
      puts '  zsh_history help config     # Configuration management'
      puts '  zsh_history help profiles   # Profile system'
      puts '  zsh_history help patterns   # Include/exclude pattern system'
      puts '  zsh_history help workflow   # Typical usage workflow'
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def show_main_help
    puts <<~HELP
      ZSH History - Parse, filter, and manage shell history

      Usage: zsh_history [command] [options]

      Commands:
        show                 Display wanted commands (read-only)
        stats                Show statistics about your history
        search <pattern>     Search history with regex pattern
        purge                Rewrite history file (removes unwanted)
        config               Manage configuration and profiles
        help [topic]         Show help information

      Quick Examples:
        zsh_history show                          # Display wanted commands
        zsh_history show --days 7                 # Last 7 days only
        zsh_history show --profile crash-recovery # Use specific profile
        zsh_history stats                         # Show statistics
        zsh_history search docker                 # Find docker commands
        zsh_history config init                   # Create config files

      Global Options:
        -p, --profile NAME   Use named profile for patterns
        -d, --days N         Only show last N days

      Help Topics:
        zsh_history help show       # Display options
        zsh_history help stats      # Statistics options
        zsh_history help search     # Search options
        zsh_history help purge      # Rewrite history file
        zsh_history help config     # Configuration management
        zsh_history help profiles   # Profile system
        zsh_history help patterns   # How patterns work
        zsh_history help workflow   # Typical usage workflow

      How It Works:
        Commands are categorized into three groups:
        - WANTED:   Useful commands to keep (git commit, docker, rake, etc.)
        - UNWANTED: Noise to remove (ls, cd, typos, output lines)
        - UNSURE:   Commands that don't match any pattern

        Patterns can be customized via profiles. See 'zsh_history help profiles'.

      For more information: https://github.com/appydave/appydave-tools
    HELP
  end

  def show_show_help
    puts <<~HELP
      Show Command - Display filtered commands (read-only)

      Usage: zsh_history show [options]

      Options:
        -d, --days N         Only show last N days
        -u, --unsure         Show only unsure commands (for debugging patterns)
        -a, --all            Show ALL commands (no filtering)
        -v, --verbose        Show which pattern matched each command
        -p, --profile NAME   Use named profile for patterns
        -o, --output PATH    Write output to file instead of stdout
        -f, --file PATH      Use different history file (default: ~/.zsh_history)

      Examples:
        zsh_history show                     # Show wanted commands
        zsh_history show --days 7            # Last 7 days
        zsh_history show --unsure            # Show only unsure commands
        zsh_history show --verbose           # Show matching patterns
        zsh_history show --all               # Show everything unfiltered
        zsh_history show -o history.txt      # Write to file
        zsh_history show --profile file-exploration  # Use different profile

      Output Format:
        2025-12-13 10:30:45  git commit -m "Add feature"
        2025-12-13 10:31:02  docker build .

      Verbose Output:
        2025-12-13 10:30:45  [WANTED: ^git commit]  git commit -m "Add feature"
        2025-12-13 10:31:02  [WANTED: ^docker ]     docker build .

      See Also:
        zsh_history help patterns   # Understand the filtering system
        zsh_history help purge      # Actually rewrite history file
    HELP
  end

  def show_stats_help
    puts <<~HELP
      Stats Command - Show history statistics

      Usage: zsh_history stats [options]

      Options:
        -d, --days N         Only analyze last N days
        -f, --file PATH      Use different history file

      Examples:
        zsh_history stats              # Full history stats
        zsh_history stats --days 7     # Last 7 days only
        zsh_history stats --days 30    # Last 30 days

      Output:
        ZSH History Statistics
        ==================================================
        Total commands:    8265
        Wanted:            2693  (32.6%)
        Unwanted:          2610  (31.6%)
        Unsure:            2962  (35.8%)

        Date range: 2025-08-24 to 2025-12-13 (111 days)

      Use Cases:
        - See how much noise is in your history
        - Track history size over time
        - Decide if you need to clean up
    HELP
  end

  def show_search_help
    puts <<~HELP
      Search Command - Search history with regex

      Usage: zsh_history search <pattern> [options]

      Options:
        -d, --days N         Only search last N days
        -a, --all            Search ALL commands (not just wanted)
        -f, --file PATH      Use different history file

      Pattern:
        Uses Ruby regex (case-insensitive by default)

      Examples:
        zsh_history search docker           # Find docker commands
        zsh_history search "git.*main"      # Git commands with 'main'
        zsh_history search dam              # Find DAM tool usage
        zsh_history search claude           # Find Claude CLI usage
        zsh_history search "npm|yarn|bun"   # Any JS package manager

      With Date Filter:
        zsh_history search docker --days 7  # Docker commands this week

      Search All (including unwanted):
        zsh_history search ls --all         # Even though 'ls' is unwanted
    HELP
  end

  def show_patterns_help
    puts <<~HELP
      Pattern System - How commands are categorized

      Commands are matched against regex patterns in this order:
      1. EXCLUDE patterns checked first (marks as UNWANTED)
      2. INCLUDE patterns checked second (marks as WANTED)
      3. No match = UNSURE

      EXCLUDE Patterns (noise removal):
        ^[a-z]$              Single letter typos
        ^[a-z]{2}$           Two letter typos
        ^ls$, ^ls -          Directory listings
        ^pwd$, ^clear$       Basic navigation
        ^cd$, ^cd ..$        Directory changes
        ^git status$         Quick git checks (not commits)
        ^git diff$, ^git log$
        ^gs$, ^gd$, ^gl$     Git aliases
        ^history             History commands
        ^which, ^type        Command lookups
        ^cat, ^head, ^tail   File viewing
        ^zsh: command not found  Error messages

      INCLUDE Patterns (valuable commands):
        ^git commit          Commits (not status/diff)
        ^git push, ^git add
        ^docker              Docker commands
        ^claude              Claude CLI
        ^dam                 DAM tool
        ^rake, ^bundle       Ruby development
        ^bun, ^npm run       JS development
        ^brew install        Package installation
        ^j[a-z]              Jump aliases (jad, jfli, etc.)

      UNSURE:
        Commands matching neither list need manual review.
        Use --unsure flag to include them in output.

      Examples:
        'vim file.txt'       -> UNSURE (not in either list)
        'git status'         -> UNWANTED (in exclude list)
        'git commit -m "x"'  -> WANTED (in include list)
        'ls -la'             -> UNWANTED (matches ^ls -)
        'docker build .'     -> WANTED (matches ^docker )
    HELP
  end

  def show_workflow_help
    puts <<~HELP
      Typical Workflow - How to use this tool

      1. CHECK STATS FIRST
         See how much noise is in your history:

         $ zsh_history stats
         Total: 8265, Wanted: 32.6%, Unwanted: 31.6%, Unsure: 35.8%

      2. REVIEW WHAT WOULD BE KEPT
         Preview the filtered output:

         $ zsh_history show --days 30

      3. CHECK UNSURE COMMANDS
         See what's not being categorized:

         $ zsh_history show --unsure --days 7

      4. SEARCH FOR SPECIFIC COMMANDS
         Find commands you need:

         $ zsh_history search docker
         $ zsh_history search "git.*feature"

      5. DRY RUN FIRST
         Preview what purge would do:

         $ zsh_history purge --days 90 --dry-run

      6. PURGE HISTORY (CAREFUL!)
         Only when you're confident:

         $ zsh_history purge --days 90

         This creates a backup first:
         ~/.zsh_history.backup.20251213-103045

      Use Cases:
        - After a terminal crash, find what you were doing
        - Clean up history before sharing screen
        - Remove noise accumulated over months
        - Find that docker command from last week
    HELP
  end

  def show_purge_help
    puts <<~HELP
      Purge Command - Rewrite history file (DANGEROUS!)

      Removes unwanted commands from your history file permanently.

      Usage: zsh_history purge [options]

      Options:
        -d, --days N         Only keep last N days
        -u, --unsure         Include unsure commands (keep more)
        --dry-run            Preview what would be removed
        -f, --file PATH      Use different history file

      Safety Features:
        1. Creates timestamped backup before writing:
           ~/.zsh_history.backup.20251213-103045

        2. Refuses if keeping < 10% of commands:
           "This seems too aggressive"

        3. Shows count before/after

      Examples:
        # Preview first with show
        zsh_history show --days 90

        # Then purge
        zsh_history purge --days 90

        # Keep unsure commands too
        zsh_history purge --days 90 --unsure

        # Dry run (preview only)
        zsh_history purge --days 90 --dry-run

      Recovery:
        If something goes wrong, restore from backup:

        $ cp ~/.zsh_history.backup.20251213-103045 ~/.zsh_history
        $ exec zsh  # Reload shell

      WARNING:
        - This permanently modifies your history file
        - The backup is your only recovery option
        - Test with 'show' first to preview
        - Consider keeping unsure commands (--unsure)
    HELP
  end

  def show_config_help
    puts <<~HELP
      Config Command - Manage configuration and profiles

      Usage: zsh_history config [subcommand]

      Subcommands:
        (none)               Show configuration status
        init                 Create default config files
        list                 List available profiles
        path                 Show config directory path

      Examples:
        zsh_history config           # Show status
        zsh_history config init      # Create default config
        zsh_history config list      # List profiles

      Config Location:
        ~/.config/appydave/zsh_history/

      Config Structure:
        config.txt           - Settings (default_profile=crash-recovery)
        base_exclude.txt     - Patterns always excluded (typos, output)
        profiles/
          crash-recovery/
            exclude.txt      - Profile-specific excludes
            include.txt      - Profile-specific includes

      See Also:
        zsh_history help profiles   # How profiles work
        zsh_history help patterns   # Pattern format
    HELP
  end

  def show_profiles_help
    puts <<~HELP
      Profile System - Scenario-specific pattern sets

      Profiles allow different include/exclude patterns for different use cases.
      The same command might be "wanted" in one scenario but "noise" in another.

      How It Works:
        1. base_exclude.txt is ALWAYS applied (typos, output lines, errors)
        2. Profile adds additional exclude/include patterns
        3. Patterns are simple regex, one per line

      Built-in Profile: crash-recovery
        Use case: Find what you were working on when terminal crashed
        Excludes: ls, cd, git status (navigation noise)
        Includes: git commit, docker, rake (actual work)

      Using Profiles:
        zsh_history show --profile crash-recovery
        zsh_history stats --profile crash-recovery
        zsh_history purge --profile crash-recovery

      Default Profile:
        Set in ~/.config/appydave/zsh_history/config.txt:
        default_profile=crash-recovery

        When set, profile is used automatically without --profile flag.

      Creating Custom Profiles:
        1. Create directory: ~/.config/appydave/zsh_history/profiles/my-profile/
        2. Add exclude.txt with patterns to exclude
        3. Add include.txt with patterns to include
        4. Use: zsh_history show --profile my-profile

      Example Profile: file-exploration
        exclude.txt:
          ^git
          ^docker
          ^rake
        include.txt:
          ^cat
          ^head
          ^tail
          ^less
          ^vim
          ^nano

      Pattern Format:
        - One regex per line
        - Lines starting with # are comments
        - Blank lines ignored
        - Case-insensitive matching
        - ^ anchors to start of command
    HELP
  end

  # ============================================================
  # SHOW COMMAND
  # ============================================================

  def show_command(args)
    options = parse_common_options(args)

    parser_instance = Appydave::Tools::ZshHistory::Parser.new(options[:history_path])
    commands = parser_instance.parse

    if commands.empty?
      puts "No commands found in #{options[:history_path]}"
      exit
    end

    filter = Appydave::Tools::ZshHistory::Filter.new(profile: options[:profile])
    result = filter.apply(commands, days: options[:days])

    formatter = Appydave::Tools::ZshHistory::Formatter.new

    output = if options[:all]
               formatter.format_commands(commands, verbose: options[:verbose])
             elsif options[:unsure]
               formatter.format_commands(result.unsure.sort_by(&:timestamp), verbose: options[:verbose])
             else
               formatter.format_commands(result.wanted.sort_by(&:timestamp), verbose: options[:verbose])
             end

    write_output(output, options[:output])
  end

  # ============================================================
  # PURGE COMMAND
  # ============================================================

  def purge_command(args)
    options = parse_common_options(args)

    parser_instance = Appydave::Tools::ZshHistory::Parser.new(options[:history_path])
    commands = parser_instance.parse

    if commands.empty?
      puts "No commands found in #{options[:history_path]}"
      exit
    end

    filter = Appydave::Tools::ZshHistory::Filter.new(profile: options[:profile])
    result = filter.apply(commands, days: options[:days])

    commands_to_write = result.wanted
    commands_to_write += result.unsure if options[:unsure]

    if commands_to_write.size < commands.size * 0.1
      puts "Warning: Would only keep #{commands_to_write.size} of #{commands.size} commands (< 10%)"
      puts 'This seems too aggressive. Use --days to be more selective or check your patterns.'
      exit 1
    end

    if options[:dry_run]
      puts "DRY RUN - Would keep #{commands_to_write.size} of #{commands.size} commands"
      puts "  Wanted:   #{result.wanted.size}"
      puts "  Unsure:   #{result.unsure.size}#{options[:unsure] ? ' (included)' : ' (excluded)'}"
      puts "  Unwanted: #{result.unwanted.size} (removed)"
      puts ''
      puts "Run without --dry-run to actually rewrite #{options[:history_path]}"
    else
      formatter = Appydave::Tools::ZshHistory::Formatter.new
      formatter.write_history(commands_to_write, options[:history_path])
    end
  end

  # ============================================================
  # STATS COMMAND
  # ============================================================

  def stats_command(args)
    options = parse_common_options(args)

    parser_instance = Appydave::Tools::ZshHistory::Parser.new(options[:history_path])
    commands = parser_instance.parse

    if commands.empty?
      puts "No commands found in #{options[:history_path]}"
      exit
    end

    filter = Appydave::Tools::ZshHistory::Filter.new(profile: options[:profile])
    result = filter.apply(commands, days: options[:days])

    date_range = nil
    unless commands.empty?
      sorted = commands.sort_by(&:timestamp)
      date_range = {
        from: sorted.first.formatted_datetime('%Y-%m-%d'),
        to: sorted.last.formatted_datetime('%Y-%m-%d'),
        days: ((sorted.last.timestamp - sorted.first.timestamp) / (24 * 60 * 60)).round
      }
    end

    formatter = Appydave::Tools::ZshHistory::Formatter.new
    puts formatter.format_stats(result.stats, date_range: date_range)
  end

  # ============================================================
  # SEARCH COMMAND
  # ============================================================

  def search_command(args)
    pattern = args.shift
    show_search_usage_and_exit if pattern.nil? || pattern.start_with?('-')

    options = parse_common_options(args)
    commands = load_and_filter_commands(options)
    matches = find_matches(commands, pattern, options)

    exit_with_no_matches(pattern) if matches.empty?

    formatter = Appydave::Tools::ZshHistory::Formatter.new
    puts formatter.format_commands(matches.sort_by(&:timestamp), verbose: options[:verbose])
  end

  def show_search_usage_and_exit
    puts 'Usage: zsh_history search <pattern> [options]'
    puts ''
    puts 'Examples:'
    puts '  zsh_history search docker'
    puts '  zsh_history search "git.*main"'
    puts '  zsh_history search claude --days 7'
    exit 1
  end

  def load_and_filter_commands(options)
    parser_instance = Appydave::Tools::ZshHistory::Parser.new(options[:history_path])
    commands = parser_instance.parse
    if commands.empty?
      puts "No commands found in #{options[:history_path]}"
      exit
    end
    { commands: commands, result: Appydave::Tools::ZshHistory::Filter.new(profile: options[:profile]).apply(commands, days: options[:days]) }
  end

  def find_matches(data, pattern, options)
    grep_pattern = Regexp.new(pattern, Regexp::IGNORECASE)
    if options[:all]
      data[:commands].select { |cmd| cmd.text.match?(grep_pattern) }
    else
      data[:result].wanted.select { |cmd| cmd.text.match?(grep_pattern) } +
        data[:result].unsure.select { |cmd| cmd.text.match?(grep_pattern) }
    end
  end

  def exit_with_no_matches(pattern)
    puts "No matches found for: #{pattern}"
    exit
  end

  # ============================================================
  # CONFIG COMMAND
  # ============================================================

  def config_command(args)
    subcommand = args[0]

    case subcommand
    when 'init'
      config_init
    when 'list'
      config_list
    when 'path'
      config_path
    when nil, 'status'
      config_status
    else
      puts "Unknown config subcommand: #{subcommand}"
      puts ''
      puts 'Usage: zsh_history config [subcommand]'
      puts ''
      puts 'Subcommands:'
      puts '  zsh_history config           # Show config status'
      puts '  zsh_history config init      # Create default config files'
      puts '  zsh_history config list      # List available profiles'
      puts '  zsh_history config path      # Show config directory path'
    end
  end

  def config_status
    config = Appydave::Tools::ZshHistory::Config.new

    puts 'ZSH History Configuration'
    puts '=' * 50
    puts ''
    puts "Config path: #{config.config_path}"
    puts "Configured:  #{config.configured? ? 'Yes' : 'No'}"
    puts ''

    if config.configured?
      display_profiles(config)
    else
      puts "Run 'zsh_history config init' to create default configuration."
    end
  end

  def display_profiles(config)
    puts 'Profiles:'
    profiles = config.available_profiles
    if profiles.empty?
      puts '  (none)'
    else
      profiles.each do |profile|
        default_marker = profile == config.default_profile ? ' (default)' : ''
        puts "  - #{profile}#{default_marker}"
      end
    end

    puts ''
    puts "Default profile: #{config.default_profile || '(none)'}"
  end

  def config_init
    config_path = Appydave::Tools::ZshHistory::Config.create_default_config
    puts "Created default configuration at: #{config_path}"
    puts ''
    puts 'Files created:'
    puts '  config.txt           - Default profile setting'
    puts '  base_exclude.txt     - Patterns always excluded'
    puts '  profiles/'
    puts '    crash-recovery/'
    puts '      exclude.txt      - Profile-specific excludes'
    puts '      include.txt      - Profile-specific includes'
    puts ''
    puts 'Edit these files to customize your patterns.'
  end

  def config_list
    config = Appydave::Tools::ZshHistory::Config.new

    unless config.configured?
      puts 'No configuration found.'
      puts "Run 'zsh_history config init' to create default configuration."
      return
    end

    profiles = config.available_profiles
    if profiles.empty?
      puts 'No profiles found.'
    else
      puts 'Available profiles:'
      puts ''
      profiles.each do |profile|
        default_marker = profile == config.default_profile ? ' (default)' : ''
        puts "  #{profile}#{default_marker}"
        description = load_profile_description(config.config_path, profile)
        puts "    #{description}" if description
        puts ''
      end
    end
  end

  def load_profile_description(config_path, profile)
    desc_file = File.join(config_path, 'profiles', profile, 'description.txt')
    return nil unless File.exist?(desc_file)

    lines = File.readlines(desc_file).map(&:strip).reject(&:empty?)
    # Return first line after the title (the "Use when:" line)
    lines[1] if lines.size > 1
  end

  def config_path
    puts Appydave::Tools::ZshHistory::Config::DEFAULT_CONFIG_PATH
  end

  # ============================================================
  # OUTPUT HELPERS
  # ============================================================

  def write_output(content, output_path)
    if output_path
      File.write(output_path, content)
      puts "Written to: #{output_path}"
    else
      puts content
    end
  end

  # ============================================================
  # OPTION PARSING
  # ============================================================

  def parse_common_options(args)
    options = {
      days: nil,
      unsure: false,
      verbose: false,
      all: false,
      dry_run: false,
      profile: nil,
      output: nil,
      history_path: File.expand_path('~/.zsh_history')
    }

    parser = OptionParser.new do |opts|
      opts.on('-d', '--days N', Integer, 'Only show last N days') do |days|
        options[:days] = days
      end

      opts.on('-u', '--unsure', 'Include unsure commands') do
        options[:unsure] = true
      end

      opts.on('-a', '--all', 'Show all commands (no filtering)') do
        options[:all] = true
      end

      opts.on('-v', '--verbose', 'Show which pattern matched') do
        options[:verbose] = true
      end

      opts.on('--dry-run', 'Preview changes without writing') do
        options[:dry_run] = true
      end

      opts.on('-p', '--profile NAME', 'Use named profile for patterns') do |name|
        options[:profile] = name
      end

      opts.on('-o', '--output PATH', 'Write output to file') do |path|
        options[:output] = File.expand_path(path)
      end

      opts.on('-f', '--file PATH', 'Path to history file') do |path|
        options[:history_path] = File.expand_path(path)
      end
    end

    parser.parse!(args)
    options
  end
end

# Run CLI
ZshHistoryCLI.new.run if $PROGRAM_NAME == __FILE__
