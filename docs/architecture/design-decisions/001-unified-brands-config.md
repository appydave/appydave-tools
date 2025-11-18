# PRD: Unified Brands Configuration System

**Status**: Draft for Review
**Author**: Claude (with David Cruwys)
**Date**: 2025-11-09
**Version**: 1.0

---

## Executive Summary

Create a unified `brands.json` configuration system that consolidates video project brand management, integrating with existing `channels.json` (YouTube) and `settings.json` (global) configs. This eliminates the fragmented `.video-tools.env` files and provides a centralized, team-friendly configuration approach for multi-brand video project collaboration.

---

## Problem Statement

### Current Issues

1. **Fragmented Configuration**: Three disconnected systems
   - `settings.json` (global paths)
   - `channels.json` (YouTube metadata) - only 2/7 brands configured
   - `.video-tools.env` (per-brand secrets) - only 1/7 brands has this file

2. **Missing Multi-User Support**:
   - Only David's credentials configured
   - No structure for Jan, Vasilios, Ronnie to use their own AWS credentials
   - No clear team access model

3. **Code Bugs**:
   - `ConfigLoader.load()` doesn't exist (should be `load_from_repo()`)
   - AWS CLI dependency instead of AWS SDK gem
   - Hardcoded brand shortcuts in `Config.expand_brand()`

4. **Incomplete Coverage**:
   - 7 brand directories exist
   - 2 configured in `channels.json`
   - 1 has `.video-tools.env`
   - Brands: appydave, voz, aitldr, kiros, beauty-and-joy, supportsignal

5. **Relationship Ambiguity**:
   - Brands vs. YouTube channels not clearly defined
   - Some brands are owned (appydave, aitldr, beauty-and-joy)
   - Some brands are client work (voz, kiros, supportsignal)
   - Not all brands publish to YouTube

---

## Goals

### Primary Goals

1. **Unified Configuration**: Single source of truth for brand metadata via `brands.json`
2. **Multi-User Support**: Enable David, Jan, Vasilios, Ronnie to use their own AWS credentials
3. **Security**: Separate secrets (AWS credentials) from metadata (brand config)
4. **Consistency**: All 7 brands properly configured and accessible
5. **Tool Integration**: `ad_config` (alias to `bin/configuration.rb`) manages all configs

### Secondary Goals

1. Migrate from AWS CLI shell commands to AWS SDK gem
2. Fix `ConfigLoader` bugs
3. Remove `.video-tools.env` dependency
4. Link brands ↔ YouTube channels where applicable

### Non-Goals

1. **No business logic on brand types**: `owned` vs `client` is metadata only
2. **No client isolation**: Single S3 bucket with prefixes (current architecture)
3. **No required YouTube channels**: Brands can exist without YouTube channels
4. **No complex permissions**: Use AWS IAM for access control

---

## User Stories

### As David (Owner)
- I want to configure all 7 brands in one place
- I want to use my AWS credentials for brands I manage (appydave, aitldr, joy)
- I want team members to use their own credentials for brands they manage
- I want `ad_config` to show me all brands and their configuration status

### As Jan (Team Member)
- I want to access most brands (except maybe appydave core) with my AWS credentials
- I want to see which brands I have access to
- I want VAT commands to automatically use my AWS profile

### As Vasilios (Client - VOZ)
- I want to access only v-voz brand with my AWS credentials
- I want VAT to work for my brand without seeing other brands

### As Ronnie (Client - Kiros/SupportSignal)
- I want to access v-kiros and v-supportsignal with my AWS credentials
- I want isolated access to only my client brands

### As Developer (Using VAT)
- I want `vat list` to show all brands I have access to
- I want `vat s3-up appydave b65` to use the correct AWS profile automatically
- I want clear error messages if my AWS credentials are missing/invalid

---

## Architecture

### Configuration File Structure

```
~/.config/appydave/
├── settings.json          # Global tool settings
├── channels.json          # YouTube channel configs (existing)
├── brands.json            # NEW: Video project brands
└── youtube_automation.json

~/.aws/
└── credentials            # AWS profiles (standard AWS CLI format)
```

