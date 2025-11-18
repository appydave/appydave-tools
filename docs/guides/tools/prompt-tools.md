# Prompt Tools

⚠️ **DEPRECATED**: Uses legacy OpenAI Completion API (discontinued). See "Use Cases" for alternatives.

Generate text completions using OpenAI's API for prompts and content generation.

## What It Does (Deprecated)

**Prompt Tools** provides command-line access to OpenAI text generation:

- Send prompts to OpenAI API
- Get text completions
- Configure model and parameters
- Handle streaming responses
- Process batch prompts

⚠️ **Status**: Uses deprecated OpenAI Completion API (`davinci-003`). OpenAI discontinued this in January 2024.

## How to Use

### Basic Completion

```bash
prompt_tools completion -p "Write a haiku about programming"

prompt_tools completion -p "Explain recursion" -m "text-davinci-003"
```

### Configuration

Set OpenAI API key in config:

```bash
# Interactive setup
prompt_tools config

# Or set environment variable
export OPENAI_API_KEY="sk-..."
```

### Options

```bash
-p, --prompt TEXT        Text prompt to complete
-m, --model MODEL        Model name (default: text-davinci-003)
-t, --temperature NUM    Randomness 0-2 (default: 1.0)
-l, --max-tokens NUM     Maximum response length
-h, --help              Show help
```

## Why It's Deprecated

OpenAI discontinued the Completion API in January 2024. The tool still works with archived models but should not be used for new work.

### Migration Path

**Instead of Completion API:**

Use the **Chat Completion API** which is the current standard:

```bash
# Using gpt_context with aider (better approach)
gpt_context -i 'lib/**/*.rb' -p "Explain this code" -o clipboard

# Then paste into Claude, ChatGPT, or Copilot directly
# Or use aider CLI tool with gpt_context output
```

## Use Cases for AI Agents

### 1. Legacy Workflow Compatibility
```bash
# If you have existing scripts using this tool
# They will continue to work with archived models
# But consider migrating to Chat API
```
**AI discovers**: Legacy integration points. Can identify and update deprecated API usage.

### 2. Batch Prompt Processing (Outdated)
```bash
# Old approach: Use prompt_tools in loop
# Better approach: Use aider with gpt_context
# Or call Claude/ChatGPT API directly
```
**AI discovers**: Where deprecated tools are used. Can plan migration strategy.

### 3. Content Generation (Better Alternatives)
```bash
# Old: prompt_tools completion -p "Write blog post..."
# New: Use Claude API (claude-3-sonnet-20240229)
# Or: gpt_context + aider for code-aware generation
```
**AI discovers**: Content generation workflows. Can recommend better solutions.

### 4. Completion for Coding (Much Better Alternatives)
```bash
# Old: prompt_tools to suggest code completions
# Better: Use Copilot, Cursor, or Claude Code
# These understand context and code style
```
**AI discovers**: Code generation needs. Can recommend modern tools.

### 5. Migrating Legacy Prompts
```bash
# Convert old completion-style prompts to Chat format
# Old: "Write a story about..."
# New: ChatMessage with role="user", content="Write a story about..."
```
**AI discovers**: Legacy prompt format. Can adapt to modern APIs.

### 6. Archive Historical Data
```bash
# If you have saved outputs from this tool
# Convert to structured format for analysis
# Keep for historical reference if needed
```
**AI discovers**: What was generated with this tool. Can preserve and archive.

### 7. Identify Integration Points
```bash
# Find all scripts using prompt_tools
# Document current usage
# Plan migration to modern APIs
grep -r "prompt_tools" . --include="*.rb" --include="*.sh"
```
**AI discovers**: Tool dependencies, integration surface area. Can plan systematic migration.

### 8. API Cost Optimization
```bash
# Old models (davinci-003) are expensive
# New models (gpt-3.5-turbo, gpt-4) are cheaper and better
# Migrate to save on API costs
```
**AI discovers**: Cost structure. Can calculate migration savings.

### 9. Functionality Assessment
```bash
# Determine what this tool was used for
# Evaluate modern alternatives:
#   - Code: GitHub Copilot, Claude Code, Cursor
#   - Writing: ChatGPT, Claude, Gemini
#   - Data: Claude API, GPT-4 API, specialized models
```
**AI discovers**: Use cases. Can recommend best modern solution for each.

### 10. Retirement Planning
```bash
# Schedule deprecation of prompt_tools
# Replace with modern API calls
# Remove from codebase once all usages migrated
```
**AI discovers**: Deprecation timeline. Can plan orderly sunset of legacy tool.

## Modern Alternatives

| Use Case | Modern Solution | Notes |
|----------|-----------------|-------|
| Interactive coding | Claude Code, Copilot, Cursor | IDE integration recommended |
| Batch code analysis | gpt_context + Claude API | Better context awareness |
| Writing generation | ChatGPT API, Claude API | Chat format is more flexible |
| Content creation | Dedicated content tools | Like Copy.ai, WriterAccess |
| Completion in code | Model-specific APIs | Call modern APIs directly |

## Troubleshooting (Legacy)

| Issue | Solution |
|-------|----------|
| "Model not found" | Archived models are no longer available; migrate to Chat API |
| "API key error" | Check `~/.config/appydave` for OPENAI_API_KEY |
| "Rate limited" | Reduce batch size or wait; consider modern API quotas |

## Migration Guide

### Step 1: Identify Usage
```bash
# Find all prompt_tools invocations
grep -r "prompt_tools" . --include="*.rb"
```

### Step 2: Understand Intent
For each usage:
- What is it trying to do?
- What would be the best modern tool?

### Step 3: Implement Alternative
- For code: Use Claude Code, Copilot
- For writing: Use ChatGPT API or Claude API
- For batch: Use modern API with proper batching

### Step 4: Test & Validate
- Verify new solution works
- Compare output quality
- Measure cost difference

### Step 5: Remove Legacy
- Delete `prompt_tools` invocations
- Update documentation
- Remove from dependencies if no longer needed

---

**Status**: ⚠️ Deprecated - Migrate to modern APIs
**Recommendation**: Replace with Claude API, OpenAI Chat API, or IDE-integrated tools
**Timeline**: Plan migration within 6 months
**Related Tools**:
- `gpt_context` - For context gathering (works with modern APIs)
- `youtube_automation` - Uses newer API patterns

**OpenAI Migration**: [Completion → Chat Completions](https://platform.openai.com/docs/guides/gpt/completions-api)
