# DAM CLI Implementation Guide

**Practical code-level guide for implementing CLI enhancements**

This document provides the technical details needed to implement the CLI changes specified in [dam-cli-enhancements.md](dam-cli-enhancements.md). It includes code locations, existing patterns, granular task breakdowns, and implementation examples.

---

## 📂 Codebase Structure

### Current DAM Code Organization

```
bin/
└── dam                                    # Main CLI executable (VatCLI class)

lib/appydave/tools/dam/
├── config.rb                             # Brand configuration and path resolution
├── config_loader.rb                      # Legacy config loader (deprecated)
├── manifest_generator.rb                 # ✅ EXISTS - Generates brand-level manifests
├── project_listing.rb                    # List brands and projects
├── project_resolver.rb                   # Short name expansion (b65 → b65-full-name)
├── s3_operations.rb                      # ✅ EXISTS - S3 upload/download/status
├── share_operations.rb                   # S3 pre-signed URL generation
├── status.rb                             # Unified status command
├── sync_from_ssd.rb                      # SSD → Local sync
├── repo_status.rb                        # Git status checking
├── repo_sync.rb                          # Git pull operations
└── repo_push.rb                          # Git push operations

spec/appydave/tools/dam/
└── ... (corresponding spec files)

~/.config/appydave/
└── brands.json                           # Brand configuration (6 brands)

/Users/[user]/dev/video-projects/
├── v-appydave/
│   ├── projects.json                     # Brand-level manifest (generated)
│   ├── b64-project-name/
│   │   ├── .project-manifest.json        # 🆕 NEW - Project-level manifest (optional)
│   │   ├── recordings/
│   │   ├── s3-staging/
│   │   └── ...
│   └── ...
└── ...
```

### Key Files to Modify/Create

| File | Status | Purpose |
|------|--------|---------|
| `bin/dam` | ✏️ MODIFY | Add new command handlers |
| `lib/appydave/tools/dam/manifest_generator.rb` | ✏️ MODIFY | Enhance with S3 scan data merging |
| `lib/appydave/tools/dam/s3_scanner.rb` | 🆕 NEW | Query AWS S3 for file listings |
| `lib/appydave/tools/dam/project_manifest_generator.rb` | 🆕 NEW | Generate project-level manifests with tree |
| `spec/appydave/tools/dam/s3_scanner_spec.rb` | 🆕 NEW | Specs for S3 scanner |
| `spec/appydave/tools/dam/project_manifest_generator_spec.rb` | 🆕 NEW | Specs for project manifest generator |

---

## 🔧 Existing Patterns to Follow

### 1. CLI Command Structure (bin/dam)

**Pattern:** Commands defined in hash, methods handle arguments

```ruby
class VatCLI
  def initialize
    @commands = {
      'help' => method(:help_command),
      'list' => method(:list_command),
      'manifest' => method(:manifest_command),
      # ADD NEW COMMANDS HERE:
      's3-scan' => method(:s3_scan_command),
      'project-manifest' => method(:project_manifest_command)
    }
  end

  def s3_scan_command(args)
    all_brands = args.include?('--all')
    args = args.reject { |arg| arg.start_with?('--') }
    brand_arg = args[0]

    if all_brands
      scan_all_brands
    elsif brand_arg
      scan_single_brand(brand_arg)
    else
      show_s3_scan_usage
    end
  rescue StandardError => e
    puts "❌ Error: #{e.message}"
    exit 1
  end
end
```

### 2. Brand Info Loading

**Pattern:** Use `Config` to load brand info from `brands.json`

```ruby
def load_brand_info(brand)
  Appydave::Tools::Configuration::Config.configure
  Appydave::Tools::Configuration::Config.brands.get_brand(brand)
end

# Brand info structure (from brands.json):
# {
#   "key" => "appydave",
#   "name" => "AppyDave",
#   "aws" => {
#     "profile" => "david-appydave",
#     "region" => "ap-southeast-1",
#     "s3_bucket" => "appydave-video-projects",
#     "s3_prefix" => "staging/v-appydave/"
#   },
#   "locations" => {
#     "video_projects" => "/path/to/v-appydave",
#     "ssd_backup" => "/Volumes/T7/..."
#   }
# }
```