### brands.json Schema

```json
{
  "brands": {
    "appydave": {
      "name": "AppyDave",
      "shortcut": "ad",
      "type": "owned",
      "youtube_channels": ["appydave"],
      "team": ["david", "jan"],
      "locations": {
        "video_projects": "/Users/davidcruwys/dev/video-projects/v-appydave",
        "ssd_backup": "/Volumes/T7/youtube-PUBLISHED/appydave"
      },
      "aws": {
        "profile": "david-appydave",
        "region": "ap-southeast-1",
        "s3_bucket": "appydave-video-projects",
        "s3_prefix": "staging/v-appydave/"
      },
      "settings": {
        "s3_cleanup_days": 90
      }
    },
    "voz": {
      "name": "VOZ Creative",
      "shortcut": "voz",
      "type": "client",
      "youtube_channels": [],
      "team": ["vasilios"],
      "locations": {
        "video_projects": "/Users/davidcruwys/dev/video-projects/v-voz",
        "ssd_backup": "/Volumes/T7/voz"
      },
      "aws": {
        "profile": "vasilios-voz",
        "region": "ap-southeast-1",
        "s3_bucket": "appydave-video-projects",
        "s3_prefix": "staging/v-voz/"
      }
    },
    "aitldr": {
      "name": "AITLDR",
      "shortcut": "ai",
      "type": "owned",
      "youtube_channels": ["aitldr"],
      "team": ["david", "jan"],
      "aws": {
        "profile": "david-appydave",
        "region": "ap-southeast-1",
        "s3_bucket": "appydave-video-projects",
        "s3_prefix": "staging/v-aitldr/"
      }
    },
    "beauty-and-joy": {
      "name": "Beauty & Joy",
      "shortcut": "joy",
      "type": "owned",
      "youtube_channels": [],
      "team": ["joy", "david"],
      "aws": {
        "profile": "david-appydave",
        "region": "ap-southeast-1",
        "s3_bucket": "appydave-video-projects",
        "s3_prefix": "staging/v-beauty-and-joy/"
      }
    },
    "kiros": {
      "name": "Kiros",
      "shortcut": "kiros",
      "type": "client",
      "youtube_channels": [],
      "team": ["ronnie"],
      "aws": {
        "profile": "ronnie-kiros",
        "region": "ap-southeast-1",
        "s3_bucket": "appydave-video-projects",
        "s3_prefix": "staging/v-kiros/"
      }
    },
    "supportsignal": {
      "name": "SupportSignal",
      "shortcut": "ss",
      "type": "client",
      "youtube_channels": [],
      "team": ["ronnie"],
      "aws": {
        "profile": "ronnie-kiros",
        "region": "ap-southeast-1",
        "s3_bucket": "appydave-video-projects",
        "s3_prefix": "staging/v-supportsignal/"
      }
    }
  },
  "users": {
    "david": {
      "name": "David Cruwys",
      "email": "david@appydave.com",
      "role": "owner",
      "default_aws_profile": "david-appydave"
    },
    "jan": {
      "name": "Jan",
      "role": "team_member",
      "default_aws_profile": "jan-appydave"
    },
    "vasilios": {
      "name": "Vasilios Kapenekas",
      "role": "client",
      "default_aws_profile": "vasilios-voz"
    },
    "ronnie": {
      "name": "Ronnie",
      "role": "client",
      "default_aws_profile": "ronnie-kiros"
    },
    "joy": {
      "name": "Joy",
      "role": "owner",
      "default_aws_profile": "joy-beauty"
    }
  }
}
```

### AWS Credentials (separate file)

**Location**: `~/.aws/credentials` (standard AWS CLI format)

