# Name Manager

Parse and generate project names following AppyDave naming conventions and channel codes.

## What It Does

**Name Manager** handles project naming and parsing:

- Parses project names following AppyDave conventions
- Generates standardized project names
- Extracts sequence numbers, channel codes, and project descriptors
- Validates names against configured channels
- Enforces naming consistency across projects

## Naming Convention

AppyDave project names follow this pattern:

```
{sequence}-{channel-code}-{project-name}
```

**Examples**:
- `b60-appydave-intro-to-system-design`
  - Sequence: `b60`
  - Channel: `appydave`
  - Project: `intro-to-system-design`

- `b61-aitldr-ai-graphics-basics`
  - Sequence: `b61`
  - Channel: `aitldr`
  - Project: `ai-graphics-basics`

- `50-quick-tip`
  - Sequence: `50`
  - Channel: (none - uses default)
  - Project: `quick-tip`

## How to Use

### Parse Project Name

```ruby
require 'appydave/tools'

# Parse a project filename
project = Appydave::Tools::NameManager::ProjectName.new('b60-appydave-intro-to-coding.md')

project.sequence              # => "b60"
project.channel_code          # => "appydave"
project.project_name          # => "intro-to-coding"
project.generate_name         # => "b60-appydave-intro-to-coding"
```

### Generate Project Name

```ruby
require 'appydave/tools'

project = Appydave::Tools::NameManager::ProjectName.new('b60-appydave-intro-to-coding.md')

# Set new values
project.sequence = 'b75'
project.project_name = 'advanced-system-design'

# Generate updated name
new_name = project.generate_name
# => "b75-appydave-advanced-system-design"
```

### Set Channel Code

```ruby
require 'appydave/tools'

project = Appydave::Tools::NameManager::ProjectName.new('b60-intro-to-coding.md')

# Set channel code (validates against configured channels)
project.channel_code = 'appydave'

project.generate_name
# => "b60-appydave-intro-to-coding"
```

## Use Cases for AI Agents

### 1. Project Inventory Generation
```ruby
# AI parses all project files
projects = Dir.glob('**/*.md').map do |file|
  Appydave::Tools::NameManager::ProjectName.new(file)
end

# Generates inventory with sequence, channel, project name
projects.each do |p|
  puts "#{p.sequence} (#{p.channel_code}): #{p.project_name}"
end
```
**AI discovers**: Project structure, naming patterns, distribution across channels. Can generate comprehensive inventory.

### 2. Channel Migration
```ruby
# AI renames projects when moving between channels
# From appydave to aitldr
project = Appydave::Tools::NameManager::ProjectName.new('b60-appydave-old-project.md')
project.channel_code = 'aitldr'
new_name = project.generate_name
# => "b60-aitldr-old-project"
```
**AI discovers**: Channel organization. Can systematically rename projects during migrations.

### 3. Sequence Number Management
```ruby
# AI analyzes sequence numbers
# Identifies gaps, next available number
projects = Dir.glob('b*.md').map { |f| ProjectName.new(f) }
sequences = projects.map(&:sequence).sort

# Find next sequence number
last_sequence = sequences.last  # "b75"
next_sequence = "b#{last_sequence.sub(/^b/, '').to_i + 1}"
# => "b76"
```
**AI discovers**: Sequence patterns, gaps. Can manage project numbering scheme.

### 4. Naming Validation
```ruby
# AI validates all projects follow naming convention
Dir.glob('**/*').each do |file|
  project = ProjectName.new(file)
  if project.sequence.nil? || project.project_name.nil?
    puts "Invalid name: #{file}"
  end
end
```
**AI discovers**: Naming compliance. Can identify and fix naming violations.

### 5. Multi-Channel Reporting
```ruby
# AI generates reports by channel
channels = {}
Dir.glob('**/*.md').each do |file|
  project = ProjectName.new(file)
  channels[project.channel_code] ||= []
  channels[project.channel_code] << project
end

channels.each do |channel, projects|
  puts "#{channel}: #{projects.length} projects"
end
```
**AI discovers**: Projects per channel. Can generate channel-specific reports.

### 6. Bulk Renaming
```ruby
# AI orchestrates renaming operation
# When naming convention changes
Dir.glob('**/*.md').each do |old_file|
  project = ProjectName.new(old_file)
  # Apply new naming rules
  new_name = "#{project.sequence}-#{project.channel_code}-#{project.project_name.upcase}.md"
  File.rename(old_file, new_name) if old_file != new_name
end
```
**AI discovers**: Current naming scheme. Can apply new conventions systematically.

