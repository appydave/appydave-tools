#!/usr/bin/env ruby
# frozen_string_literal: true
# rubocop:disable all

# Sync non-video files from SSD to local video directory
# Reads projects.json manifest and syncs only projects not in local flat structure
# Copies transcripts, thumbnails, and documentation while excluding video files
#
# Usage: ruby sync_from_ssd.rb [--dry-run]

require 'fileutils'
require 'json'

# Load configuration
SCRIPT_DIR = File.dirname(__FILE__)
TOOLS_DIR = File.expand_path(File.join(SCRIPT_DIR, '..'))
require_relative '../lib/config_loader'

# Determine paths relative to current working directory (repo root)
LOCAL_BASE = Dir.pwd
LOCAL_ARCHIVED = File.join(LOCAL_BASE, 'archived')
MANIFEST_FILE = File.join(LOCAL_BASE, 'projects.json')

# Load SSD_BASE from config
begin
  config = ConfigLoader.load_from_repo(LOCAL_BASE)
  SSD_BASE = config['SSD_BASE']
rescue ConfigLoader::ConfigNotFoundError, ConfigLoader::InvalidConfigError => e
  puts e.message
  exit 1
end

# Light file patterns to include (everything except heavy video files)
LIGHT_FILE_PATTERNS = %w[
  **/*.srt
  **/*.vtt
  **/*.txt
  **/*.md
  **/*.jpg
  **/*.jpeg
  **/*.png
  **/*.webp
  **/*.json
  **/*.yml
  **/*.yaml
].freeze

# Heavy file patterns to exclude (video files)
HEAVY_FILE_PATTERNS = %w[
  *.mp4
  *.mov
  *.avi
  *.mkv
  *.webm
].freeze

def dry_run?
  ARGV.include?('--dry-run')
end

def load_manifest
  unless File.exist?(MANIFEST_FILE)
    puts '❌ projects.json not found!'
    puts '   Run: ruby video-asset-tools/bin/generate_manifest.rb'
    exit 1
  end

  JSON.parse(File.read(MANIFEST_FILE), symbolize_names: true)
rescue JSON::ParserError => e
  puts "❌ Error parsing projects.json: #{e.message}"
  exit 1
end

def should_sync_project?(project)
  # Only sync if project exists on SSD but NOT in local flat structure
  return false unless project[:storage][:ssd][:exists]

  # Skip if exists locally in flat structure
  return false if project[:storage][:local][:exists] && project[:storage][:local][:structure] == 'flat'

  true
end

def validate_no_flat_conflict(project_id)
  flat_path = File.join(LOCAL_BASE, project_id)
  Dir.exist?(flat_path)
end

def sync_project(project)
  project_id = project[:id]
  ssd_path = File.join(SSD_BASE, project[:storage][:ssd][:path])
  range = project[:storage][:ssd][:path].split('/')[0]
  local_dir = File.join(LOCAL_ARCHIVED, range, project_id)

  return skip_project_result('SSD path not found') unless Dir.exist?(ssd_path)
  return skip_project_result('Flat folder exists (stale manifest?)') if validate_no_flat_conflict(project_id)

  prepare_local_directory(local_dir)
  sync_light_files(ssd_path, local_dir)
end

def skip_project_result(reason)
  { skipped: 1, files: 0, bytes: 0, reason: reason }
end

def prepare_local_directory(local_dir)
  FileUtils.mkdir_p(local_dir) if !dry_run? && !Dir.exist?(local_dir)
end

def sync_light_files(ssd_path, local_dir)
  stats = { files: 0, bytes: 0 }

  LIGHT_FILE_PATTERNS.each do |pattern|
    Dir.glob(File.join(ssd_path, pattern)).each do |source_file|
      next if heavy_file?(source_file)

      copy_file_stats = copy_light_file(source_file, ssd_path, local_dir)
      stats[:files] += copy_file_stats[:files]
      stats[:bytes] += copy_file_stats[:bytes]
    end
  end

  stats
end

def heavy_file?(source_file)
  HEAVY_FILE_PATTERNS.any? { |pattern| File.fnmatch(pattern, File.basename(source_file)) }
end

def copy_light_file(source_file, ssd_path, local_dir)
  relative_path = source_file.sub("#{ssd_path}/", '')
  dest_file = File.join(local_dir, relative_path)

  return { files: 0, bytes: 0 } if file_already_synced?(source_file, dest_file)

  file_size = File.size(source_file)
  perform_file_copy(source_file, dest_file, relative_path, file_size)

  { files: 1, bytes: file_size }
end

def file_already_synced?(source_file, dest_file)
  File.exist?(dest_file) && File.size(dest_file) == File.size(source_file)
end

def perform_file_copy(source_file, dest_file, relative_path, file_size)
  if dry_run?
    puts "  [DRY-RUN] Would copy: #{relative_path} (#{format_bytes(file_size)})"
  else
    FileUtils.mkdir_p(File.dirname(dest_file))
    FileUtils.cp(source_file, dest_file, preserve: true)
    puts "  ✓ Copied: #{relative_path} (#{format_bytes(file_size)})"
  end
end

def format_bytes(bytes)
  if bytes < 1024
    "#{bytes}B"
  elsif bytes < 1024 * 1024
    "#{(bytes / 1024.0).round(1)}KB"
  else
    "#{(bytes / 1024.0 / 1024.0).round(1)}MB"
  end
end

# Main execution
puts dry_run? ? '🔍 DRY-RUN MODE - No files will be copied' : '📦 Syncing from SSD...'
puts

unless Dir.exist?(SSD_BASE)
  puts "❌ SSD not mounted at #{SSD_BASE}"
  exit 1
end

# Load manifest
manifest = load_manifest
puts "📋 Loaded manifest: #{manifest[:projects].size} projects"
puts "   Last updated: #{manifest[:config][:last_updated]}"
puts

# Filter projects to sync
projects_to_sync = manifest[:projects].select { |p| should_sync_project?(p) }

puts '🔍 Analysis:'
puts "   Total projects in manifest: #{manifest[:projects].size}"
puts "   Projects to sync: #{projects_to_sync.size}"
puts "   Skipped (in flat structure): #{manifest[:projects].size - projects_to_sync.size}"
puts

if projects_to_sync.empty?
  puts '✅ Nothing to sync - all projects either in flat structure or already synced'
  exit 0
end

total_stats = { files: 0, bytes: 0, skipped: 0, validation_skipped: 0 }

projects_to_sync.each do |project|
  stats = sync_project(project)

  # Only show project if there are files to sync or a warning
  if stats[:reason] || stats[:files]&.positive?
    puts "📁 #{project[:id]}"

    if stats[:reason]
      puts "  ⚠️  Skipped: #{stats[:reason]}"
      total_stats[:validation_skipped] += 1 if stats[:reason].include?('stale')
    end

    puts "  #{stats[:files]} file(s), #{format_bytes(stats[:bytes])}" if stats[:files]&.positive?
    puts
  end

  total_stats[:files] += stats[:files] || 0
  total_stats[:bytes] += stats[:bytes] || 0
  total_stats[:skipped] += stats[:skipped] || 0
end

puts
puts '=' * 60
puts 'Summary:'
puts "  Projects scanned: #{projects_to_sync.size}"
puts "  Projects skipped (validation): #{total_stats[:validation_skipped]}" if total_stats[:validation_skipped].positive?
puts "  Files #{dry_run? ? 'to copy' : 'copied'}: #{total_stats[:files]}"
puts "  Total size: #{format_bytes(total_stats[:bytes])}"
puts

if total_stats[:validation_skipped].positive?
  puts '⚠️  WARNING: Some projects were skipped due to validation failures'
  puts '   This may indicate a stale manifest. Consider running:'
  puts '   ruby video-asset-tools/bin/generate_manifest.rb'
  puts
end

puts '✅ Sync complete!'
puts '   Run without --dry-run to perform the sync' if dry_run?
puts "   Run 'ruby video-asset-tools/bin/generate_manifest.rb' to update manifest with new state" unless dry_run?