### 3. S3 Client Creation

**Pattern:** Use AWS SDK with shared credentials (from `s3_operations.rb:53-68`)

```ruby
def create_s3_client(brand_info)
  profile_name = brand_info.aws.profile
  raise "AWS profile not configured" if profile_name.nil? || profile_name.empty?

  credentials = Aws::SharedCredentials.new(profile_name: profile_name)

  Aws::S3::Client.new(
    credentials: credentials,
    region: brand_info.aws.region,
    http_wire_trace: false,
    ssl_verify_peer: false  # Workaround for OpenSSL 3.4.x CRL issues
  )
end
```

### 4. Manifest Generation (brand-level)

**Pattern:** Scan filesystem, build project array, write JSON (from `manifest_generator.rb:21-70`)

```ruby
def generate(output_file: nil)
  output_file ||= File.join(brand_path, 'projects.json')

  # Collect project IDs from filesystem
  all_project_ids = collect_project_ids(ssd_backup, ssd_available)

  # Build entries with storage detection
  projects = build_project_entries(all_project_ids, ssd_backup, ssd_available)

  # Calculate disk usage
  disk_usage = calculate_disk_usage(projects, ssd_backup)

  # Build manifest
  manifest = {
    config: {
      brand: brand,
      local_base: brand_path,
      ssd_base: ssd_backup,
      last_updated: Time.now.utc.iso8601
    }.merge(disk_usage),
    projects: projects
  }

  # Write to file
  File.write(output_file, JSON.pretty_generate(manifest))
end
```

### 5. Progress Output

**Pattern:** Use emoji and clear status messages

```ruby
puts "📊 Generating manifest for #{brand}..."
puts "✅ Generated #{output_file}"
puts "❌ Error: #{e.message}"
puts "⚠️  Warning: #{warning_message}"
```

---

## 📋 Phase-by-Phase Implementation

### Phase 1: Naming Consolidation (Optional - Can defer)

**Status:** LOW PRIORITY - Can implement later without breaking existing functionality

**Tasks:**
- [ ] Add `ad-dam` symlink in `bin/` directory
- [ ] Add deprecation warning to `dam` executable
- [ ] Update documentation references
- [ ] Schedule removal for v1.0.0

**Skip this phase for now** - Focus on Phase 2 (S3 Scan) which delivers immediate value.

---

### Phase 2: Brand-Level S3 Scan ⭐ HIGH PRIORITY

**Goal:** Query AWS S3 to get actual file listings (not just local `s3-staging/` folder presence)

#### Task 2.1: Create S3Scanner Class

**Location:** `lib/appydave/tools/dam/s3_scanner.rb`

**Dependencies:** `aws-sdk-s3` (already in gemspec ✅)

**Implementation:**

