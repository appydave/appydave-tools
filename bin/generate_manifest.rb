#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate projects.json manifest by scanning local and SSD directories
# Tracks video projects across storage locations with grouped folder support
#
# Usage: ruby generate_manifest.rb

require 'json'
require 'fileutils'

# Load configuration
SCRIPT_DIR = File.dirname(__FILE__)
TOOLS_DIR = File.expand_path(File.join(SCRIPT_DIR, '..'))
require_relative '../lib/config_loader'

# Determine paths relative to current working directory (repo root)
LOCAL_BASE = Dir.pwd
LOCAL_ARCHIVED = File.join(LOCAL_BASE, 'archived')
OUTPUT_FILE = File.join(LOCAL_BASE, 'projects.json')

# Load SSD_BASE from config
begin
  config = ConfigLoader.load_from_repo(LOCAL_BASE)
  SSD_BASE = config['SSD_BASE']
rescue ConfigLoader::ConfigNotFoundError, ConfigLoader::InvalidConfigError => e
  puts e.message
  exit 1
end

def heavy_files?(dir)
  return false unless Dir.exist?(dir)

  Dir.glob(File.join(dir, '*.{mp4,mov,avi,mkv,webm}')).any?
end

def light_files?(dir)
  return false unless Dir.exist?(dir)

  Dir.glob(File.join(dir, '**/*.{srt,vtt,jpg,png,md,txt,json,yml}')).any?
end

def build_ssd_range_map
  return @ssd_range_map if @ssd_range_map

  @ssd_range_map = {}
  Dir.glob(File.join(SSD_BASE, '*/')).each do |range_path|
    range_name = File.basename(range_path)
    Dir.glob(File.join(range_path, '*/')).each do |project_path|
      proj_id = File.basename(project_path)
      @ssd_range_map[proj_id] = range_name
    end
  end

  @ssd_range_map
end

def get_range_for_project(project_id)
  build_ssd_range_map[project_id]
end

# Validation functions
def validate_project_id_format(project_id)
  # Valid formats:
  # - Modern: letter + 2 digits + dash + name (e.g., a00-project, b63-flivideo)
  # - Legacy: just numbers (e.g., 006-ac-carnivore-90, 010-bing-gpt)
  !!(project_id =~ /^[a-z]\d{2}-/ || project_id =~ /^\d/)
end

def extract_prefix(project_id)
  # Extract the prefix (e.g., "b63" from "b63-flivideo")
  match = project_id.match(/^([a-z]\d{2})/)
  match ? match[1] : nil
end

def compare_prefixes(prefix1, prefix2)
  # Compare two prefixes (e.g., "a12" vs "b40")
  # Returns: -1 if prefix1 < prefix2, 0 if equal, 1 if prefix1 > prefix2
  return 0 if prefix1 == prefix2

  letter1 = prefix1[0]
  num1 = prefix1[1..2].to_i
  letter2 = prefix2[0]
  num2 = prefix2[1..2].to_i

  if letter1 == letter2
    num1 <=> num2
  else
    letter1 <=> letter2
  end
end

def validate_flat_structure_consistency(projects)
  warnings = []

  flat_prefixes = extract_flat_prefixes(projects)
  return warnings if flat_prefixes.empty?

  oldest_flat = flat_prefixes.first
  newest_flat = flat_prefixes.last

  grouped_prefixes = extract_grouped_prefixes(projects)
  warnings.concat(check_grouped_within_flat_range(grouped_prefixes, oldest_flat, newest_flat))

  warnings
end

def extract_flat_prefixes(projects)
  flat_projects = projects.select { |p| p[:storage][:local][:structure] == 'flat' }
  flat_projects.map { |p| extract_prefix(p[:id]) }.compact.sort
end

def extract_grouped_prefixes(projects)
  grouped_projects = projects.select { |p| p[:storage][:local][:structure] == 'grouped' }
  grouped_projects.map { |p| extract_prefix(p[:id]) }.compact
