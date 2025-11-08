# Test Coverage Quick Wins

**Current Coverage:** 85.84% (1655 / 1928 lines)

**Goal:** Increase to 90%+ with minimal effort

---

## Missing Test Files (Quick Wins)

### 🎯 Priority 1: CLI Actions (0/4 specs) - HIGH IMPACT

**Files without specs:**
1. `lib/appydave/tools/cli_actions/base_action.rb` ⭐ **CRITICAL**
2. `lib/appydave/tools/cli_actions/get_video_action.rb`
3. `lib/appydave/tools/cli_actions/prompt_completion_action.rb`
4. `lib/appydave/tools/cli_actions/update_video_action.rb`

**Why high impact:**
- BaseAction is a template class used by all actions
- Testing BaseAction tests the pattern used across the codebase
- CLI actions are user-facing entry points

**Estimated effort:** 2-3 hours for all 4

**RSpec convention adherence:**
- ✅ Template Method Pattern - Already established in codebase
- ✅ Use `described_class` for class under test
- ✅ Group by method with `describe '#method_name'`
- ✅ Use `context` for different scenarios
- ✅ No `require` statements (handled by spec_helper)

**Example test structure for BaseAction:**

```ruby
# spec/appydave/tools/cli_actions/base_action_spec.rb
# frozen_string_literal: true

RSpec.describe Appydave::Tools::CliActions::BaseAction do
  # Create concrete test class since BaseAction is abstract
  let(:test_action_class) do
    Class.new(described_class) do
      protected

      def define_options(opts, options)
        opts.on('-t', '--test VALUE', 'Test option') { |v| options[:test] = v }
      end

      def validate_options(options)
        raise ArgumentError, 'Test option required' unless options[:test]
      end

      def execute(options)
        "Executed with: #{options[:test]}"
      end
    end
  end

  let(:test_action) { test_action_class.new }

  describe '#action' do
    context 'with valid options' do
      it 'executes successfully' do
        expect { test_action.action(['-t', 'value']) }.not_to raise_error
      end
    end

    context 'with missing required options' do
      it 'raises ArgumentError' do
        expect { test_action.action([]) }.to raise_error(ArgumentError, 'Test option required')
      end
    end

    context 'with help flag' do
      it 'displays help and exits' do
        expect { test_action.action(['-h']) }.to raise_error(SystemExit)
      end
    end
  end

  describe 'template method pattern' do
    it 'calls define_options during initialization' do
      # Test that subclass hook is called
    end

    it 'calls validate_options before execute' do
      # Test validation happens
    end

    it 'calls execute with parsed options' do
      # Test execution happens
    end
  end
end
```

---

### 🎯 Priority 2: GPT Context Options (1 file) - MEDIUM IMPACT

**File without spec:**
- `lib/appydave/tools/gpt_context/options.rb`

**Why medium impact:**
- Already have specs for FileCollector and OutputHandler
- Options class is smaller, focused
- Completes the gpt_context module coverage

**Estimated effort:** 30-45 minutes

**Test structure:**

```ruby
# spec/appydave/tools/gpt_context/options_spec.rb
# frozen_string_literal: true

RSpec.describe Appydave::Tools::GptContext::Options do
  describe '#initialize' do
    context 'with default options' do
      it 'sets default values' do
        options = described_class.new([])
        expect(options.include_patterns).to be_empty
        expect(options.exclude_patterns).to be_empty
      end
    end

    context 'with include patterns' do
      it 'parses multiple -i flags' do
        options = described_class.new(['-i', '*.rb', '-i', '*.md'])
        expect(options.include_patterns).to eq(['*.rb', '*.md'])
      end
    end

    context 'with exclude patterns' do
      it 'parses -e flags' do
        options = described_class.new(['-e', 'spec/**/*'])
        expect(options.exclude_patterns).to eq(['spec/**/*'])
      end
    end

    context 'with format option' do
      it 'parses format flag' do
        options = described_class.new(['-f', 'tree'])
        expect(options.format).to eq('tree')
      end
    end

    context 'with output file' do
      it 'parses output flag' do
        options = described_class.new(['-o', 'output.txt'])
        expect(options.output_file).to eq('output.txt')
      end
    end

    context 'with line limit' do
      it 'parses line limit flag' do
        options = described_class.new(['-l', '100'])
        expect(options.line_limit).to eq(100)
      end
    end
  end

  describe '#valid?' do
    context 'with no include patterns' do
      it 'returns false' do
        options = described_class.new([])
        expect(options.valid?).to be false
      end
    end

    context 'with include patterns' do
      it 'returns true' do
        options = described_class.new(['-i', '*.rb'])
        expect(options.valid?).to be true
      end
    end
  end
end
```

---

### 🎯 Priority 3: Root-level Files (2 files) - LOW IMPACT

**Files without specs:**
- `lib/appydave/tools/debuggable.rb` - Likely a simple module
- `lib/appydave/tools/version.rb` - Auto-generated version file

