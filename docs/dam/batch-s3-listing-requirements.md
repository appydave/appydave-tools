# Batch S3 Listing - Requirements Document

**Author:** Claude Code
**Date:** 2025-01-24
**Status:** Draft
**Related Issue:** Performance bottleneck in `dam list <brand> --s3`

---

## Executive Summary

**Problem:** The `dam list <brand> --s3` command makes N individual AWS S3 API calls (one per project), causing severe performance degradation for brands with many projects (3-5 seconds for 13 projects).

**Proposed Solution:** Implement batch S3 listing that makes a single AWS API call for all projects in a brand, then distributes results locally.

**Expected Improvement:** 13 AWS API calls → 1 call (13x reduction, ~3-5s → ~300-500ms)

---

## 1. Problem Statement

### Current Behavior

**Command:** `dam list appydave --s3`

**What happens:**
1. Retrieves list of 13 projects locally
2. For EACH project (loop):
   - Creates new `S3Operations` instance
   - Calls `calculate_sync_status()`
   - Which calls `list_s3_files()` (AWS API call)
   - Returns sync status (↑ upload, ↓ download, ✓ synced, none)

**Result:** 13 sequential AWS API calls, taking 3-5 seconds total

**User Impact:**
- Slow response time for common operation
- Poor UX for daily workflows
- Cost implications (AWS S3 API charges per request)

### Root Cause

**N+1 Query Pattern:**
```ruby
# In project_listing.rb:172
project_data = projects.map do |project|
  collect_project_data(..., s3: true)  # Called for each project
    → calculate_project_s3_sync_status()  # Line 566
      → S3Operations.new().calculate_sync_status()  # Line 493
        → list_s3_files()  # Line 502 - AWS API CALL
end
```

Each project makes an independent S3 list_objects_v2 call with prefix:
- `staging/appydave/b60/`
- `staging/appydave/b61/`
- `staging/appydave/b62/`
- ... (13 times)

---

## 2. Current Architecture

### Class Responsibilities

**`ProjectListing` (presenter layer):**
- Formats and displays brand/project lists
- Calls `S3Operations` for each project individually

**`S3Operations` (business logic):**
- Handles S3 operations for a SINGLE project
- Initialized with `brand` + `project_id`
- Method: `list_s3_files()` lists files for that specific project

### Current Flow

```
User: dam list appydave --s3
   ↓
ProjectListing.list_brand_projects(brand_arg, s3: true)
   ↓
[Loop 13 times]
   ↓
   collect_project_data(project, s3: true)
      ↓
      calculate_project_s3_sync_status(brand, project)
         ↓
         S3Operations.new(brand, project)
            ↓
            list_s3_files()  ← AWS API CALL (prefix: staging/appydave/b60/)
            ↓
         calculate_sync_status() → "✓ synced"
   ↓
Display table with S3 column
```

**Total AWS calls:** 13 (one per project)

---

## 3. Proposed Solution

### Batch Listing Strategy

**Core Idea:** Make ONE AWS call to list ALL files for a brand, then distribute results to projects locally.

### New Flow

```
User: dam list appydave --s3
   ↓
ProjectListing.list_brand_projects(brand_arg, s3: true)
   ↓
S3Operations.list_all_brand_files(brand)  ← SINGLE AWS API CALL
   ↓                                          (prefix: staging/appydave/)
Returns: {
  'b60' => [file1, file2, ...],
  'b61' => [file3, file4, ...],
  ...
}
   ↓
[Loop 13 times]
   ↓
   collect_project_data(project, s3: true, s3_cache: s3_files_map)
      ↓
      calculate_project_s3_sync_status(brand, project, s3_files: s3_files_map[project])
         ↓
         calculate_sync_status(s3_files)  ← Use cached data (no AWS call)
   ↓
Display table with S3 column
```

**Total AWS calls:** 1 (batch fetch for all projects)

---

## 4. Technical Design

### 4.1 New Class Method

**Location:** `lib/appydave/tools/dam/s3_operations.rb`

