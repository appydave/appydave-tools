# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Development Setup
```bash
bin/setup           # Install dependencies and setup development environment
bin/console         # Interactive Ruby console for experimentation
```

### CLI Tools Usage

#### GPT Context Gatherer
Collect and organize project files for AI context:

```bash
# Basic usage - gather files with debug output and file output
gpt_context -i '**/*.rb' -e 'spec/**/*' -d -o context.txt

# Multiple formats and patterns
gpt_context -i 'lib/**/*.rb' -i 'bin/**/*.rb' -f tree,content -d

# Advanced web project filtering
gpt_context -i 'apps/**/*.ts' -i 'apps/**/*.tsx' -e '**/node_modules/**/*' -e '**/_generated/**/*' -d -f tree -o typescript.txt

# Tree view only for project structure
gpt_context -i '**/*' -e '**/node_modules/**/*' -e '.git/**/*' -f tree -d

# Line-limited content gathering  
gpt_context -i '**/*.rb' -l 20 -f content -d

# Multiple output targets
gpt_context -i 'docs/**/*' -f tree,content -o clipboard -o docs-context.txt
```

#### Other CLI Tools
```bash
# YouTube video management
bin/youtube_manager.rb get [options]
bin/youtube_manager.rb update [options]

# Subtitle processing
bin/subtitle_manager.rb clean [options]  
bin/subtitle_manager.rb join [options]

# AI prompt tools
bin/prompt_tools.rb completion [options]

# YouTube automation workflows  
bin/youtube_automation.rb [workflow-command]
```

### Testing & Quality
```bash
rake spec           # Run all RSpec tests
rake                # Default task: compile, spec (clobber compile spec)
guard               # Watch files and auto-run tests + rubocop on changes
bundle exec rspec -f doc  # Run tests with detailed documentation format
```

### Linting & Style
```bash
rubocop             # Run RubyGem style checks
bundle exec rubocop --format clang  # Run with clang format (as used in Guard)
```

### Build & Release
```bash
rake build          # Build the gem
rake publish        # Build and publish gem to RubyGems.org
rake clean          # Remove built *.gem files
gem build           # Build gemspec into .gem file
```

## Architecture Overview

This is a Ruby gem called `appydave-tools` that provides YouTube automation and content creation tools.

### Core Structure
- **CLI Tools**: Multiple executable scripts in `bin/` for different functionalities
- **Modular Design**: Organized into focused modules under `lib/appydave/tools/`
- **Configuration System**: Flexible config management with channel and project settings
- **Type System**: Custom type classes for data validation and transformation

### Key Components

#### CLI Actions (`lib/appydave/tools/cli_actions/`)
- Base action pattern for command-line operations
- YouTube video management (get, update)
- AI prompt completion workflows

#### Configuration (`lib/appydave/tools/configuration/`)
- Multi-channel YouTube setup support
- Project folder management (content, video, published, abandoned)
- OpenAI integration configuration
- Channel-specific settings (code, name, youtube_handle)

#### GPT Context (`lib/appydave/tools/gpt_context/`)
- File collection for AI context gathering
- Content filtering and organization
- Output handling for various formats

#### YouTube Management (`lib/appydave/tools/youtube_manager/`)
- YouTube API authorization and authentication
- Video metadata retrieval and updates
- Caption/subtitle management
- Detailed reporting capabilities

#### Subtitle Management (`lib/appydave/tools/subtitle_manager/`)
- SRT file cleaning and normalization
- Multi-part subtitle joining
- Timeline synchronization

### Type System (`lib/appydave/tools/types/`)
- `BaseModel`: Foundation for data models with validation
- `ArrayType` & `HashType`: Collection type wrappers
- `IndifferentAccessHash`: Symbol/string key flexibility

## Development Conventions

### Ruby Style
- All Ruby files must start with `# frozen_string_literal: true`
- Follow existing code patterns and naming conventions
- Use the Guard setup for continuous testing during development

### Testing
- RSpec for all testing
- No `require` statements needed in spec files (handled by spec_helper)
- VCR for HTTP request mocking (YouTube API calls)
- SimpleCov for coverage reporting

### File Organization
- CLI executables in `bin/`
- Core library code in `lib/appydave/tools/`
- Tests mirror lib structure in `spec/`
- Configuration examples and docs in respective `_doc.md` files

## Key Dependencies
- `google-api-client`: YouTube API integration
- `ruby-openai`: OpenAI GPT integration  
- `activemodel`: Data validation and modeling
- `clipboard`: System clipboard operations
- `dotenv`: Environment variable management

## Configuration Files
The gem uses JSON configuration for:
- Channel definitions (code, name, youtube_handle)
- Project folder paths (content, video, published, abandoned)
- OpenAI API settings
- YouTube automation workflows