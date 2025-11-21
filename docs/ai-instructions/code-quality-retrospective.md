# Code Quality Retrospective Analysis

## Objective
Analyze recent development history to identify architectural issues, code duplication, pattern inconsistencies, and other AI-generated code problems.

## Context
This is a Ruby gem project (`appydave-tools`) that provides CLI tools for YouTube content creation workflows. The codebase is maintained by humans with AI assistance. AI-generated code excels at writing individual implementations but often fails to:
- Look around the system to reuse existing patterns
- Follow established testing conventions
- Avoid duplicating functionality that already exists elsewhere
- Maintain architectural consistency across features

## What You Need From the User
1. **Time range:** How many days back to analyze (default: last 3-7 days)
2. **Focus areas:** Specific parts of codebase (e.g., "DAM/configuration changes" or "all of lib/")

## Analysis Process

### Phase 1: Discovery (Understand What Changed)
```bash
# Get git log with stats for the specified period
git log --since="3 days ago" --stat --oneline

# Identify most-changed files
git log --since="3 days ago" --name-only --pretty=format: | sort | uniq -c | sort -rn | head -20

# Get commit messages to understand intent
git log --since="3 days ago" --pretty=format:"%h - %s (%an, %ar)"
```

**Output:**
- List of changed files grouped by frequency
- Summary of feature areas touched
- Commit themes (new features, refactorings, bug fixes)

### Phase 2: Code Duplication Analysis

**What to search for:**
1. **Similar method names** across different files:
   - `brand.*path`, `resolve.*brand`, `get.*config`
   - `load.*`, `find.*`, `lookup.*`
   - `validate.*`, `check.*`, `ensure.*`

2. **Repeated logic patterns:**
   - Brand/project path resolution
   - Configuration loading/parsing
   - File path manipulation (joining, expanding, validating)
   - Error handling patterns
   - Nil checking patterns

3. **Copy-paste indicators:**
   - Similar code blocks with minor variable name changes
   - Identical error messages in multiple places
   - Repeated conditional logic
   - Similar method signatures with slight variations

**Tools to use:**
```bash
# Search for method definitions with similar names
grep -rn "def.*brand.*path" lib/

# Find repeated string patterns (error messages, etc.)
grep -rn "Configuration.*not found" lib/

# Look for similar class structures
find lib/ -name "*.rb" -exec grep -l "class.*Resolver" {} \;
```

**What to report:**
- File pairs with duplicated logic
- Line numbers of similar implementations
- Severity: Critical (exact duplication) vs Moderate (similar patterns)
- Suggested consolidation approach

### Phase 3: Pattern Consistency Analysis

#### Testing Patterns
Compare test files to identify inconsistencies:

1. **Spec structure:**
   - Are all specs using `describe`/`context`/`it` consistently?
   - Are test descriptions following the same format?
   - Are expectations using consistent matchers (`expect().to eq()` vs `expect().to be()`)?

2. **Test setup:**
   - Are mocks/stubs handled consistently?
   - Is test data creation following DRY principles?
   - Are `let` blocks used consistently vs instance variables?
   - Are `before` blocks structured similarly?

3. **Test coverage patterns:**
   - Are edge cases tested consistently (nil values, empty strings, missing files)?
   - Are error conditions tested?
   - Are success and failure paths both covered?

**Example patterns to check:**
```ruby
# Pattern A (preferred?)
let(:config) { described_class.new }
subject { config.load }

# Pattern B (alternative?)
before do
  @config = described_class.new
end

# Are both patterns used? Should we standardize?
```

#### Code Patterns
1. **Error handling:**
   - Consistent use of `raise` vs `return nil` vs `puts` for errors
   - Error message formatting
   - Use of custom exceptions vs standard library

2. **Logging:**
   - Consistent logging levels (debug, info, warn, error)
   - Consistent log message formatting
   - Protected debugging infrastructure (DO NOT flag as bloat)

3. **Class initialization:**
   - Consistent parameter handling
   - Consistent use of keyword arguments vs positional
   - Consistent defaults handling

4. **Method naming:**
   - `get_x` vs `fetch_x` vs `find_x` vs `x` (getter)
   - `set_x` vs `update_x` vs `x=` (setter)
   - Boolean methods ending in `?`
   - Dangerous methods ending in `!`

### Phase 4: Architectural Concerns

**What to flag:**

1. **Methods that are too large:**
   - \>20 lines of actual logic (not counting comments/whitespace)
   - Complex nested conditionals
   - Multiple concerns mixed together