```ruby
# Class method: List all S3 files for a brand, grouped by project
# @param brand [String] Brand key (e.g., 'appydave')
# @param brand_info [BrandInfo] Optional pre-loaded brand info (DI)
# @return [Hash<String, Array<Hash>>] Map of project_id => array of S3 file hashes
#
# Example return value:
# {
#   'b60-automate-image-generation' => [
#     { 'Key' => 'staging/appydave/b60-automate-image-generation/video.mp4',
#       'Size' => 12345, 'ETag' => '"abc123"', 'LastModified' => Time }
#   ],
#   'b61-kdd-bmad' => [...]
# }
def self.list_all_brand_files(brand, brand_info: nil)
  # Load brand info
  brand_info ||= load_brand_info(brand)

  # Create S3 client
  s3_client = create_s3_client(brand_info)

  # Fetch ALL objects for brand with single list_objects_v2 call
  prefix = "#{brand_info.aws.s3_prefix}"  # e.g., "staging/appydave/"

  all_files = []
  continuation_token = nil

  loop do
    response = s3_client.list_objects_v2(
      bucket: brand_info.aws.s3_bucket,
      prefix: prefix,
      continuation_token: continuation_token
    )

    all_files.concat(response.contents) if response.contents

    break unless response.is_truncated
    continuation_token = response.next_continuation_token
  end

  # Group files by project ID
  group_files_by_project(all_files, prefix)
end

private

# Extract project ID from S3 key and group files
# @param files [Array<Aws::S3::Types::Object>] S3 objects
# @param prefix [String] S3 prefix (e.g., "staging/appydave/")
# @return [Hash<String, Array<Hash>>] Map of project_id => files
def self.group_files_by_project(files, prefix)
  grouped = Hash.new { |h, k| h[k] = [] }

  files.each do |obj|
    # Extract project ID from key
    # Example: "staging/appydave/b60-project-name/video.mp4" → "b60-project-name"
    relative_path = obj.key.sub(prefix, '')
    project_id = relative_path.split('/').first

    next if project_id.nil? || project_id.empty?

    # Store file info in project's array
    grouped[project_id] << {
      'Key' => obj.key,
      'Size' => obj.size,
      'ETag' => obj.etag,
      'LastModified' => obj.last_modified
    }
  end

  grouped
end
```

### 4.2 Updated Instance Method

**Modify:** `calculate_sync_status` to accept optional cached S3 files

```ruby
# Calculate 3-state S3 sync status
# @param s3_files [Array<Hash>, nil] Optional pre-fetched S3 files (for batch mode)
# @return [String] One of: '↑ upload', '↓ download', '✓ synced', 'none'
def calculate_sync_status(s3_files: nil)
  project_dir = project_directory_path
  staging_dir = File.join(project_dir, 's3-staging')

  # No s3-staging directory means no S3 intent
  return 'none' unless Dir.exist?(staging_dir)

  # Get S3 files (use cached if provided, otherwise fetch)
  begin
    s3_files_list = s3_files || list_s3_files
  rescue StandardError
    # S3 not configured or not accessible
    return 'none'
  end

  local_files = list_local_files(staging_dir)

  # No files anywhere
  return 'none' if s3_files_list.empty? && local_files.empty?

  # ... (rest of logic unchanged)
end
```

### 4.3 Updated ProjectListing Integration

**Modify:** `list_brand_projects` to use batch listing

```ruby
def self.list_brand_projects(brand_arg, detailed: false, s3: false)
  # ... (existing code)

  # Batch-fetch S3 files if requested (SINGLE AWS CALL)
  s3_files_cache = if s3
                     begin
                       S3Operations.list_all_brand_files(brand_arg, brand_info: brand_info)
                     rescue StandardError => e
                       # S3 not configured or error - log and continue without S3
                       puts "⚠️  S3 listing failed: #{e.message}" if ENV['DAM_DEBUG']
                       {}
                     end
                   else
                     {}
                   end

  # Gather project data (use cached S3 files)
  project_data = projects.map do |project|
    collect_project_data(
      brand_arg, brand_path, brand_info, project, is_git_repo,
      detailed: detailed,
      s3: s3,
      s3_files_cache: s3_files_cache  # NEW PARAMETER
    )
  end

  # ... (rest of method unchanged)
end
```

**Modify:** `collect_project_data` to use cached S3 files

```ruby
def self.collect_project_data(brand_arg, brand_path, brand_info, project, is_git_repo,
                               detailed: false, s3: false, s3_files_cache: {})
  # ... (existing code)

  # Calculate 3-state S3 sync status - use cache if available
  s3_sync = if s3
              calculate_project_s3_sync_status(
                brand_arg, brand_info, project,
                s3_files: s3_files_cache[project]  # Use cached S3 files
              )
            else
              'N/A'
            end

  # ... (rest of method)
end
```

**Modify:** `calculate_project_s3_sync_status` to accept cached files