```ini
[david-appydave]
aws_access_key_id = YOUR_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_SECRET_KEY_HERE

[jan-appydave]
aws_access_key_id = YOUR_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_SECRET_KEY_HERE

[vasilios-voz]
aws_access_key_id = YOUR_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_SECRET_KEY_HERE

[ronnie-kiros]
aws_access_key_id = YOUR_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_SECRET_KEY_HERE

[joy-beauty]
aws_access_key_id = YOUR_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_SECRET_KEY_HERE
```

**Security Benefits**:
- ✅ Never in git (standard AWS practice)
- ✅ Standard AWS tooling (`aws configure --profile`)
- ✅ Per-user credentials
- ✅ Separate from metadata

---

## Data Model

### BrandInfo Class

```ruby
class BrandInfo
  attr_accessor :key, :name, :shortcut, :type, :youtube_channels,
                :team, :locations, :aws, :settings

  def initialize(key, data)
    @key = key
    @name = data['name']
    @shortcut = data['shortcut']
    @type = data['type']  # 'owned' or 'client' (metadata only)
    @youtube_channels = data['youtube_channels'] || []
    @team = data['team'] || []
    @locations = BrandLocation.new(data['locations'] || {})
    @aws = BrandAws.new(data['aws'] || {})
    @settings = BrandSettings.new(data['settings'] || {})
  end
end

class BrandLocation
  attr_accessor :video_projects, :ssd_backup
end

class BrandAws
  attr_accessor :profile, :region, :s3_bucket, :s3_prefix
end

class BrandSettings
  attr_accessor :s3_cleanup_days
end
```

---

## Features & Requirements

### Feature 1: BrandsConfig Model

**Description**: New configuration model parallel to `ChannelsConfig`

**Requirements**:
- [ ] Create `lib/appydave/tools/configuration/models/brands_config.rb`
- [ ] Implement `BrandsConfig < ConfigBase`
- [ ] Methods:
  - `get_brand(brand_key)` → returns `BrandInfo`
  - `set_brand(brand_key, brand_info)` → saves brand
  - `brands()` → returns array of all `BrandInfo`
  - `get_brands_for_user(user_key)` → filters by team membership
  - `key?(key)` → check if brand exists
  - `print()` → tabular display of all brands
- [ ] Type-safe classes: `BrandInfo`, `BrandLocation`, `BrandAws`, `BrandSettings`
- [ ] Default data structure
- [ ] Config file: `~/.config/appydave/brands.json`

**Acceptance Criteria**:
- BrandsConfig loads/saves brands.json correctly
- All 7 brands can be configured
- Validation ensures required fields present
- Print displays tabular brand information

---

### Feature 2: Integration with Configuration::Config

**Description**: Register brands configuration in central config system

**Requirements**:
- [ ] Update `lib/appydave/tools/configuration/config.rb`
- [ ] Add `register_config(:brands, Models::BrandsConfig)`
- [ ] Method: `Config.brands` returns `BrandsConfig` instance
- [ ] Method: `Config.configure` includes brands setup

**Acceptance Criteria**:
- `ad_config -p brands` prints brands configuration
- `ad_config -c` creates default brands.json if missing
- `ad_config -e` opens brands.json in editor

---

### Feature 3: Migrate VAT to Use brands.json

**Description**: Remove dependency on `.video-tools.env`, use `brands.json` instead

**Requirements**:

**3a. Update Vat::Config**:
- [ ] Remove hardcoded brand shortcuts (joy, ss)
- [ ] Read brand shortcuts from `brands.json`
- [ ] `brand_path()` reads from `brands.json` locations
- [ ] `expand_brand()` reads from `brands.json` shortcuts
- [ ] `available_brands()` reads from `brands.json`
- [ ] Remove `valid_brand?()` check for `.video-tools.env`

**3b. Update Vat::ConfigLoader**:
- [ ] Deprecate `ConfigLoader` entirely (no longer needed)
- [ ] OR: Refactor to load from `brands.json` instead of `.video-tools.env`
- [ ] Method: `ConfigLoader.load_brand(brand_key)` → loads from `brands.json`
- [ ] Fix bug: `ConfigLoader.load()` doesn't exist (called by S3Operations:19)