2. **Classes with too many responsibilities:**
   - Classes with \>10 public methods
   - Classes that do multiple unrelated things
   - God objects that know too much about the system

3. **Tight coupling:**
   - Classes that directly instantiate other classes (should use dependency injection)
   - Hard-coded paths or configuration
   - Direct file system access instead of using abstractions

4. **Missing abstractions:**
   - Repeated conditional logic that should be polymorphic
   - Switch statements on type that should use inheritance/composition
   - Duplicated algorithms that should be extracted

5. **Inconsistent use of existing utilities:**
   - Code that reimplements functionality available in the standard library
   - Code that doesn't use existing helper methods in the project

**Example checks:**
```ruby
# Bad: Repeated conditional
if brand == "appydave"
  "v-appydave"
elsif brand == "voz"
  "v-voz"
# ... repeated in 3 different files

# Better: Use existing BrandResolver or similar
BrandResolver.resolve(brand)
```

### Phase 5: Protected Code Patterns ⚠️

**DO NOT flag these as problems:**
- Debug logging statements (even if verbose)
- Nil-check logging before operations
- Configuration loading trace logs
- Error context enrichment
- Defensive programming patterns (explicit nil checks, argument validation)

**Why:** These patterns exist for remote debugging and production issue diagnosis. They may look like "code bloat" but they're intentional safety nets.

## Report Format

```markdown
# Code Quality Analysis - [Date Range]

## Summary
- **Commits analyzed:** X commits
- **Files changed:** Y files in Z directories
- **Key areas:** [list main feature areas]
- **Analysis date:** [current date]

## Critical Issues 🔴
### 1. Code Duplication: [Short Description]
- **Found in:**
  - `lib/path/to/file1.rb:123-145`
  - `lib/path/to/file2.rb:456-478`
- **Description:** [What functionality is duplicated]
- **Impact:**
  - Maintenance burden (changes must be made in 2+ places)
  - Bug risk (fixes might miss one location)
  - Code bloat (X lines duplicated)
- **Recommendation:**
  - Extract to `lib/appydave/tools/utils/[name].rb`
  - Or add to existing `[ExistingClass]` if related
- **Estimated effort:** [Small/Medium/Large]

### 2. Architectural Issue: [Description]
[Similar format]

## Moderate Issues 🟡
### 1. Pattern Inconsistency: [Description]
- **Found in:** [file locations]
- **Pattern A:** [description with code example]
- **Pattern B:** [description with code example]
- **Recommendation:** Standardize on Pattern [A/B] because [reason]
- **Files to update:** [list]

### 2. Missing Test Coverage: [Description]
[Similar format]

## Minor Observations 🔵
### 1. [Observation]
- **Description:** [what was noticed]
- **Impact:** Low priority but worth noting
- **Recommendation:** [optional improvement]

## Positive Patterns ✅
### 1. [Good Pattern]
- **Found in:** [file locations]
- **Why it's good:** [explanation]
- **Recommend:** Continue using this approach

### 2. [Another Good Pattern]
[Similar format]

## Prioritized Action Items

### High Priority (Do First)
1. [ ] [Action item from Critical Issues]
2. [ ] [Action item from Critical Issues]

### Medium Priority (Do Soon)
1. [ ] [Action item from Moderate Issues]
2. [ ] [Action item from Moderate Issues]

### Low Priority (Future Improvement)
1. [ ] [Action item from Minor Observations]

## Statistics
- **Total duplicated code:** ~X lines across Y locations
- **Test coverage gaps:** Z files missing tests
- **Pattern inconsistencies:** N different patterns found for [thing]
- **Large methods:** M methods over 20 lines
- **Large classes:** K classes over 10 public methods
```

## Example Usage Instructions

### Example 1: After Feature Development
```
Analyze the last 3 days of git history. Focus on the DAM migration work and
configuration changes. Look for code duplication (especially around brand/path
resolution), inconsistent testing patterns, and places where we're not reusing
existing utilities. Give me a prioritized list of refactoring opportunities.
```

### Example 2: Specific Concern
```
Review commits from Nov 18-21. The main work was DAM CLI and configuration.
I'm particularly concerned we might have written brand resolution logic multiple
times in different places. Also check if the new specs are following the same
patterns as existing ones in spec/appydave/tools/
```

### Example 3: General Health Check
```
Analyze the last week of development. Look for the usual AI code problems:
duplication, pattern drift, missing abstractions. Focus on lib/appydave/tools/
and corresponding specs.
```

