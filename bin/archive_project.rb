#!/usr/bin/env ruby
# frozen_string_literal: true

# Archive a completed video project to SSD
# 1. Copies entire project to SSD grouped folder (if not already there)
# 2. Deletes entire local project folder
# 3. Run 'ruby sync_from_ssd.rb' afterward to pull back light files to archived/
#
# Usage:
#   ruby archive_project.rb PROJECT_ID [--dry-run]
#
# Example:
#   ruby archive_project.rb b63-flivideo --dry-run   # Preview
#   ruby archive_project.rb b63-flivideo             # Execute
#   ruby sync_from_ssd.rb                            # Pull back light files
#   ruby generate_manifest.rb                        # Update dashboard
#
# Options:
#   --dry-run      : Show what would happen without making changes

require 'fileutils'

# Load configuration
SCRIPT_DIR = File.dirname(__FILE__)
TOOLS_DIR = File.expand_path(File.join(SCRIPT_DIR, '..'))
require_relative '../lib/config_loader'

# Determine paths relative to current working directory (repo root)
LOCAL_BASE = Dir.pwd
LOCAL_ARCHIVED = File.join(LOCAL_BASE, 'archived')

# Load SSD_BASE from config
begin
  config = ConfigLoader.load_from_repo(LOCAL_BASE)
  SSD_BASE = config['SSD_BASE']
rescue ConfigLoader::ConfigNotFoundError, ConfigLoader::InvalidConfigError => e
  puts e.message
  exit 1
end

def dry_run?
  ARGV.include?('--dry-run')
end

def get_range(project_id)
  # Extract letter and number from project ID
  if project_id =~ /^([a-z])(\d+)/i
    letter = Regexp.last_match(1).downcase
    num = Regexp.last_match(2).to_i
    range_suffix = num < 50 ? "00-#{letter}49" : "50-#{letter}99"
    return "#{letter}#{range_suffix}"
  elsif project_id =~ /^(\d+)/
    # Legacy numerical projects
    num = Regexp.last_match(1).to_i
    return '-01-25' if num <= 25
  end

  nil
end

def format_bytes(bytes)
  if bytes < 1024
    "#{bytes}B"
  elsif bytes < 1024 * 1024
    "#{(bytes / 1024.0).round(1)}KB"
  elsif bytes < 1024 * 1024 * 1024
    "#{(bytes / 1024.0 / 1024.0).round(1)}MB"
  else
    "#{(bytes / 1024.0 / 1024.0 / 1024.0).round(1)}GB"
  end
end

def get_dir_size(dir)
  total = 0
  Dir.glob(File.join(dir, '**', '*'), File::FNM_DOTMATCH).each do |file|
    total += File.size(file) if File.file?(file)
  end
  total
end

def copy_to_ssd(_project_id, local_path, ssd_path)
  puts "\n📦 Step 1: Copy to SSD"

  if Dir.exist?(ssd_path)
    puts "   ⚠️  Already exists on SSD: #{ssd_path}"
    puts '   Skipping copy step'
    return true
  end

  size = get_dir_size(local_path)
  puts "   Source: #{local_path}"
  puts "   Dest:   #{ssd_path}"
  puts "   Size:   #{format_bytes(size)}"

  if dry_run?
    puts '   [DRY-RUN] Would copy entire project to SSD'
  else
    FileUtils.mkdir_p(File.dirname(ssd_path))
    FileUtils.cp_r(local_path, ssd_path, preserve: true)
    puts '   ✅ Copied to SSD'
  end
  true
end

def delete_local_project(local_path)
  puts "\n🗑️  Step 2: Delete local project"

  size = get_dir_size(local_path)
  puts "   Path: #{local_path}"
  puts "   Size: #{format_bytes(size)}"

  if dry_run?
    puts '   [DRY-RUN] Would delete entire local folder'
  else
    FileUtils.rm_rf(local_path)
    puts '   ✅ Deleted local folder'
    puts "   💾 Freed: #{format_bytes(size)}"
  end
end

# Parse --next flag
def next_count
  next_idx = ARGV.index('--next')
  return nil unless next_idx

  count = ARGV[next_idx + 1]
  count ? count.to_i : 1
end

