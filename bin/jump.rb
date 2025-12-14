#!/usr/bin/env ruby
# frozen_string_literal: true

# Jump Location Tool - Manage development folder locations
#
# Usage:
#   jump search <terms>           # Fuzzy search locations
#   jump get <key>                # Get by exact key
#   jump list                     # List all locations
#   jump add --key <key> --path <path>  # Add new location
#   jump update <key> [options]   # Update location
#   jump remove <key> --force     # Remove location
#   jump validate [key]           # Check paths exist
#   jump report <type>            # Generate reports
#   jump generate <target>        # Generate aliases/help
#   jump info                     # Show config info
#
# Examples:
#   jump search appydave ruby
#   jump add --key my-proj --path ~/dev/my-proj --brand appydave
#   jump generate aliases --output ~/.oh-my-zsh/custom/aliases-jump.zsh

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'appydave/tools'

cli = Appydave::Tools::Jump::CLI.new
exit_code = cli.run(ARGV)
exit(exit_code)