end

def check_grouped_within_flat_range(grouped_prefixes, oldest_flat, newest_flat)
  warnings = []
  grouped_prefixes.each do |grouped_prefix|
    next unless prefix_within_flat_range?(grouped_prefix, oldest_flat, newest_flat)

    warnings << "⚠️  WARNING: Project #{grouped_prefix}-* is in grouped structure but falls within flat range (#{oldest_flat} - #{newest_flat})"
  end
  warnings
end

def prefix_within_flat_range?(prefix, oldest_flat, newest_flat)
  0.between?(compare_prefixes(prefix, newest_flat), compare_prefixes(prefix, oldest_flat))
end

def validate_project_id_formats(projects)
  warnings = []

  projects.each do |project|
    warnings << "⚠️  WARNING: Invalid project ID format: #{project[:id]}" unless validate_project_id_format(project[:id])
  end

  warnings
end

def find_local_project(project_id)
  range = get_range_for_project(project_id)

  # Check flat structure first (active projects at root)
  flat_path = File.join(LOCAL_BASE, project_id)
  return flat_path if Dir.exist?(flat_path)

  # Check archived/grouped folder structure (if we know the range)
  if range
    archived_path = File.join(LOCAL_ARCHIVED, range, project_id)
    return archived_path if Dir.exist?(archived_path)
  end

  nil
end

def get_ssd_path(project_id)
  range = get_range_for_project(project_id)
  return nil unless range

  File.join(SSD_BASE, range, project_id)
end

# Require SSD to be mounted
unless Dir.exist?(SSD_BASE)
  puts "❌ SSD not mounted at #{SSD_BASE}"
  puts '   Please connect the SSD before running this tool.'
  puts '   The manifest requires scanning both local AND SSD to be accurate.'
  exit 1
end

# Collect all unique project IDs from both locations
all_project_ids = []

# Scan SSD (all range folders)
if Dir.exist?(SSD_BASE)
  Dir.glob(File.join(SSD_BASE, '*/')).each do |range_path|
    File.basename(range_path)
    # Look for project folders (a*, b*, or anything that looks like a project)
    Dir.glob(File.join(range_path, '*/')).each do |project_path|
      all_project_ids << File.basename(project_path)
    end
  end
end

# Scan local flat (root level projects)
Dir.glob(File.join(LOCAL_BASE, '*/')).each do |path|
  basename = File.basename(path)
  # Skip non-project directories
  next if basename == 'archived'
  next if basename == 'final'
  next unless validate_project_id_format(basename)

  # Add flat project
  all_project_ids << basename
end

# Scan local archived (grouped folders inside archived/)
if Dir.exist?(LOCAL_ARCHIVED)
  Dir.glob(File.join(LOCAL_ARCHIVED, '*/')).each do |range_path|
    Dir.glob(File.join(range_path, '*/')).each do |project_path|
      all_project_ids << File.basename(project_path)
    end
  end
end

all_project_ids = all_project_ids.uniq.sort

# Build project entries
projects = []
all_project_ids.each do |project_id|
  local_path = find_local_project(project_id)
  ssd_path = get_ssd_path(project_id)

  local_exists = !local_path.nil?
  ssd_exists = ssd_path && Dir.exist?(ssd_path)

  # Determine if local is in flat or grouped structure
  # Check if path is in archived/ subdirectory
  local_structure = if local_path&.include?('/archived/')
                      'grouped'
                    elsif local_path
                      'flat'
                    end

  projects << {
    id: project_id,
    storage: {
      ssd: {
        exists: ssd_exists,
        path: "#{get_range_for_project(project_id)}/#{project_id}"
      },
      local: {
        exists: local_exists,
        structure: local_structure,
        has_heavy_files: local_exists ? heavy_files?(local_path) : false,
        has_light_files: local_exists ? light_files?(local_path) : false
      }
    }
  }