```ruby
def self.calculate_project_s3_sync_status(brand_arg, brand_info, project, s3_files: nil)
  # Check if S3 is configured
  s3_bucket = brand_info.aws.s3_bucket
  return 'N/A' if s3_bucket.nil? || s3_bucket.empty? || s3_bucket == 'NOT-SET'

  # Use S3Operations to calculate sync status
  begin
    s3_ops = S3Operations.new(brand_arg, project, brand_info: brand_info)
    s3_ops.calculate_sync_status(s3_files: s3_files)  # Pass cached files
  rescue StandardError
    # S3 not accessible or other error
    'N/A'
  end
end
```

---

## 5. Implementation Tasks

### Phase 1: Core Batch Listing (2-3 hours)

**Task 1.1:** Add `S3Operations.list_all_brand_files` class method
- [ ] Implement single list_objects_v2 call with pagination
- [ ] Handle S3 pagination (continuation tokens)
- [ ] Group files by project ID
- [ ] Return hash map: `{ project_id => [files] }`
- [ ] Handle errors gracefully (return empty hash on failure)

**Task 1.2:** Extract `group_files_by_project` helper
- [ ] Parse S3 keys to extract project IDs
- [ ] Handle edge cases (empty keys, missing project folders)
- [ ] Unit tests with sample S3 responses

**Task 1.3:** Update `calculate_sync_status` to accept cached files
- [ ] Add optional `s3_files:` parameter
- [ ] Use cached files if provided, fallback to `list_s3_files()` otherwise
- [ ] Ensure backward compatibility (existing code still works)

### Phase 2: Integration (1-2 hours)

**Task 2.1:** Update `ProjectListing.list_brand_projects`
- [ ] Call `S3Operations.list_all_brand_files` once before loop
- [ ] Pass `s3_files_cache` to `collect_project_data`
- [ ] Handle S3 fetch errors gracefully

**Task 2.2:** Update `collect_project_data`
- [ ] Accept `s3_files_cache:` parameter
- [ ] Pass cached files to `calculate_project_s3_sync_status`

**Task 2.3:** Update `calculate_project_s3_sync_status`
- [ ] Accept `s3_files:` parameter
- [ ] Pass to `calculate_sync_status`

### Phase 3: S3 Timestamps (1 hour)

**Task 3.1:** Update `calculate_s3_timestamps` for batch mode
- [ ] Accept optional `s3_files:` parameter
- [ ] Extract timestamps from cached data
- [ ] Fallback to `list_s3_files()` if not cached

**Task 3.2:** Update `collect_project_data` detailed mode
- [ ] Pass cached S3 files to `calculate_s3_timestamps`

### Phase 4: Testing (2-3 hours)

