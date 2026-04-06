# Spec: Fix `jump add` (and `update`/`remove`) Output Display

**Status**: Ready for implementation
**Filed by**: Claude Code session (brains repo), 2026-04-06
**Root cause session**: User ran `jump add --key awb --path ... --type app`, got "No locations found." — the add succeeded but the formatter showed a misleading empty-results message.

---

## Problem

`jump add`, `jump update`, and `jump remove` all return a **mutation result** shape:

```ruby
{ success: true, message: "Location 'awb' added successfully", location: location.to_h }
{ success: true, message: "Location 'awb' removed successfully" }
```

`TableFormatter#format` dispatches on result shape in this order:

```ruby
def format
  return format_error   unless success?
  return format_info    if info_result?
  return format_summary if summary_result?
  return format_groups  unless groups.empty?
  return format_empty   if results.empty?   # ← mutation results land here
  ...
  format_results
end
```

`results` reads `data[:results] || []`. Mutation results have no `:results` key, so `results` is always `[]`, so `format_empty` fires and prints **"No locations found."**

The operation worked. The data was saved. The message was misleading noise.

---

## Fix Required

### `lib/appydave/tools/jump/formatters/table_formatter.rb`

Add a `mutation_result?` guard **before** the `format_empty` check, and a corresponding `format_mutation` method.

#### Change 1 — dispatch order

```ruby
def format
  return format_error    unless success?
  return format_info     if info_result?
  return format_summary  if summary_result?
  return format_groups   unless groups.empty?
  return format_mutation if mutation_result?   # ← insert here
  return format_empty    if results.empty?
  return format_definition_report if definition_report?
  return format_count_report      if count_report?
  return format_category_report   if category_report?

  format_results
end
```

#### Change 2 — new private methods

```ruby
def mutation_result?
  data.key?(:message) && (data.key?(:location) || data[:message].to_s.match?(/removed|updated|added/i))
end

def format_mutation
  lines = [colorize(data[:message], :green)]
  lines << colorize(data[:warning], :yellow) if data[:warning]
  lines.join("\n")
end
```

**No other files need changing.** `Commands::Add`, `Commands::Update`, and `Commands::Remove` already return the right shape.

---

## Unit Tests Required

Add these to `spec/appydave/tools/jump/formatters/table_formatter_spec.rb`.

Insert as a new context block after the existing `'when formatting empty results'` context (around line 31):

```ruby
context 'when formatting a mutation result (add/update/remove)' do
  context 'with a successful add' do
    let(:data) do
      {
        success: true,
        message: "Location 'awb' added successfully",
        location: {
          key: 'awb',
          path: '/Users/davidcruwys/dev/ad/apps/awb',
          jump: 'jawb',
          type: 'app'
        }
      }
    end

    it 'displays the success message' do
      output = formatter.format
      expect(output).to include("Location 'awb' added successfully")
    end

    it 'does not display "No locations found"' do
      output = formatter.format
      expect(output).not_to include('No locations found')
    end

    it 'does not display a table header' do
      output = formatter.format
      expect(output).not_to include('KEY')
    end
  end

  context 'with a successful add and a path warning' do
    let(:data) do
      {
        success: true,
        message: "Location 'awb' added successfully",
        warning: "Warning: Path '/Users/davidcruwys/dev/ad/apps/awb' does not exist",
        location: {
          key: 'awb',
          path: '/Users/davidcruwys/dev/ad/apps/awb'
        }
      }
    end

    it 'displays the success message' do
      output = formatter.format
      expect(output).to include("Location 'awb' added successfully")
    end

    it 'displays the path warning' do
      output = formatter.format
      expect(output).to include('does not exist')
    end
  end

  context 'with a successful update' do
    let(:data) do
      {
        success: true,
        message: "Location 'awb' updated successfully",
        location: { key: 'awb', path: '/Users/davidcruwys/dev/ad/apps/awb' }
      }
    end

    it 'displays the update success message' do
      output = formatter.format
      expect(output).to include("Location 'awb' updated successfully")
    end

    it 'does not display "No locations found"' do
      output = formatter.format
      expect(output).not_to include('No locations found')
    end
  end

  context 'with a successful remove' do
    let(:data) do
      {
        success: true,
        message: "Location 'awb' removed successfully"
        # remove has no :location key
      }
    end

    it 'displays the remove success message' do
      output = formatter.format
      expect(output).to include("Location 'awb' removed successfully")
    end

    it 'does not display "No locations found"' do
      output = formatter.format
      expect(output).not_to include('No locations found')
    end
  end
end
```

---

## CLI Integration Test

The existing `cli_spec.rb` tests auto-regeneration but never asserts what the user actually *sees*. Add these to
`spec/appydave/tools/jump/cli_spec.rb` inside the existing `'when adding a location'` context (around line 43):

```ruby
it 'shows success message after add' do
  cli.run(['add', '--key', 'new-project', '--path', '~/dev/new-path'])

  expect(output.string).to include("Location 'new-project' added successfully")
end

it 'does not show "No locations found" after add' do
  cli.run(['add', '--key', 'new-project', '--path', '~/dev/new-path'])

  expect(output.string).not_to include('No locations found')
end

it 'shows warning when path does not exist' do
  no_path_validator = TestPathValidator.new(valid_paths: [])
  bad_cli = described_class.new(config: config, path_validator: no_path_validator, output: output)
  bad_cli.run(['add', '--key', 'ghost', '--path', '~/dev/ghost'])

  expect(output.string).to include('does not exist')
  expect(output.string).to include("Location 'ghost' added successfully")
end
```

---

## After This Is Done — Skill Update

Once the fix is merged and released, the jump skill at
`~/.claude/skills/jump/SKILL.md` needs its **"Modifying Locations"** section rewritten.

**Current (wrong):**
```
"Add a new jump alias for my-project"
- Action:
  1. Add new entry to ~/.config/appydave/locations.json
  2. Run /Users/.../jump.rb generate aliases > ~/.oh-my-zsh/custom/aliases-jump.zsh
```

**Correct (after fix):**
```
"Add a new jump alias for my-project"
- Action:
  jump add --key my-project --path ~/dev/my-project [--type X] [--brand X]
  # aliases auto-regenerate if aliases-output-path is set in settings.json
  # use --no-generate to skip
```

The skill should use the tool. Direct JSON editing is a workaround, not a workflow.

---

## Summary of Files to Touch

| File | Change |
|------|--------|
| `lib/.../formatters/table_formatter.rb` | Add `mutation_result?` + `format_mutation`, insert guard in `format` dispatch |
| `spec/.../formatters/table_formatter_spec.rb` | Add 4 new contexts covering add/update/remove/warning |
| `spec/.../jump/cli_spec.rb` | Add 3 assertions inside existing `'when adding a location'` context |
| `~/.claude/skills/jump/SKILL.md` | Update after gem is released (done in brains repo, not here) |
