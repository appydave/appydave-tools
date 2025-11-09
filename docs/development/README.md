# Development Documentation

This directory contains comprehensive guides for developing and extending appydave-tools.

## Quick Links

### Architecture Guides
- [CLI Architecture Patterns](./cli-architecture-patterns.md) - **START HERE** when creating new tools

## Quick Pattern Selection

When creating a new CLI tool, use this quick reference:

### Single Operation Tool → Pattern 1
**Use when:** Tool performs ONE operation with various options

**Examples:** `gpt_context`, `move_images`

**Key files:**
```
bin/tool_name.rb                    # CLI executable
lib/appydave/tools/tool_name/
  ├── options.rb                    # Options struct
  └── main_logic.rb                 # Business logic
```

**Read:** [Pattern 1 Details](./cli-architecture-patterns.md#pattern-1-single-command-tools)

---

### 2-5 Commands → Pattern 2
**Use when:** Tool has 2-5 related commands with simple routing

**Examples:** `subtitle_processor`, `configuration`

**Key files:**
```
bin/tool_name.rb                    # CLI with inline routing
lib/appydave/tools/tool_name/
  ├── command_one.rb                # Command implementation
  └── command_two.rb                # Command implementation
```

**Read:** [Pattern 2 Details](./cli-architecture-patterns.md#pattern-2-multi-command-with-inline-routing)

---

### 6+ Commands or Shared Patterns → Pattern 3
**Use when:** Tool has many commands OR commands share validation/execution patterns

**Examples:** `youtube_manager`

**Key files:**
```
bin/tool_name.rb                    # CLI with BaseAction routing
lib/appydave/tools/
  ├── cli_actions/
  │   ├── base_action.rb            # Shared base (already exists)
  │   ├── tool_cmd_one_action.rb    # Command as Action class
  │   └── tool_cmd_two_action.rb
  └── tool_name/
      └── service.rb                # Business logic
```

**Read:** [Pattern 3 Details](./cli-architecture-patterns.md#pattern-3-multi-command-with-baseaction)

---

## Common Tasks

### Adding a New Tool
1. Choose pattern using [Decision Tree](./cli-architecture-patterns.md#decision-tree)
2. Follow [Migration Guide](./cli-architecture-patterns.md#migration-guide)
3. Register in `appydave-tools.gemspec`
4. Document in `CLAUDE.md`

### Understanding Existing Code
- See [Directory Structure](./cli-architecture-patterns.md#directory-structure)
- Review [Best Practices](./cli-architecture-patterns.md#best-practices)

### Writing Tests
- Read [Testing Approach](./cli-architecture-patterns.md#testing-approach)
- No `require` statements in specs (handled by `spec_helper`)
- Test business logic, not CLI executables

---

## Philosophy

AppyDave Tools follows a **consolidated toolkit philosophy**:
- Multiple independent tools in one repository
- Each tool solves one specific problem
- Clear separation between CLI and business logic
- Business logic can be used programmatically (no CLI dependencies in `lib/`)

**Full Philosophy:** [Purpose and Philosophy](../purpose-and-philosophy.md)

---

**Last updated:** 2025-11-08