```ruby
# frozen_string_literal: true

require 'aws-sdk-s3'

module Appydave
  module Tools
    module Dam
      # Scan S3 bucket for project files
      class S3Scanner
        attr_reader :brand_info, :brand, :s3_client

        def initialize(brand, brand_info: nil, s3_client: nil)
          @brand_info = brand_info || load_brand_info(brand)
          @brand = @brand_info.key
          @s3_client = s3_client || create_s3_client(@brand_info)
        end

        # Scan S3 for a specific project
        # @param project_id [String] Project ID (e.g., "b65-guy-monroe-marketing-plan")
        # @return [Hash] S3 file data with :file_count, :total_bytes, :last_modified
        def scan_project(project_id)
          bucket = @brand_info.aws.s3_bucket
          prefix = File.join(@brand_info.aws.s3_prefix, project_id)

          puts "🔍 Scanning S3: s3://#{bucket}/#{prefix}/"

          files = list_s3_objects(bucket, prefix)

          if files.empty?
            return {
              exists: false,
              file_count: 0,
              total_bytes: 0,
              last_modified: nil
            }
          end

          total_bytes = files.sum { |obj| obj.size }
          last_modified = files.map(&:last_modified).max

          {
            exists: true,
            file_count: files.size,
            total_bytes: total_bytes,
            last_modified: last_modified.utc.iso8601
          }
        rescue Aws::S3::Errors::ServiceError => e
          puts "⚠️  S3 scan failed for #{project_id}: #{e.message}"
          { exists: false, file_count: 0, total_bytes: 0, last_modified: nil, error: e.message }
        end

        # Scan all projects in brand's S3 bucket
        # @return [Hash] Map of project_id => scan result
        def scan_all_projects
          bucket = @brand_info.aws.s3_bucket
          prefix = @brand_info.aws.s3_prefix

          puts "🔍 Scanning all projects in S3: s3://#{bucket}/#{prefix}"

          # List all "directories" (prefixes) under brand prefix
          project_prefixes = list_s3_prefixes(bucket, prefix)

          results = {}
          project_prefixes.each do |project_id|
            results[project_id] = scan_project(project_id)
          end

          results
        end

        private

        def load_brand_info(brand)
          Appydave::Tools::Configuration::Config.configure
          Appydave::Tools::Configuration::Config.brands.get_brand(brand)
        end

        def create_s3_client(brand_info)
          profile_name = brand_info.aws.profile
          raise "AWS profile not configured for brand '#{@brand}'" if profile_name.nil? || profile_name.empty?

          credentials = Aws::SharedCredentials.new(profile_name: profile_name)

          Aws::S3::Client.new(
            credentials: credentials,
            region: brand_info.aws.region,
            http_wire_trace: false,
            ssl_verify_peer: false
          )
        end

        # List all objects under a prefix
        def list_s3_objects(bucket, prefix)
          objects = []
          continuation_token = nil

          loop do
            resp = s3_client.list_objects_v2(
              bucket: bucket,
              prefix: prefix,
              continuation_token: continuation_token
            )

            objects.concat(resp.contents)
            break unless resp.is_truncated

            continuation_token = resp.next_continuation_token
          end

          objects
        end

        # List project-level prefixes (directories) under brand prefix
        def list_s3_prefixes(bucket, prefix)
          resp = s3_client.list_objects_v2(
            bucket: bucket,
            prefix: prefix,
            delimiter: '/'
          )

          # common_prefixes returns array of prefixes like "staging/v-appydave/b65-guy-monroe/"
          resp.common_prefixes.map do |cp|
            # Extract project ID from prefix
            File.basename(cp.prefix.chomp('/'))
          end
        end
      end
    end
  end
end
```

#### Task 2.2: Add CLI Command Handler

**Location:** `bin/dam` (add method)

```ruby
def s3_scan_command(args)
  all_brands = args.include?('--all')
  args = args.reject { |arg| arg.start_with?('--') }
  brand_arg = args[0]

  if all_brands
    scan_all_brands_s3
  elsif brand_arg
    scan_single_brand_s3(brand_arg)
  else
    puts 'Usage: dam s3-scan <brand> [--all]'
    puts ''
    puts 'Scan S3 bucket to update project manifests with actual S3 file data.'
    puts ''
    puts 'Examples:'
    puts '  dam s3-scan appydave      # Scan AppyDave S3 bucket'
    puts '  dam s3-scan --all         # Scan all brands'
    exit 1
  end
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  exit 1
end

def scan_single_brand_s3(brand_arg)
  brand_key = brand_arg
  scanner = Appydave::Tools::Dam::S3Scanner.new(brand_key)

  # Scan all projects
  results = scanner.scan_all_projects

  # Load existing manifest
  Appydave::Tools::Configuration::Config.configure
  brand_info = Appydave::Tools::Configuration::Config.brands.get_brand(brand_key)
  brand_path = Appydave::Tools::Dam::Config.brand_path(brand_key)
  manifest_path = File.join(brand_path, 'projects.json')

  unless File.exist?(manifest_path)
    puts "❌ Manifest not found: #{manifest_path}"
    puts "   Run: dam manifest #{brand_key}"
    exit 1
  end

  manifest = JSON.parse(File.read(manifest_path), symbolize_names: true)

  # Merge S3 scan data into manifest
  manifest[:projects].each do |project|
    project_id = project[:id]
    s3_data = results[project_id]
    next unless s3_data

    project[:storage][:s3] = s3_data
  end

  # Update timestamp
  manifest[:config][:last_updated] = Time.now.utc.iso8601
  manifest[:config][:note] = 'Auto-generated manifest with S3 scan data. Regenerate with: dam s3-scan'

  # Write updated manifest
  File.write(manifest_path, JSON.pretty_generate(manifest))

  puts "✅ Updated manifest with S3 data: #{manifest_path}"
  puts "   Scanned #{results.size} projects"
end

def scan_all_brands_s3
  Appydave::Tools::Configuration::Config.configure
  brands_config = Appydave::Tools::Configuration::Config.brands

  brands_config.brands.each do |brand_info|
    brand_key = brand_info.key
    puts ''
    puts '=' * 60
    scan_single_brand_s3(brand_key)
  end
end
```