**Why low impact:**
- Version file is auto-generated (should not be tested)
- Debuggable is likely a simple concern/module

**Estimated effort:** 15-30 minutes (only test debuggable)

**Skip version.rb** - It's auto-generated by semantic-release

---

## RSpec Conventions to Follow

Based on existing specs in the codebase:

### ✅ DO:
1. **Use `described_class`** instead of explicit class name
2. **Group by method** with `describe '#method_name'` (instance) or `describe '.method_name'` (class)
3. **Use `context` for scenarios** - "with valid input", "when error occurs"
4. **Use `let` for test data** - lazy evaluation, cleaner setup
5. **Freeze string literals** - `# frozen_string_literal: true` at top
6. **No require statements** - spec_helper handles all requires
7. **Use RSpec matchers** - `expect(...).to eq(...)`, not `should`
8. **Test behavior, not implementation** - Focus on public API

### ❌ DON'T:
1. **Don't use `should` syntax** - Use `expect` instead
2. **Don't manually require files** - spec_helper does this
3. **Don't test private methods directly** - Test through public API
4. **Don't duplicate setup** - Use `let`, `let!`, `before` blocks
5. **Don't write brittle tests** - Avoid testing internal state unless necessary

---

## Example from Existing Codebase

**Good example:** `spec/appydave/tools/subtitle_processor/clean_spec.rb`

```ruby
RSpec.describe Appydave::Tools::SubtitleProcessor::Clean do
  let(:file_path) { File.expand_path('../../../fixtures/subtitle_processor/test.srt', __dir__) }
  let(:simple_content) do
    <<~SRT
      1
      00:00:00,060 --> 00:00:01,760
      <u>The</u> quick
    SRT
  end

  describe '#initialize' do
    it 'initializes with file_path' do
      expect { described_class.new(file_path: file_path) }.not_to raise_error
    end

    it 'raises error when both file_path and srt_content are provided' do
      expect { described_class.new(file_path: file_path, srt_content: simple_content) }
        .to raise_error(ArgumentError, 'You cannot provide both a file path and an SRT content stream.')
    end
  end

  describe '#clean' do
    context 'when initialized with file_path' do
      let(:cleaner) { described_class.new(file_path: file_path) }

      it 'normalizes the subtitles correctly' do
        cleaned_content = cleaner.clean
        expect(cleaned_content.strip.encode('UTF-8')).to eq(expected_content.strip.encode('UTF-8'))
      end
    end
  end
end
```

**Why this is good:**
- ✅ Uses `described_class`
- ✅ Groups by method
- ✅ Uses `context` for scenarios
- ✅ Uses `let` for test data
- ✅ Frozen string literal
- ✅ No requires
- ✅ Tests behavior (clean works) not implementation

---

## Implementation Plan

### Step 1: BaseAction (Highest Priority)
```bash
# Create spec file
touch spec/appydave/tools/cli_actions/base_action_spec.rb

# Run tests for just this file
bundle exec rspec spec/appydave/tools/cli_actions/base_action_spec.rb
```

### Step 2: CLI Action Subclasses
```bash
# Create spec files
touch spec/appydave/tools/cli_actions/get_video_action_spec.rb
touch spec/appydave/tools/cli_actions/update_video_action_spec.rb
touch spec/appydave/tools/cli_actions/prompt_completion_action_spec.rb

# Run tests
bundle exec rspec spec/appydave/tools/cli_actions/
```

### Step 3: GPT Context Options
```bash
# Create spec file
touch spec/appydave/tools/gpt_context/options_spec.rb

# Run tests
bundle exec rspec spec/appydave/tools/gpt_context/
```

### Step 4: Verify Coverage
```bash
# Run full suite
bundle exec rspec

# Check new coverage (should be 90%+)
cat coverage/.last_run.json
```

---

## Estimated Impact

**Current:** 85.84% (1655 / 1928 lines)

**After Priority 1 (CLI Actions):**
- Estimated lines in cli_actions: ~150 lines
- Assuming 80% test coverage of those lines: +120 lines
- New total: ~1775 / 1928 = **92.1%**

**After Priority 2 (Options):**
- Estimated lines in options.rb: ~50 lines
- Assuming 80% coverage: +40 lines
- New total: ~1815 / 1928 = **94.1%**

**Target: 94% coverage with ~4-5 hours of effort**

---

## Notes

- **BaseAction is abstract** - Test via concrete subclass or test doubles
- **Integration vs unit** - CLI actions may need integration-style tests (harder to unit test)
- **VCR cassettes** - YouTube actions may need VCR for API mocking (already in use)
- **Don't test version.rb** - It's auto-generated
- **Focus on public API** - Don't test private methods directly

---

**Recommendation:** Start with BaseAction spec - it will establish the pattern for all other CLI action specs and provide the biggest coverage boost.