**Task 4.1:** Unit tests
- [ ] Test `group_files_by_project` with various S3 key formats
- [ ] Test empty brand (no projects in S3)
- [ ] Test partial match (some projects have S3 files, some don't)
- [ ] Test S3 pagination (large brands with >1000 files)

**Task 4.2:** Integration tests
- [ ] Test `list_brand_projects` with batch listing
- [ ] Test fallback to individual listing on batch error
- [ ] Test backward compatibility (existing code paths)

**Task 4.3:** Performance validation
- [ ] Measure AWS API call count (should be 1)
- [ ] Measure wall-clock time improvement
- [ ] Test with various brand sizes (1, 10, 50 projects)

### Phase 5: Documentation (30 minutes)

**Task 5.1:** Update CLAUDE.md
- [ ] Document batch listing approach
- [ ] Update performance notes

**Task 5.2:** Add code comments
- [ ] Document new class method
- [ ] Explain batching strategy

---

## 6. Testing Strategy

### 6.1 Unit Tests

**Location:** `spec/appydave/tools/dam/s3_operations_spec.rb`

```ruby
describe S3Operations do
  describe '.list_all_brand_files' do
    let(:brand) { 'appydave' }
    let(:s3_client) { instance_double(Aws::S3::Client) }

    context 'with multiple projects' do
      it 'groups files by project ID' do
        # Mock S3 response
        response = double(
          contents: [
            double(key: 'staging/appydave/b60-project/video.mp4', size: 1000, etag: '"abc"', last_modified: Time.now),
            double(key: 'staging/appydave/b60-project/subtitle.srt', size: 100, etag: '"def"', last_modified: Time.now),
            double(key: 'staging/appydave/b61-other/video.mp4', size: 2000, etag: '"ghi"', last_modified: Time.now)
          ],
          is_truncated: false
        )

        allow(s3_client).to receive(:list_objects_v2).and_return(response)

        result = S3Operations.list_all_brand_files(brand, s3_client: s3_client)

        expect(result.keys).to contain_exactly('b60-project', 'b61-other')
        expect(result['b60-project'].size).to eq(2)
        expect(result['b61-other'].size).to eq(1)
      end
    end

    context 'with S3 pagination' do
      it 'fetches all pages' do
        # Test continuation token handling
      end
    end

    context 'with empty brand' do
      it 'returns empty hash' do
        # Test no files case
      end
    end
  end

  describe '#calculate_sync_status' do
    context 'with cached S3 files' do
      it 'uses cached data instead of AWS call' do
        # Verify no S3 API call made
      end
    end

    context 'without cached files' do
      it 'falls back to individual listing' do
        # Verify AWS call still made
      end
    end
  end
end
```

### 6.2 Integration Tests

**Location:** `spec/appydave/tools/dam/project_listing_spec.rb`

```ruby
describe ProjectListing do
  describe '.list_brand_projects' do
    context 'with --s3 flag (batch mode)' do
      it 'makes single AWS call for all projects' do
        allow(S3Operations).to receive(:list_all_brand_files).once.and_return({})

        ProjectListing.list_brand_projects('appydave', s3: true)

        expect(S3Operations).to have_received(:list_all_brand_files).once
      end

      it 'displays correct S3 status for all projects' do
        # Verify output matches expectations
      end
    end
  end
end
```

### 6.3 Performance Tests

**Manual Testing Script:**

```bash
# Baseline (individual calls)
git checkout main
time bin/dam list appydave --s3

# After batch implementation
git checkout feature/batch-s3-listing
time bin/dam list appydave --s3

# Expected improvement: 3-5s → 300-500ms
```

---

## 7. Risks & Mitigations

### Risk 1: S3 Key Format Variations

**Risk:** Different project naming conventions may break project ID extraction.

**Examples:**
- FliVideo: `b60-project-name` (standard)
- Storyline: `boy-baker` (no prefix)
- Edge case: `b60-project-name/archived/video.mp4` (nested folders)

**Mitigation:**
- Extract project ID as first path segment after brand prefix
- Unit test with various key formats
- Gracefully handle unexpected formats (skip, don't crash)

### Risk 2: Large Brand Performance

**Risk:** Brands with 1000+ files may have slow S3 pagination.

**Mitigation:**
- Implement proper pagination (continuation tokens)
- Add progress indicator for large brands
- Consider caching results (future enhancement)

### Risk 3: Partial S3 Failures

**Risk:** S3 listing succeeds but some projects fail to parse.

**Mitigation:**
- Return partial results (best-effort)
- Log warnings for unparseable keys
- Don't block entire listing on single project error

### Risk 4: Backward Compatibility

**Risk:** Breaking existing code that uses `calculate_sync_status()` without parameters.

**Mitigation:**
- Make `s3_files:` parameter optional with default `nil`
- Existing code falls back to individual listing
- Ensure all existing tests still pass

### Risk 5: S3 API Rate Limits

**Risk:** Large brands may hit S3 API rate limits.

**Mitigation:**
- Single call is much better than N calls
- AWS S3 rate limits are generous (5500 GET/HEAD per second per prefix)
- Monitor CloudWatch metrics for throttling

---

## 8. Performance Expectations

### Current Performance (Baseline)

**Test case:** `dam list appydave --s3` (13 projects)

| Metric | Value |
|--------|-------|
| AWS API calls | 13 (sequential) |
| Network round-trips | 13 |
| Total time | 3-5 seconds |
| User experience | Slow, frustrating |

### Expected Performance (After Batch)

| Metric | Value | Improvement |
|--------|-------|-------------|
| AWS API calls | 1 (may paginate) | 13x reduction |
| Network round-trips | 1-2 | 6-13x reduction |
| Total time | 300-500ms | 6-10x faster |
| User experience | Fast, responsive | ✅ Acceptable |

### Performance by Brand Size

| Projects | Current | After Batch | Improvement |
|----------|---------|-------------|-------------|
| 5 | 1-2s | 200-300ms | 5-7x |
| 13 | 3-5s | 300-500ms | 6-10x |
| 30 | 8-12s | 500-800ms | 10-15x |
| 50 | 15-20s | 800-1200ms | 12-18x |

**Note:** Improvement scales with brand size (larger brands benefit more).

---

## 9. Future Enhancements

### 9.1 Caching Layer (Optional)

**Benefit:** Repeated `dam list` calls within 30-60 seconds use cached S3 data.

**Implementation:**
- Cache S3 results in temp file or memory
- TTL: 30-60 seconds
- Invalidate on `s3-up`, `s3-down`, `s3-cleanup`

**Trade-off:** Adds complexity, stale data risk

### 9.2 Parallel Git Status (Future)

**Note:** Git status checks also exhibit N+1 pattern (checked per project).

**Potential fix:**
- Batch `git status` calls using single `git status --porcelain <project1> <project2> ...`
- Or parallelize git calls (less benefit than S3)

**Priority:** Lower (git is local, faster than S3)

### 9.3 Progress Indicators

**For large brands:** Show spinner or progress bar during S3 fetch.

```ruby
print "🔍 Fetching S3 data for #{brand}... "
s3_files_cache = S3Operations.list_all_brand_files(brand)
puts "✓ (#{s3_files_cache.size} projects)"
```

---

## 10. Success Criteria

### Must Have

- ✅ Single AWS S3 API call per brand (vs N calls currently)
- ✅ Correct S3 sync status for all projects
- ✅ No regressions in existing functionality
- ✅ All existing tests pass
- ✅ Performance improvement: 3-5s → < 1s

### Nice to Have

- ⭐ Unit test coverage > 90%
- ⭐ Performance improvement > 6x
- ⭐ Graceful error handling for S3 failures
- ⭐ Progress indicator for large brands

### Out of Scope

- ❌ Caching layer (future enhancement)
- ❌ Batch git status (separate issue)
- ❌ Parallel S3 requests (single call is better)

---

## 11. Rollout Plan

### Phase 1: Development (This Sprint)

1. Implement batch listing (Tasks 1.1-1.3)
2. Integrate with ProjectListing (Tasks 2.1-2.3)
3. Add S3 timestamps support (Tasks 3.1-3.2)
4. Unit tests (Task 4.1)

### Phase 2: Testing (Next Sprint)

1. Integration tests (Task 4.2)
2. Performance validation (Task 4.3)
3. UAT with real brands (appydave, voz, ss)

### Phase 3: Documentation & Release

1. Update documentation (Task 5.1-5.2)
2. Code review
3. Merge to main
4. Release as minor version (e.g., v0.70.0)

---

## 12. Appendix

### A. S3 Key Format Examples

**FliVideo (AppyDave):**
```
staging/appydave/b60-automate-image-generation/video.mp4
staging/appydave/b60-automate-image-generation/subtitle.srt
staging/appydave/b61-kdd-bmad/video.mp4
```

**Storyline (VOZ):**
```
staging/voz/boy-baker/final-edit.mov
staging/voz/boy-baker/scene-01.mp4
staging/voz/the-point/intro.mp4
```

**Project ID Extraction Logic:**
```ruby
# Input:  "staging/appydave/b60-project/video.mp4"
# Prefix: "staging/appydave/"
# Remove prefix: "b60-project/video.mp4"
# Split on '/': ["b60-project", "video.mp4"]
# First element: "b60-project"  ← Project ID
```

### B. AWS S3 list_objects_v2 API

**Request:**
```ruby
response = s3_client.list_objects_v2(
  bucket: 'appydave-video-projects',
  prefix: 'staging/appydave/',
  max_keys: 1000,  # Default max per page
  continuation_token: nil  # For pagination
)
```

**Response Structure:**
```ruby
{
  contents: [
    {
      key: 'staging/appydave/b60-project/video.mp4',
      size: 12345678,
      etag: '"abc123def456"',
      last_modified: Time.parse('2025-01-20 10:30:00 UTC')
    },
    # ... more objects
  ],
  is_truncated: true,  # More results available?
  next_continuation_token: 'xyz789...'  # Use for next page
}
```

**Pagination Example:**
```ruby
def fetch_all_objects(s3_client, bucket, prefix)
  all_objects = []
  continuation_token = nil

  loop do
    response = s3_client.list_objects_v2(
      bucket: bucket,
      prefix: prefix,
      continuation_token: continuation_token
    )

    all_objects.concat(response.contents) if response.contents

    break unless response.is_truncated
    continuation_token = response.next_continuation_token
  end

  all_objects
end
```

### C. Error Handling Strategy

**Graceful Degradation:**
```ruby
begin
  s3_files_cache = S3Operations.list_all_brand_files(brand)
rescue Aws::S3::Errors::ServiceError => e
  # AWS error (credentials, network, etc.)
  puts "⚠️  S3 listing failed: #{e.message}" if ENV['DAM_DEBUG']
  s3_files_cache = {}  # Fall back to no S3 data
rescue StandardError => e
  # Unexpected error
  puts "⚠️  Unexpected error: #{e.message}" if ENV['DAM_DEBUG']
  s3_files_cache = {}
end

# Continue with empty cache (shows 'N/A' for S3 status)
```

---

**End of Requirements Document**