#### Task 2.3: Update ManifestGenerator to Support S3 Data

**Location:** `lib/appydave/tools/dam/manifest_generator.rb`

**Change:** Modify `build_project_entry` to accept optional S3 scan data

```ruby
def build_project_entry(project_id, ssd_backup, ssd_available, s3_scan_data: nil)
  # ... existing local/SSD detection code ...

  # S3 detection (use scan data if available, otherwise check local folder)
  s3_info = if s3_scan_data && s3_scan_data[project_id]
              s3_scan_data[project_id]
            else
              # Fallback to local s3-staging folder check
              s3_staging_path = File.join(local_path, 's3-staging')
              s3_exists = local_exists && Dir.exist?(s3_staging_path)
              { exists: s3_exists }
            end

  {
    id: project_id,
    type: type,
    storage: {
      ssd: { ... },
      s3: s3_info,  # Now includes file_count, total_bytes, last_modified if scanned
      local: { ... }
    }
  }
end
```

#### Task 2.4: Write Specs

**Location:** `spec/appydave/tools/dam/s3_scanner_spec.rb`

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appydave::Tools::Dam::S3Scanner do
  let(:brand) { 'appydave' }
  let(:brand_info) { double('brand_info', key: 'appydave', aws: aws_config) }
  let(:aws_config) do
    double('aws_config',
           profile: 'david-appydave',
           region: 'ap-southeast-1',
           s3_bucket: 'test-bucket',
           s3_prefix: 'staging/v-appydave/')
  end
  let(:s3_client) { instance_double(Aws::S3::Client) }

  subject { described_class.new(brand, brand_info: brand_info, s3_client: s3_client) }

  describe '#scan_project' do
    let(:project_id) { 'b65-test-project' }

    context 'when project has files in S3' do
      it 'returns S3 file data' do
        # Mock S3 response
        resp = double('response',
                      contents: [
                        double('object', size: 1000, last_modified: Time.now),
                        double('object', size: 2000, last_modified: Time.now - 3600)
                      ],
                      is_truncated: false)

        allow(s3_client).to receive(:list_objects_v2).and_return(resp)

        result = subject.scan_project(project_id)

        expect(result[:exists]).to be true
        expect(result[:file_count]).to eq 2
        expect(result[:total_bytes]).to eq 3000
        expect(result[:last_modified]).to be_a(String)
      end
    end

    context 'when project has no files in S3' do
      it 'returns empty data' do
        resp = double('response', contents: [], is_truncated: false)
        allow(s3_client).to receive(:list_objects_v2).and_return(resp)

        result = subject.scan_project(project_id)

        expect(result[:exists]).to be false
        expect(result[:file_count]).to eq 0
      end
    end
  end
end
```

#### Task 2.5: Test with Real Data

```bash
# 1. Generate base manifest (if not exists)
dam manifest appydave

# 2. Run S3 scan
dam s3-scan appydave

# 3. Verify manifest was updated
cat /Users/davidcruwys/dev/video-projects/v-appydave/projects.json | jq '.projects[0].storage.s3'

# Expected output:
# {
#   "exists": true,
#   "file_count": 15,
#   "total_bytes": 1234567890,
#   "last_modified": "2025-11-18T12:00:00Z"
# }
```

---

### Phase 3: Project-Level Manifests

**Goal:** Generate detailed file tree for individual projects

#### Task 3.1: Create ProjectManifestGenerator Class

**Location:** `lib/appydave/tools/dam/project_manifest_generator.rb`

```ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'