**3c. Update S3Operations**:
- [ ] Initialize with `brand_key` instead of `brand_path`
- [ ] Load config from `brands.json`: `config = Config.brands.get_brand(brand_key)`
- [ ] Get AWS profile: `config.aws.profile`
- [ ] Get S3 bucket: `config.aws.s3_bucket`
- [ ] Get S3 prefix: `config.aws.s3_prefix`

**Acceptance Criteria**:
- VAT commands work with brands.json
- No dependency on `.video-tools.env`
- All 7 brands accessible
- `vat list` shows all configured brands

---

### Feature 4: AWS SDK Integration

**Description**: Replace AWS CLI shell commands with AWS SDK gem

**Requirements**:
- [ ] Add gem dependency: `spec.add_dependency 'aws-sdk-s3', '~> 1.0'`
- [ ] Update `S3Operations` to use AWS SDK
- [ ] Initialize S3 client with profile from `brands.json`:
  ```ruby
  Aws::S3::Client.new(
    profile: config.aws.profile,
    region: config.aws.region
  )
  ```
- [ ] Replace 5 AWS CLI operations:
  1. `aws s3api head-object` → `s3_client.head_object()`
  2. `aws s3 cp` (upload) → `s3_client.put_object()`
  3. `aws s3 cp` (download) → `s3_client.get_object()`
  4. `aws s3 rm` → `s3_client.delete_object()`
  5. `aws s3api list-objects-v2` → `s3_client.list_objects_v2()`

**Acceptance Criteria**:
- No AWS CLI dependency
- S3 operations use SDK gem
- AWS credentials from `~/.aws/credentials` profiles
- Error handling for missing/invalid credentials
- All existing VAT S3 commands work (s3-up, s3-down, s3-status, s3-cleanup)

---

### Feature 5: Update bin/vat Command

**Description**: Ensure VAT CLI works with new brands.json system

**Requirements**:
- [ ] Update `parse_s3_args()` to use brands config
- [ ] Remove `ENV['BRAND_PATH']` workaround (line 203)
- [ ] Update help text to reference brands.json
- [ ] Update `vat help config` to show brands.json setup

**Acceptance Criteria**:
- `vat list` shows all brands from brands.json
- `vat s3-*` commands use AWS SDK with correct profiles
- Help text accurate

---

### Feature 6: Migration Tool

**Description**: Migrate existing `.video-tools.env` → `brands.json` + `~/.aws/credentials`

**Requirements**:
- [ ] Create `bin/migrate_brands_config.rb`
- [ ] Read existing `.video-tools.env` files
- [ ] Generate `brands.json` structure
- [ ] Generate `~/.aws/credentials` profiles
- [ ] Show migration summary
- [ ] Backup original files

**Acceptance Criteria**:
- Migration tool converts v-appydave/.video-tools.env successfully
- Generates complete brands.json with all 7 brands
- AWS credentials extracted to ~/.aws/credentials
- User can review before committing changes

---

### Feature 7: Documentation

**Requirements**:
- [ ] Update `docs/vat/vat-testing-plan.md`
  - Remove references to `.video-tools.env`
  - Add references to `brands.json`
  - Update setup instructions
- [ ] Create `docs/brands-configuration.md`
  - Explain brands.json structure
  - Setup guide for new team members
  - AWS profile setup instructions
- [ ] Update `CLAUDE.md`
  - Document brands configuration system
  - Update VAT configuration section

---

## Technical Specifications

### Code Structure

```
lib/appydave/tools/
├── configuration/
│   ├── config.rb                     # Update: register brands
│   └── models/
│       ├── brands_config.rb          # NEW
│       ├── channels_config.rb        # Existing
│       └── settings_config.rb        # Existing
│
└── vat/
    ├── config.rb                     # Update: use brands.json
    ├── config_loader.rb              # Deprecate or refactor
    ├── s3_operations.rb              # Update: AWS SDK + brands.json
    ├── project_listing.rb            # Update: use brands.json
    └── project_resolver.rb           # Update: use brands.json

bin/
├── configuration.rb                  # Update: support brands
├── vat                               # Update: use brands.json
└── migrate_brands_config.rb          # NEW

docs/
├── prd-unified-brands-configuration.md  # This file
├── brands-configuration.md           # NEW: User guide
└── vat/
    └── vat-testing-plan.md          # Update references
```