### 7. Project Organization
```ruby
# AI organizes projects by channel
Dir.glob('**/*.md').each do |file|
  project = ProjectName.new(file)
  channel_dir = "projects/#{project.channel_code}"
  FileUtils.mkdir_p(channel_dir)
  FileUtils.mv(file, "#{channel_dir}/#{project.generate_name}.md")
end
```
**AI discovers**: Naming patterns. Can reorganize by channel using names.

### 8. Name Conflict Detection
```ruby
# AI identifies duplicate project names
names = Dir.glob('**/*').map { |f| ProjectName.new(f).generate_name }
duplicates = names.group_by { |n| n }.select { |_, v| v.length > 1 }

duplicates.each do |name, count|
  puts "Duplicate: #{name} (#{count} files)"
end
```
**AI discovers**: Naming collisions. Can identify and help resolve duplicates.

### 9. Sequence Gap Analysis
```ruby
# AI analyzes sequence number coverage
projects = Dir.glob('b*.md').map { |f| ProjectName.new(f) }
sequences = projects.map { |p| p.sequence.sub(/^b/, '').to_i }.sort

gaps = []
(sequences.first..sequences.last).each do |n|
  gaps << n unless sequences.include?(n)
end

puts "Gaps in sequence: #{gaps.inspect}"
```
**AI discovers**: Sequence coverage. Can identify missing numbers for reuse or filling.

### 10. Naming Standardization
```ruby
# AI ensures all names follow convention
# lowercase, hyphenated, valid channels
Dir.glob('**/*').each do |file|
  project = ProjectName.new(file)
  standardized_name = project.generate_name.downcase.gsub(/\s+/, '-')
  new_path = "#{File.dirname(file)}/#{standardized_name}#{File.extname(file)}"
  File.rename(file, new_path) if file != new_path
end
```
**AI discovers**: Naming inconsistencies. Can standardize all names.

## Class Reference

### ProjectName

```ruby
class ProjectName
  # Parse project filename
  def initialize(file_name)
  end

  # Get/set attributes
  attr_accessor :sequence
  attr_accessor :project_name
  attr_reader :channel_code

  # Generate standardized name
  def generate_name
  end

  # Set and validate channel code
  def channel_code=(code)
  end
end
```

**Attributes**:
- `sequence` - Project sequence (e.g., "b60", "50")
- `channel_code` - Channel code (e.g., "appydave", "aitldr")
- `project_name` - Project descriptor (e.g., "intro-to-coding")

**Methods**:
- `generate_name()` - Returns "{sequence}-{channel}-{project_name}" (lowercase, hyphenated)
- `channel_code=(code)` - Validates and sets channel code against configured channels

## Configuration

Names are validated against configured channels in:
```
~/.config/appydave/channels.json
```

Valid channels must be defined in configuration. Invalid channels are rejected.

## Naming Rules

1. **Sequence**: Alphanumeric identifier (e.g., `b60`, `50`)
2. **Channel** (optional): Valid configured channel code (e.g., `appydave`, `aitldr`)
3. **Project Name**: Hyphenated, lowercase (e.g., `intro-to-coding`)

**Generated Format**:
- With channel: `{seq}-{channel}-{project}` (all lowercase)
- Without channel: `{seq}-{project}` (all lowercase)

## Examples

### Parse & Regenerate
```ruby
project = ProjectName.new('B60-APPYDAVE-Intro-To-Coding')
project.generate_name
# => "b60-appydave-intro-to-coding" (normalized)
```

### Create New Project Name
```ruby
project = ProjectName.new('b60-test')
project.channel_code = 'appydave'
project.project_name = 'full-course-series'
project.generate_name
# => "b60-appydave-full-course-series"
```

### Extract Parts
```ruby
project = ProjectName.new('b60-appydave-advanced-python.md')
puts "Sequence: #{project.sequence}"           # "b60"
puts "Channel: #{project.channel_code}"        # "appydave"
puts "Project: #{project.project_name}"        # "advanced-python"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Invalid channel code" | Channel must be configured in ~/.config/appydave/channels.json |
| "Parse error" | Ensure filename follows {seq}-{channel?}-{project} format |
| "Missing sequence" | Sequence (first part) is required |
| "Invalid characters" | Project names should use hyphens, no spaces or underscores |

## Tips & Tricks

1. **Use sequence prefix**: `b` for big videos, `s` for shorts, helps with sorting
2. **Valid channel first**: Set correct channel before generating names
3. **Lowercase output**: `generate_name()` always returns lowercase
4. **Batch processing**: Use in loops to rename/validate entire projects
5. **Configuration required**: Set up channels.json before using

---

**Related Tools**:
- `configuration` - Manage channel definitions
- `youtube_manager` - Uses project names for organization
- Video production tools - Reference projects by names

**Pattern**: Part of AppyDave project organization system