module Appydave
  module Tools
    module Dam
      # Generate detailed manifest for a single project
      class ProjectManifestGenerator
        attr_reader :brand, :project_id, :brand_path, :project_path

        def initialize(brand, project_id)
          @brand = brand
          @project_id = project_id
          @brand_path = Config.brand_path(brand)
          @project_path = File.join(@brand_path, @project_id)

          unless Dir.exist?(@project_path)
            raise "Project not found: #{@project_path}"
          end
        end

        def generate(output_file: nil)
          output_file ||= File.join(project_path, '.project-manifest.json')

          puts "📊 Generating project manifest for #{brand}/#{project_id}..."

          # Build directory tree
          tree = build_directory_tree(project_path)

          # Determine project type
          type = determine_project_type

          # Build manifest
          manifest = {
            project_id: project_id,
            brand: brand,
            type: type,
            generated_at: Time.now.utc.iso8601,
            tree: tree
          }

          # Write to file
          File.write(output_file, JSON.pretty_generate(manifest))

          puts "✅ Generated #{output_file}"
          puts "   Total size: #{format_bytes(tree[:total_bytes])}"
          puts "   Total files: #{tree[:file_count]}"

          manifest
        end

        private

        def build_directory_tree(dir_path, max_depth: 3, current_depth: 0)
          return nil if current_depth >= max_depth

          entries = Dir.entries(dir_path).reject { |e| e.start_with?('.') }

          subdirectories = {}
          file_count = 0
          total_bytes = 0

          entries.each do |entry|
            full_path = File.join(dir_path, entry)

            if File.directory?(full_path)
              # Recurse into subdirectory
              subtree = build_directory_tree(full_path, max_depth: max_depth, current_depth: current_depth + 1)
              if subtree
                subdirectories[entry] = subtree
                file_count += subtree[:file_count]
                total_bytes += subtree[:total_bytes]
              end
            elsif File.file?(full_path)
              # Count file
              file_count += 1
              total_bytes += File.size(full_path)
            end
          end

          {
            type: 'directory',
            file_count: file_count,
            total_bytes: total_bytes,
            subdirectories: subdirectories
          }
        end

        def determine_project_type
          # Check for storyline.json
          storyline_path = File.join(project_path, 'data', 'storyline.json')
          return 'storyline' if File.exist?(storyline_path)

          # Check for FliVideo pattern
          return 'flivideo' if project_id =~ /^[a-z]\d{2}-/

          'general'
        end

        def format_bytes(bytes)
          if bytes < 1024 * 1024
            "#{(bytes / 1024.0).round(1)} KB"
          elsif bytes < 1024 * 1024 * 1024
            "#{(bytes / (1024.0 * 1024)).round(1)} MB"
          else
            "#{(bytes / (1024.0 * 1024 * 1024)).round(2)} GB"
          end
        end
      end
    end
  end
end
```

#### Task 3.2: Add CLI Command

**Location:** `bin/dam`

```ruby
def project_manifest_command(args)
  args = args.reject { |arg| arg.start_with?('--') }
  brand_arg = args[0]
  project_arg = args[1]

  if brand_arg.nil? || project_arg.nil?
    puts 'Usage: dam project-manifest <brand> <project>'
    puts ''
    puts 'Generate detailed file tree manifest for a project.'
    puts ''
    puts 'Examples:'
    puts '  dam project-manifest appydave b65'
    puts '  dam project-manifest voz boy-baker'
    exit 1
  end

  brand_key = brand_arg
  project_id = Appydave::Tools::Dam::ProjectResolver.resolve(brand_arg, project_arg)

  generator = Appydave::Tools::Dam::ProjectManifestGenerator.new(brand_key, project_id)
  generator.generate
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  exit 1
end
```

#### Task 3.3: Add to .gitignore

**Location:** `/Users/davidcruwys/dev/ad/appydave-tools/.gitignore`

Add:
```
# DAM project manifests (transient/generated)
.project-manifest.json
```

---

### Phase 4: Bulk Operations

**Goal:** Add `manifest all` and `refresh` commands

#### Task 4.1: Implement `refresh` Command

**Location:** `bin/dam`

```ruby
def refresh_command(args)
  all_brands = args.include?('--all')
  args = args.reject { |arg| arg.start_with?('--') }
  brand_arg = args[0]

  if all_brands
    refresh_all_brands
  elsif brand_arg
    refresh_single_brand(brand_arg)
  else
    puts 'Usage: dam refresh <brand> [--all]'
    puts ''
    puts 'Refresh manifest and S3 scan data for a brand.'
    puts ''
    puts 'Examples:'
    puts '  dam refresh appydave      # Refresh AppyDave'
    puts '  dam refresh --all         # Refresh all brands'
    exit 1
  end
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  exit 1
end