---

## Testing Strategy

### Unit Tests

- [ ] `spec/appydave/tools/configuration/models/brands_config_spec.rb`
  - Test load/save brands.json
  - Test get_brand(), brands(), get_brands_for_user()
  - Test validation
  - Test print()

- [ ] Update `spec/appydave/tools/vat/config_spec.rb`
  - Test brand_path() reads from brands.json
  - Test expand_brand() uses brands.json shortcuts
  - Test available_brands() from brands.json

- [ ] Update `spec/appydave/tools/vat/s3_operations_spec.rb`
  - Mock AWS SDK client
  - Test all 5 S3 operations with SDK
  - Test AWS profile loading

### Integration Tests

- [ ] Test `ad_config -p brands` prints all brands
- [ ] Test `ad_config -c` creates brands.json
- [ ] Test `vat list` with brands.json
- [ ] Test `vat s3-up` with AWS SDK and profiles
- [ ] Test migration tool with sample .video-tools.env

### Manual Testing

- [ ] Setup brands.json on David's machine
- [ ] Setup AWS profiles for David
- [ ] Test all VAT commands
- [ ] Verify other team members can set up their profiles

---

## Migration Plan

### Phase 1: Foundation (Week 1) ✅ COMPLETED

**Goal**: Create brands.json infrastructure

1. ✅ Create `BrandsConfig` model
2. ✅ Register with `Configuration::Config`
3. ✅ Write unit tests
4. ✅ Test `ad_config` commands
5. ✅ Populate all 6 brands (appydave, voz, aitldr, kiros, joy, ss)

**Deliverable**: Working brands.json system

**Status**: Complete (2025-11-09)

---

### Phase 2: VAT Integration (Week 2) ✅ COMPLETED

**Goal**: VAT uses brands.json

1. ✅ Update `Vat::Config` to read brands.json
2. ✅ Refactor/deprecate `ConfigLoader`
3. ✅ Update VAT commands
4. ✅ Update unit tests

**Deliverable**: VAT works with brands.json (still using AWS CLI)

**Status**: Complete (2025-11-09)

---

### Phase 3: AWS SDK (Week 2-3) ✅ COMPLETED

**Goal**: Replace AWS CLI with SDK

1. ✅ Add aws-sdk-s3 gem
2. ✅ Refactor `S3Operations` to use SDK
3. ✅ Test with AWS profiles
4. ✅ Update integration tests
5. ✅ Implement dependency injection pattern
6. ✅ Add S3 cleanup local command
7. ✅ Fix S3 status to show local-only files
8. ✅ Rename cleanup commands (s3-cleanup-remote, s3-cleanup-local)

**Deliverable**: VAT uses AWS SDK with profiles from brands.json

**Status**: Complete (2025-11-09)
- 289 tests passing
- 90.59% code coverage
- RuboCop clean
- Manually tested by David

---

### Phase 4: Migration & Cleanup (Week 3)

**Goal**: Complete migration, remove old system

1. Create migration tool
2. Migrate David's setup
3. Test all VAT workflows
4. Update documentation
5. Remove `.video-tools.env` dependency
6. Update testing plan

**Deliverable**: Production-ready unified configuration system

---

### Phase 5: Team Onboarding (Week 4)

**Goal**: Enable team members to configure their access

1. Document setup process
2. Create AWS IAM users (if needed)
3. Help Jan/Vasilios/Ronnie configure profiles
4. Test multi-user access

**Deliverable**: All team members using VAT with their own credentials

---

## Success Criteria

### Must Have (MVP)