def find_oldest_flat_projects(count)
  # Get all flat project folders
  flat_projects = Dir.glob(File.join(LOCAL_BASE, '*/')).map { |path| File.basename(path) }

  # Filter to valid project IDs and sort by prefix
  valid_projects = flat_projects.grep(/^[a-z]\d{2}-/).sort_by do |id|
    match = id.match(/^([a-z])(\d{2})/)
    letter = match[1]
    num = match[2].to_i
    [letter, num]
  end

  valid_projects.take(count)
end

# Main execution
count = next_count
project_id = ARGV.find { |arg| !arg.start_with?('--') && arg != count.to_s }

if count
  # Archive multiple projects
  projects_to_archive = find_oldest_flat_projects(count)

  if projects_to_archive.empty?
    puts '❌ No flat projects found to archive'
    exit 1
  end

  puts dry_run? ? "🔍 DRY-RUN: Would archive #{projects_to_archive.size} oldest projects" : "🎬 Archiving #{projects_to_archive.size} oldest projects"
  puts '=' * 60
  puts 'Projects to archive:'
  projects_to_archive.each { |p| puts "  - #{p}" }
  puts '=' * 60
  puts

  # Process each project
  projects_to_archive.each_with_index do |proj_id, idx|
    puts "\n[#{idx + 1}/#{projects_to_archive.size}] Processing: #{proj_id}"
    puts '-' * 60

    local_path = File.join(LOCAL_BASE, proj_id)
    range = get_range(proj_id)
    ssd_path = File.join(SSD_BASE, range, proj_id)

    success = copy_to_ssd(proj_id, local_path, ssd_path)
    delete_local_project(local_path) if success
  end

  puts "\n#{'=' * 60}"
  if dry_run?
    puts "✅ Dry-run complete! Would have archived #{projects_to_archive.size} projects"
    puts '   Run without --dry-run to actually archive'
  else
    puts "✅ Archived #{projects_to_archive.size} projects!"
    puts
    puts 'Next steps:'
    puts '  1. ruby video-asset-tools/bin/sync_from_ssd.rb       # Pull back light files to archived/'
    puts '  2. ruby video-asset-tools/bin/generate_manifest.rb   # Update dashboard'
  end
  exit 0
end

unless project_id
  puts 'Usage: ruby archive_project.rb PROJECT_ID [--dry-run]'
  puts '       ruby archive_project.rb --next N [--dry-run]'
  puts
  puts 'Examples:'
  puts '  ruby archive_project.rb b63-flivideo --dry-run  # Archive specific project'
  puts '  ruby archive_project.rb --next 5 --dry-run      # Archive 5 oldest projects'
  puts
  puts 'After archiving, run:'
  puts '  ruby video-asset-tools/bin/sync_from_ssd.rb          # Pull back light files'
  puts '  ruby video-asset-tools/bin/generate_manifest.rb      # Update dashboard'
  exit 1
end

# Check SSD first
unless Dir.exist?(SSD_BASE)
  puts "❌ SSD not mounted at #{SSD_BASE}"
  puts '   Please connect the SSD before archiving.'
  exit 1
end

puts dry_run? ? "🔍 DRY-RUN: Archiving #{project_id}" : "🎬 Archiving: #{project_id}"
puts '=' * 60

# Find local project (must be in flat structure for archiving)
local_path = File.join(LOCAL_BASE, project_id)

unless Dir.exist?(local_path)
  puts "\n❌ Project not found in flat structure: #{local_path}"
  puts '   This tool archives active (flat) projects only.'
  exit 1
end

range = get_range(project_id)
unless range
  puts "\n❌ Cannot determine range for project: #{project_id}"
  puts '   Expected format: letter + 2 digits (e.g., b63-project)'
  exit 1
end

ssd_path = File.join(SSD_BASE, range, project_id)

# Execute steps
success = copy_to_ssd(project_id, local_path, ssd_path)
delete_local_project(local_path) if success

puts "\n#{'=' * 60}"
if dry_run?
  puts '✅ Dry-run complete!'
  puts '   Run without --dry-run to actually archive'
else
  puts '✅ Archive complete!'
  puts
  puts 'Next steps:'
  puts '  1. ruby video-asset-tools/bin/sync_from_ssd.rb       # Pull back light files to archived/'
  puts '  2. ruby video-asset-tools/bin/generate_manifest.rb   # Update dashboard'
end
