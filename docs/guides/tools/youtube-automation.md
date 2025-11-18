# YouTube Automation

Internal orchestration tool for coordinating YouTube workflows and content generation tasks.

## What It Does

**YouTube Automation** is an internal tool that coordinates complex YouTube workflows:

- Orchestrates multi-step video publishing processes
- Coordinates with GPT agents for content generation
- Manages workflow state and dependencies
- Integrates with other tools (YouTube Manager, Subtitle Processor, etc.)
- Supports parameterized workflow definitions
- Handles error recovery and retries

## How to Use

### Workflow Structure

This tool uses a configuration-based workflow system:

```bash
# List available workflows
youtube_automation workflows

# Execute a workflow
youtube_automation execute workflow_name [options]

# Check workflow status
youtube_automation status workflow_name
```

### Configuration Location

Workflows are defined in:
- `~/.config/appydave/youtube_automation.json` - Workflow definitions
- `~/.config/appydave/channels.json` - Channel configuration

## Workflow Concepts

Each workflow consists of:

1. **Trigger**: What starts the workflow (manual, scheduled, event)
2. **Steps**: Sequential or parallel operations (fetch, transform, publish)
3. **Integrations**: Which tools are involved (YouTube Manager, Subtitle Processor, etc.)
4. **Handlers**: Error handling and retry logic
5. **State**: What data flows between steps

## Use Cases for AI Agents

### 1. Orchestrated Video Publishing
```bash
# AI-managed workflow:
# 1. Fetch video details (youtube_manager get)
# 2. Generate optimized description (GPT agent)
# 3. Extract and clean subtitles (subtitle_processor clean)
# 4. Upload updated metadata (youtube_manager update)
youtube_automation execute publish_with_optimization -v dQw4w9WgXcQ
```
**AI discovers**: Complete publishing workflow, what each step does, dependencies. Can orchestrate complex multi-step processes.

### 2. Batch Content Optimization
```bash
# Process multiple videos:
# For each video:
#   1. Get current metadata
#   2. Analyze with AI for improvements
#   3. Generate optimized version
#   4. Stage changes for review
youtube_automation execute batch_optimize -c "channel-id"
```
**AI discovers**: How to handle batch operations at scale. Can orchestrate 50+ videos with proper state management.

### 3. Content Generation Pipeline
```bash
# Workflow: Script → Video → Captions → Metadata → Publish
# AI coordinates between:
#   - LLM for script generation
#   - Video tools for processing
#   - Subtitle processor for captions
#   - YouTube manager for publishing
youtube_automation execute full_content_pipeline -s "script-file.md"
```
**AI discovers**: End-to-end content workflow dependencies. Can manage complex multi-tool pipelines.

### 4. Error Recovery & Resumption
```bash
# Workflow with fault tolerance
# If step 2 fails:
#   - Log error with context
#   - Offer resume option
#   - Continue from where it failed
youtube_automation resume job_id
```
**AI discovers**: How to handle failures gracefully in complex workflows. Can implement robust error recovery.

### 5. Parallel Workflow Processing
```bash
# Process multiple channels simultaneously
# Workflow handles concurrent operations:
#   - Video 1: fetch, optimize, update
#   - Video 2: fetch, optimize, update
#   - Video 3: fetch, optimize, update
youtube_automation execute parallel_optimization -c "multiple-channels"
```
**AI discovers**: Concurrency patterns, state isolation. Can coordinate parallel tasks safely.

### 6. Conditional Workflow Branching
```bash
# Workflow with conditional logic:
# If video has < 1000 views:
#   - Regenerate thumbnail
#   - Reoptimize description
#   - Add to promotion list
# Else:
#   - Mark as successful
#   - Archive metadata
youtube_automation execute conditional_optimization -v "video-id"
```
**AI discovers**: How to implement conditional workflows. Can build intelligent decision logic into processes.

### 7. Workflow State Inspection
```bash
# Debug workflow execution
# See what data is flowing between steps
# Identify bottlenecks or failures
youtube_automation debug job_id --verbose
```
**AI discovers**: Workflow state, what's happening at each step. Can diagnose issues in complex workflows.

### 8. Integration Testing
```bash
# Test workflow with dry-run mode
# Execute steps without making changes
youtube_automation execute workflow_name --dry-run
```
**AI discovers**: What workflow would do without side effects. Can safely test complex workflows.

### 9. Workflow Composition
```bash
# Combine multiple workflows
# Master workflow orchestrates sub-workflows:
#   - run: fetch_workflow
#   - run: process_workflow
#   - run: publish_workflow
youtube_automation execute master_workflow
```
**AI discovers**: How to compose complex workflows from simpler components. Can build modular workflow systems.

### 10. Historical Analysis & Metrics
```bash
# Analyze workflow execution history
# What videos took longest to process?
# Where do failures happen most?
# Which steps have highest latency?
youtube_automation analyze metrics --period "30d"
```
**AI discovers**: Workflow performance patterns. Can identify optimization opportunities based on historical data.

## Workflow Definition Example

```json
{
  "workflows": {
    "publish_with_optimization": {
      "trigger": "manual",
      "steps": [
        {
          "name": "fetch",
          "tool": "youtube_manager",
          "command": "get",
          "params": {"video_id": "${VIDEO_ID}"}
        },
        {
          "name": "optimize",
          "tool": "gpt_agent",
          "command": "optimize_metadata",
          "params": {"metadata": "${fetch.output}"}
        },
        {
          "name": "update",
          "tool": "youtube_manager",
          "command": "update",
          "params": {
            "video_id": "${VIDEO_ID}",
            "title": "${optimize.title}",
            "description": "${optimize.description}"
          }
        }
      ],
      "on_error": "retry_step"
    }
  }
}
```

## Command Reference

### Execute Workflow
```bash
youtube_automation execute WORKFLOW_NAME [options]
```

| Option | Short | Long | Description |
|--------|-------|------|-------------|
| Dry Run | `-d` | `--dry-run` | Simulate without making changes |
| Verbose | `-v` | `--verbose` | Detailed output |
| Config | `-c` | `--config FILE` | Custom config file |

### Status & Monitoring
```bash
youtube_automation status [job_id]
youtube_automation resume [job_id]
youtube_automation cancel [job_id]
youtube_automation logs [job_id]
```

## Configuration

Edit workflow definitions:

```bash
# Edit in default editor
youtube_automation config edit workflows

# View current config
youtube_automation config show

# Validate config
youtube_automation config validate
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Workflow not found" | Check `~/.config/appydave/youtube_automation.json` |
| "Step failed, stopped" | Use `--verbose` to see error, then `resume` |
| "Configuration invalid" | Run `youtube_automation config validate` |
| "API rate limited" | Workflows implement backoff; check quotas in Google Cloud Console |

## Tips & Tricks

1. **Use dry-run first**: Test workflows without side effects
2. **Check logs**: See detailed execution history with `youtube_automation logs job_id`
3. **Parallel is safer**: Use parallel steps carefully; sequential is easier to debug
4. **Error handling**: All workflows should have `on_error` strategy defined
5. **State visibility**: Use `--verbose` to see data flowing between steps

---

**Related Tools**:
- `youtube_manager` - For individual video operations
- `gpt_context` - For gathering context for workflow decisions
- `subtitle_processor` - For caption handling in workflows
- `configuration` - For workflow and channel setup

**Architecture**: Internal tool designed for orchestration. Not intended for direct end-user use in most cases.