- [ ] All 7 brands configured in brands.json
- [ ] AWS credentials in ~/.aws/credentials profiles
- [ ] VAT commands work with brands.json
- [ ] S3 operations use AWS SDK gem
- [ ] No dependency on .video-tools.env
- [ ] All existing tests pass
- [ ] Migration tool works
- [ ] Documentation complete

### Should Have

- [ ] Team members can configure their own profiles
- [ ] Multi-user access tested
- [ ] Error messages helpful for missing credentials
- [ ] `ad_config` prints brand summary

### Nice to Have

- [ ] Brand-channel linking visible in `ad_config`
- [ ] Validate AWS profiles are configured
- [ ] Auto-detect current user
- [ ] Brand access enforcement (by team membership)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing VAT workflows | High | Thorough testing, migration tool, rollback plan |
| AWS SDK complexity | Medium | Start with simple operations, test extensively |
| Team member setup friction | Medium | Clear documentation, setup scripts |
| ConfigLoader refactoring breaks things | High | Incremental changes, test coverage |
| .video-tools.env still needed for legacy scripts | Low | Audit all usages first |

---

## Open Questions

1. **User detection**: How should VAT detect current user (david, jan, etc.)?
   - Option A: `whoami` system user
   - Option B: Config setting `~/.config/appydave/settings.json` → `current_user`
   - Option C: Environment variable `APPYDAVE_USER`

2. **AWS profile fallback**: What if profile doesn't exist?
   - Try user's default profile?
   - Error with setup instructions?

3. **Brand access enforcement**: Should VAT check team membership?
   - Or rely on AWS IAM to deny access?

4. **SSD backup**: Should all brands share same SSD path structure?
   - Current: `/Volumes/T7/youtube-PUBLISHED/{brand}/`
   - Or allow custom per-brand paths?

5. **Legacy bin/ scripts**: What about `archive_project.rb`, `sync_from_ssd.rb`, `generate_manifest.rb`?
   - Migrate to brands.json?
   - Integrate into `vat` command?
   - Leave as-is?

---

## Appendix A: Current vs. Proposed

### Current System

```
Configuration Sources:
1. settings.json → video-projects-root only
2. channels.json → 2/7 brands, YouTube metadata
3. .video-tools.env → 1/7 brands, AWS credentials

AWS Access:
- Hardcoded in .video-tools.env
- Only David's credentials
- AWS CLI shell commands

Brand Discovery:
- Hardcoded shortcuts (joy, ss)
- Scans filesystem for v-* directories
- No central registration
```

### Proposed System

```
Configuration Sources:
1. settings.json → global paths (unchanged)
2. channels.json → YouTube metadata (unchanged)
3. brands.json → ALL brand metadata (NEW)
4. ~/.aws/credentials → AWS profiles (standard)

AWS Access:
- Per-user profiles in ~/.aws/credentials
- AWS SDK gem (no CLI dependency)
- Profile name from brands.json

Brand Discovery:
- Registered in brands.json
- Shortcuts defined in brands.json
- Team membership tracked
```

---

## Appendix B: Example Workflows

### Setup New Brand (VOZ)

```bash
# 1. Add brand to brands.json
ad_config -e
# Add voz brand config with Vasilios's AWS profile

# 2. Vasilios configures his AWS credentials
aws configure --profile vasilios-voz
# Enters his AWS_ACCESS_KEY_ID and SECRET

# 3. Test access
vat list voz
vat s3-status voz boy-baker
```

### Developer Using VAT

```bash
# List all brands I have access to
vat list

# Work with specific brand (auto-detects profile)
cd ~/dev/video-projects/v-appydave/b65-*
vat s3-up --dry-run

# Explicit brand
vat s3-up appydave b65
# Uses aws.profile from brands.json → david-appydave
```

---

## Sign-Off

**Product Owner**: David Cruwys
**Developer**: Claude
**Reviewer**: ___________

**Approval Date**: ___________

---

**Next Steps After Approval**:
1. Review and approve PRD
2. Create implementation plan with tasks
3. Begin Phase 1: BrandsConfig model
4. Weekly progress reviews