def refresh_single_brand(brand_arg)
  puts "🔄 Refreshing #{brand_arg}..."

  # Step 1: Generate manifest
  generate_single_manifest(brand_arg)

  # Step 2: Scan S3
  scan_single_brand_s3(brand_arg)

  puts ''
  puts "✅ Refresh complete for #{brand_arg}"
end

def refresh_all_brands
  Appydave::Tools::Configuration::Config.configure
  brands_config = Appydave::Tools::Configuration::Config.brands

  brands_config.brands.each do |brand_info|
    brand_key = brand_info.key
    puts ''
    puts '=' * 60
    refresh_single_brand(brand_key)
  end
end
```

#### Task 4.2: Update `manifest` Command to Support `all`

Already implemented in `bin/dam:195-210` ✅

---

## 🧪 Testing Strategy

### Unit Tests

**Spec files to create:**
1. `spec/appydave/tools/dam/s3_scanner_spec.rb` - Mock S3 client
2. `spec/appydave/tools/dam/project_manifest_generator_spec.rb` - Use temp directories

**Example test structure:**

```ruby
RSpec.describe Appydave::Tools::Dam::S3Scanner do
  let(:s3_client) { instance_double(Aws::S3::Client) }
  subject { described_class.new('appydave', s3_client: s3_client) }

  describe '#scan_project' do
    it 'handles empty S3 prefix' do
      # ... mock S3 response with no files ...
    end

    it 'calculates total bytes correctly' do
      # ... mock S3 response with multiple files ...
    end

    it 'handles pagination' do
      # ... mock S3 response with is_truncated: true ...
    end
  end
end
```

### Integration Tests

**Manual testing with real data:**

```bash
# Test S3 Scanner
dam s3-scan appydave
cat ~/dev/video-projects/v-appydave/projects.json | jq '.projects[0].storage.s3'

# Test Project Manifest
dam project-manifest appydave b65
cat ~/dev/video-projects/v-appydave/b65-*/. project-manifest.json | jq '.tree'

# Test Refresh
dam refresh appydave
```

### Test Data Setup

**Option 1: Use real brands**
- Test against `appydave` brand (David's machine)
- Test against `voz` brand (different S3 bucket)

**Option 2: Create test brand**
- Add test brand to `~/.config/appydave/brands.json`
- Use separate S3 bucket: `test-video-projects`
- Add test projects with known file counts

---

## 🚀 Implementation Sequence

**Recommended order (maximize value early):**

### Week 1: S3 Scanning (Phase 2)
- **Day 1-2:** Create `S3Scanner` class and specs
- **Day 3:** Add CLI command handler
- **Day 4:** Test with real AppyDave data
- **Day 5:** Update `ManifestGenerator` to merge S3 data

**Deliverable:** `dam s3-scan appydave` command works, updates `projects.json` with real S3 file counts

### Week 2: Project Manifests (Phase 3)
- **Day 1-2:** Create `ProjectManifestGenerator` class and specs
- **Day 3:** Add CLI command handler
- **Day 4:** Test with b65 project
- **Day 5:** Add to `.gitignore`, verify transient behavior

**Deliverable:** `dam project-manifest appydave b65` generates `.project-manifest.json` with tree

### Week 3: Bulk Operations (Phase 4)
- **Day 1:** Implement `refresh` command
- **Day 2:** Test `refresh --all` with all brands
- **Day 3:** Performance optimization (parallel S3 scans?)
- **Day 4-5:** Documentation updates, edge case testing

**Deliverable:** `dam refresh --all` updates all 6 brands in one command

### Week 4: Polish (Phase 5)
- **Day 1:** Add transcript detection to manifests
- **Day 2:** Add brand color configuration
- **Day 3:** Add project type confidence scores
- **Day 4-5:** Final testing, README updates

**Deliverable:** Enhanced manifests with all metadata fields

---

## 💡 Code Examples

### Example 1: S3 Pagination Handling

```ruby
def list_s3_objects(bucket, prefix)
  objects = []
  continuation_token = nil

  loop do
    resp = s3_client.list_objects_v2(
      bucket: bucket,
      prefix: prefix,
      continuation_token: continuation_token
    )

    objects.concat(resp.contents)
    break unless resp.is_truncated

    continuation_token = resp.next_continuation_token
  end

  objects