end

# Calculate disk usage for a specific path
def calculate_path_size(path)
  return 0 unless Dir.exist?(path)

  total = 0
  Dir.glob(File.join(path, '**', '*'), File::FNM_DOTMATCH).each do |file|
    total += File.size(file) if File.file?(file)
  end
  total
end

def format_bytes(bytes)
  {
    total_bytes: bytes,
    total_mb: (bytes / 1024.0 / 1024.0).round(2),
    total_gb: (bytes / 1024.0 / 1024.0 / 1024.0).round(2)
  }
end

puts '📊 Calculating disk usage...'

# Calculate local flat (root-level project folders only)
local_flat_bytes = 0
projects.each do |project|
  if project[:storage][:local][:exists] && project[:storage][:local][:structure] == 'flat'
    flat_path = File.join(LOCAL_BASE, project[:id])
    local_flat_bytes += calculate_path_size(flat_path)
  end
end

# Calculate local grouped (all grouped folders in archived/)
local_grouped_bytes = 0
projects.each do |project|
  next unless project[:storage][:local][:exists] && project[:storage][:local][:structure] == 'grouped'

  range = get_range_for_project(project[:id])
  grouped_path = File.join(LOCAL_ARCHIVED, range, project[:id])
  local_grouped_bytes += calculate_path_size(grouped_path)
end

# Calculate total SSD
ssd_bytes = 0
projects.each do |project|
  next unless project[:storage][:ssd][:exists]

  range = get_range_for_project(project[:id])
  ssd_path = File.join(SSD_BASE, range, project[:id])
  ssd_bytes += calculate_path_size(ssd_path)
end

local_flat_usage = format_bytes(local_flat_bytes)
local_grouped_usage = format_bytes(local_grouped_bytes)
ssd_usage = format_bytes(ssd_bytes)

# Build manifest
manifest = {
  config: {
    local_base: LOCAL_BASE,
    ssd_base: SSD_BASE,
    last_updated: Time.now.utc.iso8601,
    note: 'Auto-generated manifest. Regenerate with: ruby video-asset-tools/bin/generate_manifest.rb',
    disk_usage: {
      local_flat: local_flat_usage,
      local_grouped: local_grouped_usage,
      ssd: ssd_usage
    }
  },
  projects: projects
}

# Write to file
File.write(OUTPUT_FILE, JSON.pretty_generate(manifest))

puts "✅ Generated #{OUTPUT_FILE}"
puts "   Found #{projects.size} unique projects"
puts "   SSD mounted: #{Dir.exist?(SSD_BASE)}"
puts

# Summary stats
local_flat = projects.count { |p| p[:storage][:local][:structure] == 'flat' }
local_grouped = projects.count { |p| p[:storage][:local][:structure] == 'grouped' }
local_only = projects.count { |p| p[:storage][:local][:exists] && !p[:storage][:ssd][:exists] }
ssd_only = projects.count { |p| !p[:storage][:local][:exists] && p[:storage][:ssd][:exists] }
both = projects.count { |p| p[:storage][:local][:exists] && p[:storage][:ssd][:exists] }

puts 'Distribution:'
puts "  Local only: #{local_only}"
puts "  SSD only: #{ssd_only}"
puts "  Both locations: #{both}"
puts
puts 'Local structure:'
puts "  Flat (active): #{local_flat}"
puts "  Grouped (archived): #{local_grouped}"
puts

# Run validations
puts '🔍 Running validations...'
all_warnings = []

# Validate project ID formats
format_warnings = validate_project_id_formats(projects)
all_warnings.concat(format_warnings)

# Validate flat structure consistency
consistency_warnings = validate_flat_structure_consistency(projects)
all_warnings.concat(consistency_warnings)

if all_warnings.empty?
  puts '✅ All validations passed!'
else
  puts "#{all_warnings.size} warning(s) found:"
  all_warnings.each { |w| puts "   #{w}" }
end