### Phase 6: Testing Anti-Patterns ⚠️

**CRITICAL: Don't Hide Bugs With Mocks**

The most dangerous testing anti-pattern is **using mocks to hide real bugs instead of fixing them**.

#### Red Flags in Tests:

1. **Over-mocking that masks bugs:**
   - Mocking away the exact behavior that contains the bug
   - Tests pass but production code still fails
   - "Fix" involves adding mocks instead of fixing logic

   **Example (BAD):**
   ```ruby
   # Bug: Regexp.last_match gets reset by .sub() call
   # "Fix": Mock the entire method instead of fixing the bug
   allow(resolver).to receive(:detect_from_pwd).and_return(['brand', 'project'])
   ```

   **Better approach:**
   ```ruby
   # Fix the actual bug: capture regex match BEFORE .sub() call
   project = Regexp.last_match(2)  # Capture BEFORE
   brand_key = brand_with_prefix.sub(/^v-/, '')  # Then modify
   ```

2. **Mixed mock/test data systems:**
   - Real file system + mocked configuration
   - Real objects + stubbed methods on same objects
   - Partial mocking that creates impossible states
   - Tests use different data sources than production

   **Example (BAD):**
   ```ruby
   # Mix of real filesystem and stubbed config
   let(:real_path) { File.expand_path('../fixtures', __dir__) }
   before do
     allow(config).to receive(:video_projects_root).and_return(real_path)
     allow(File).to receive(:exist?).and_return(true)  # But checking different paths!
   end
   ```

   **Better approach:**
   ```ruby
   # Consistent test data system: Either all real or all mocked
   let(:temp_dir) { Dir.mktmpdir }
   before do
     FileUtils.mkdir_p("#{temp_dir}/v-appydave/b65")
     config.video_projects_root = temp_dir
   end
   after { FileUtils.rm_rf(temp_dir) }
   ```

3. **Complex mock setups that don't reflect reality:**
   - Mocks that configure behavior that never happens in production
   - Chained stubs that create impossible scenarios
   - Mock expectations that don't match actual method signatures

4. **Tests that mock what they should be testing:**
   - Mocking the primary behavior under test
   - Stubbing return values instead of testing logic
   - Mocking away all collaborators (unit test tunnel vision)

#### When Mocking Is Appropriate:

- **External services** (API calls, network requests)
- **Slow operations** (database queries in unit tests)
- **Non-deterministic behavior** (timestamps, random values)
- **Expensive resources** (file I/O in focused unit tests)

#### When to Use Real Objects:

- **Testing integration** between components
- **Debugging failures** - Reproduce with real objects first
- **Configuration resolution** - Real config objects, real paths
- **Business logic** - Real domain objects, real calculations

#### How to Spot This Problem:

```bash
# Search for excessive mocking in specs
grep -rn "allow.*to receive" spec/ | wc -l
grep -rn "double\|instance_double" spec/ | wc -l

# Find specs with high mock-to-assertion ratios
# Red flag: 5+ mocks, 1-2 expectations
```

**Remember:** If you're adding mocks to make a test pass, stop and ask:
1. Is there a real bug I'm hiding?
2. Am I testing integration but using unit test mocks?
3. Would real objects expose the actual problem?

## Tips for Effective Analysis

1. **Start with git stats** - Let the data guide you to hot spots
2. **Read commit messages** - Understand intent before judging implementation
3. **Compare similar files** - Look at files changed in the same commit
4. **Check for existing utilities** - Before flagging duplication, verify there isn't already a helper
5. **Consider context** - Some "duplication" is intentional (tests, CLI commands)
6. **Be specific** - Don't just say "improve X", show exactly what and where
7. **Suggest solutions** - Include specific refactoring recommendations with file/method names
8. **Watch for mock overuse** - Tests with more mocks than assertions are a red flag

## Notes for AI Assistants

- **Be thorough but pragmatic** - Not every small similarity is worth flagging
- **Show your work** - Include the git commands and grep searches you ran
- **Provide evidence** - Show actual code snippets, not just descriptions
- **Prioritize impact** - Focus on issues that affect maintainability, not style preferences
- **Respect protected patterns** - Don't flag defensive logging/debugging code
- **Consider effort** - Note whether fixes are quick wins or major refactors
- **Be constructive** - Frame as learning opportunities, not criticism

---

**Last updated:** 2025-01-21