end
```

### Example 2: Tree Builder Algorithm

```ruby
def build_directory_tree(dir_path, max_depth: 3, current_depth: 0)
  return nil if current_depth >= max_depth

  subdirectories = {}
  file_count = 0
  total_bytes = 0

  Dir.entries(dir_path).reject { |e| e.start_with?('.') }.each do |entry|
    full_path = File.join(dir_path, entry)

    if File.directory?(full_path)
      subtree = build_directory_tree(full_path, max_depth: max_depth, current_depth: current_depth + 1)
      if subtree
        subdirectories[entry] = subtree
        file_count += subtree[:file_count]
        total_bytes += subtree[:total_bytes]
      end
    elsif File.file?(full_path)
      file_count += 1
      total_bytes += File.size(full_path)
    end
  end

  {
    type: 'directory',
    file_count: file_count,
    total_bytes: total_bytes,
    subdirectories: subdirectories
  }
end
```

### Example 3: Manifest Merging

```ruby
# Load existing manifest
manifest = JSON.parse(File.read(manifest_path), symbolize_names: true)

# Scan S3
scanner = S3Scanner.new(brand)
s3_data = scanner.scan_all_projects

# Merge data
manifest[:projects].each do |project|
  project_id = project[:id]
  if s3_data.key?(project_id)
    project[:storage][:s3].merge!(s3_data[project_id])
  end
end

# Write back
File.write(manifest_path, JSON.pretty_generate(manifest))
```

---

## ⚠️ Edge Cases & Error Handling

### S3 Errors

```ruby
rescue Aws::S3::Errors::NoSuchBucket => e
  puts "❌ S3 bucket does not exist: #{bucket}"
  puts "   Check brands.json configuration for #{brand}"
  exit 1
rescue Aws::S3::Errors::AccessDenied => e
  puts "❌ Access denied to S3 bucket: #{bucket}"
  puts "   Verify AWS credentials for profile: #{profile_name}"
  exit 1
rescue Aws::S3::Errors::ServiceError => e
  puts "❌ S3 service error: #{e.message}"
  exit 1
end
```

### Missing Manifests

```ruby
unless File.exist?(manifest_path)
  puts "❌ Manifest not found: #{manifest_path}"
  puts "   Run: dam manifest #{brand}"
  puts "   Then retry: dam s3-scan #{brand}"
  exit 1
end
```

### Empty Projects

```ruby
if projects.empty?
  puts "⚠️  No projects found for brand #{brand}"
  puts "   This may indicate:"
  puts "   - Brand directory is empty"
  puts "   - SSD is not mounted"
  puts "   - Configuration error"
  return { success: false, brand: brand, path: nil }
end
```

---

## 📚 Dependencies

### Ruby Gems (Already in Gemspec)

- ✅ `aws-sdk-s3` ~> 1 - S3 operations
- ✅ `json` - JSON parsing/generation (built-in)
- ✅ `fileutils` - File operations (built-in)
- ✅ `digest` - MD5 hashing (built-in)

### External

- AWS credentials configured in `~/.aws/credentials`
- Brand configuration in `~/.config/appydave/brands.json`

---

## 🔗 Related Documentation

- [dam-cli-enhancements.md](dam-cli-enhancements.md) - Requirements specification
- [dam-data-model.md](dam-data-model.md) - Entity schema and manifest structure
- [implementation-roadmap.md](implementation-roadmap.md) - Epic organization

---

**Last updated:** 2025-11-18
