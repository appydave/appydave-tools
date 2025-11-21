## [0.32.3](https://github.com/appydave/appydave-tools/compare/v0.32.2...v0.32.3) (2025-11-21)


### Bug Fixes

* add debug logging to projects_directory and re-add 'projects' to organizational folder exclusions to diagnose configuration issue ([0dc34d7](https://github.com/appydave/appydave-tools/commit/0dc34d765d3ec89400304eebf4a0718a4485580d))

## [0.32.2](https://github.com/appydave/appydave-tools/compare/v0.32.1...v0.32.2) (2025-11-21)


### Bug Fixes

* remove 'projects' from organizational folder exclusions - it should only be excluded when appearing at brand root, not when projects_subfolder properly configured ([4c72a11](https://github.com/appydave/appydave-tools/commit/4c72a116805573a3444dd977ed711e5f7538e190))

## [0.32.1](https://github.com/appydave/appydave-tools/compare/v0.32.0...v0.32.1) (2025-11-21)


### Bug Fixes

* exclude organizational folders (brand, personas, projects, video-scripts) from ProjectResolver.valid_project? to prevent them appearing in project lists ([c573edf](https://github.com/appydave/appydave-tools/commit/c573edf138daebcdbb2ece102e6f36db92453a70))

# [0.32.0](https://github.com/appydave/appydave-tools/compare/v0.31.2...v0.32.0) (2025-11-21)


### Features

* add comprehensive unit tests for projects_subfolder feature in ProjectResolver and ProjectListing ([d815be9](https://github.com/appydave/appydave-tools/commit/d815be931ed7dea3b7f048f3fb3f850861626300))

## [0.31.2](https://github.com/appydave/appydave-tools/compare/v0.31.1...v0.31.2) (2025-11-21)


### Bug Fixes

* improve repo-status messages to be more human-readable - change 'ahead/behind' to 'commits to push/pull' ([936ed2e](https://github.com/appydave/appydave-tools/commit/936ed2e28039c03ef8e73d36e0b241337ed08c20))

## [0.31.1](https://github.com/appydave/appydave-tools/compare/v0.31.0...v0.31.1) (2025-11-21)


### Bug Fixes

* add git fetch to repo-status for accurate remote sync detection ([cdbf411](https://github.com/appydave/appydave-tools/commit/cdbf411d4978195c247656c0e443f390d60cdfe8))

# [0.31.0](https://github.com/appydave/appydave-tools/compare/v0.30.0...v0.31.0) (2025-11-21)


### Features

* fix ManifestGenerator to scan only projects subfolder when configured - prevents scanning brand root organizational folders (brand/, personas/, video-scripts/) as projects ([2c8d84c](https://github.com/appydave/appydave-tools/commit/2c8d84c70f783a0f87ff36cc1e79c00df668def5))

# [0.30.0](https://github.com/appydave/appydave-tools/compare/v0.29.0...v0.30.0) (2025-11-21)


### Features

* add Config.project_path utility method for DRY principle - update all DAM files to use centralized path resolution ([acd9b9a](https://github.com/appydave/appydave-tools/commit/acd9b9afb0b03af0bb980ab1208aacf9ed422267))

# [0.29.0](https://github.com/appydave/appydave-tools/compare/v0.28.0...v0.29.0) (2025-11-20)


### Features

* add comprehensive unit tests for recent S3 features - Zone.Identifier exclusion, download timing, project directory creation, and excluded_path helper ([2a2f35a](https://github.com/appydave/appydave-tools/commit/2a2f35acb1e3674c15860120f0cf60a3fe0fe6b2))
* add unit tests for projects_subfolder feature in S3Operations ([7b47ee2](https://github.com/appydave/appydave-tools/commit/7b47ee20e1f4326446833ccd87fbb441cbabba45))

# [0.28.0](https://github.com/appydave/appydave-tools/compare/v0.27.0...v0.28.0) (2025-11-20)


### Features

* add projects_subfolder setting to support organized brand structures - allows brands like SupportSignal to keep projects in a subfolder while AppyDave keeps them at root ([6e8ed69](https://github.com/appydave/appydave-tools/commit/6e8ed6951045b2d35c6d71c53ebcb32082704ade))

# [0.27.0](https://github.com/appydave/appydave-tools/compare/v0.26.0...v0.27.0) (2025-11-19)


### Features

* add comprehensive unit tests for recent S3 features - Zone.Identifier exclusion, download timing, project directory creation, and excluded_path helper ([70f1950](https://github.com/appydave/appydave-tools/commit/70f19502cdd6f7a5a95a6421850d5b5e4a17b79b))

# [0.26.0](https://github.com/appydave/appydave-tools/compare/v0.25.0...v0.26.0) (2025-11-19)


### Features

* exclude Windows Zone.Identifier files from upload and archive ([e018b6d](https://github.com/appydave/appydave-tools/commit/e018b6d9750394e38877421d49a9dd7d4319315c))

# [0.25.0](https://github.com/appydave/appydave-tools/compare/v0.24.0...v0.25.0) (2025-11-19)


### Features

* add download timing using shared format_duration helper ([c729792](https://github.com/appydave/appydave-tools/commit/c729792c89507e16ce4c51de55c7a05173da97e7))

# [0.24.0](https://github.com/appydave/appydave-tools/compare/v0.23.0...v0.24.0) (2025-11-19)


### Features

* create project directory before S3 download - fixes WSL permission denied error when downloading to non-existent projects ([5819a65](https://github.com/appydave/appydave-tools/commit/5819a658c7aae028107c00eebe073d9a100d246a))

# [0.23.0](https://github.com/appydave/appydave-tools/compare/v0.22.0...v0.23.0) (2025-11-19)


### Features

* use current user's AWS profile for S3 operations ([3029aff](https://github.com/appydave/appydave-tools/commit/3029aff202ac8ee4a79e335ea7f3cbc246c7dd54))
* use current user's AWS profile for S3 operations instead of brand-specific profiles ([8eea669](https://github.com/appydave/appydave-tools/commit/8eea669b43f6017470edfcac4632c8cc4cca408d))

# [0.22.0](https://github.com/appydave/appydave-tools/compare/v0.21.2...v0.22.0) (2025-11-19)


### Features

* fix remaining rubocop string literal issue ([a28b9be](https://github.com/appydave/appydave-tools/commit/a28b9bedc31777bf382ebdc54b0abd4e27b7609a))
* fix rubocop issues in S3 scanner implementation ([20e9d48](https://github.com/appydave/appydave-tools/commit/20e9d481843aa4ab622a3ce6e56ff1183e3bad27))
* implement S3 scanning to query AWS for actual file data ([f452f95](https://github.com/appydave/appydave-tools/commit/f452f9587ed94f25f100ff36682f9b9c4312b975))

## [0.21.2](https://github.com/appydave/appydave-tools/compare/v0.21.1...v0.21.2) (2025-11-17)


### Bug Fixes

* fix exe/dam wrapper to properly execute bin/dam by setting PROGRAM_NAME ([cec43c3](https://github.com/appydave/appydave-tools/commit/cec43c3489ab868d120293daebf3456819ae6b11))

## [0.21.1](https://github.com/appydave/appydave-tools/compare/v0.21.0...v0.21.1) (2025-11-17)


### Bug Fixes

* add dam executable to exe directory - required for gem installation ([301464f](https://github.com/appydave/appydave-tools/commit/301464f62d9c1f6572c5024ae7daa49e5b360a5e))

# [0.21.0](https://github.com/appydave/appydave-tools/compare/v0.20.1...v0.21.0) (2025-11-17)


### Bug Fixes

* create manifest for brands with no projects ([4fea6bd](https://github.com/appydave/appydave-tools/commit/4fea6bd47ac705b2875eb901737b3a11b905619f))
* improve range folder and SSD detection ([fc0f58b](https://github.com/appydave/appydave-tools/commit/fc0f58b44ed6bf484d8fec10f3d1c38f8caa5206))
* remove require 'pry' from bin scripts - not in gemspec dependencies, breaks gem install on fresh systems ([624c2a9](https://github.com/appydave/appydave-tools/commit/624c2a976fde3995423e4b6a147d57249bd98c15))
* rename predicate methods to end with ? - handle_empty_files and find_project_in_ssd_ranges ([2c6b188](https://github.com/appydave/appydave-tools/commit/2c6b188c55b866aa5465403fd60b18e116445fe0))
* rubocop and test fixes ([3580c47](https://github.com/appydave/appydave-tools/commit/3580c47f461e5681e91e679addf23c7706f9bfd7))
* use ProjectResolver as class method in status and repo_push ([c0c8535](https://github.com/appydave/appydave-tools/commit/c0c853572fef9dccedd544a31ee369d5c0efa886))


### Features

* add three-tier project type detection (storyline, flivideo, general) ([54ac404](https://github.com/appydave/appydave-tools/commit/54ac4045c8d3d49f63456de2dcfa9969f33169ea))

## [0.20.1](https://github.com/appydave/appydave-tools/compare/v0.20.0...v0.20.1) (2025-11-10)


### Bug Fixes

* remove noisy backup log message from self-healing config saves ([f9dacfd](https://github.com/appydave/appydave-tools/commit/f9dacfd74cce5f991c7f4bafb12d1494aa6ee4ab))

# [0.20.0](https://github.com/appydave/appydave-tools/compare/v0.19.0...v0.20.0) (2025-11-10)


### Features

* Phase 2: add unified status and git repo commands (status, repo-status, repo-sync, repo-push) ([c9ff7de](https://github.com/appydave/appydave-tools/commit/c9ff7dee9bd2d60954205df08c23dd673960a524))
* Phase 2: add unified status and git repo commands (status, repo-status, repo-sync, repo-push) ([b74f343](https://github.com/appydave/appydave-tools/commit/b74f3436e188cfa7dbdff386d35cb96d75f80860))

# [0.19.0](https://github.com/appydave/appydave-tools/compare/v0.18.5...v0.19.0) (2025-11-10)


### Features

* Phase 1: add git_remote, S3 tracking, and hasStorylineJson to manifest ([4622271](https://github.com/appydave/appydave-tools/commit/4622271a9e1a01a7145981db4837ed9b69e8f721))

## [0.18.5](https://github.com/appydave/appydave-tools/compare/v0.18.4...v0.18.5) (2025-11-10)


### Bug Fixes

* update test plan to reflect all DAM commands completed (manifest, archive, sync-ssd) and clarify git repo scripts ([ac1436a](https://github.com/appydave/appydave-tools/commit/ac1436a09c4ae32009f1b98dc697da9a87f1c4ee))

## [0.18.4](https://github.com/appydave/appydave-tools/compare/v0.18.3...v0.18.4) (2025-11-10)


### Bug Fixes

* document dry-run and force flag support for all DAM commands in usage guide and test plan ([b4f54da](https://github.com/appydave/appydave-tools/commit/b4f54da17589b31c029d5ef62c92af8b3724ee2f))

## [0.18.3](https://github.com/appydave/appydave-tools/compare/v0.18.2...v0.18.3) (2025-11-10)


### Bug Fixes

* resolve archived structure detection and range folder calculation for DAM manifest and sync ([dec1400](https://github.com/appydave/appydave-tools/commit/dec1400c561f11959fb6aecd7761e916ca525082))
* resolve rubocop violations in manifest_generator (refactor build_project_entry, simplify SSD check) ([ced61be](https://github.com/appydave/appydave-tools/commit/ced61be41c3da352831d46e3486968f5ee55842c))

## [0.18.2](https://github.com/appydave/appydave-tools/compare/v0.18.1...v0.18.2) (2025-11-10)


### Bug Fixes

* resolve Windows compatibility by removing hardcoded SSL certificate path ([fb4e6f7](https://github.com/appydave/appydave-tools/commit/fb4e6f74437e898229e1863f361d8ed4274a4ca6))

## [0.18.1](https://github.com/appydave/appydave-tools/compare/v0.18.0...v0.18.1) (2025-11-10)


### Bug Fixes

* add manifest summary showing all generated paths at once ([7f73ff9](https://github.com/appydave/appydave-tools/commit/7f73ff98b5f1e375633279c597c2d9265c278b37))
* refactor manifest command to reduce complexity for RuboCop ([99d9a85](https://github.com/appydave/appydave-tools/commit/99d9a8586ea86ead65c38ac54acf6755ee4f2664))

# [0.18.0](https://github.com/appydave/appydave-tools/compare/v0.17.1...v0.18.0) (2025-11-10)


### Features

* migrate VAT to DAM with comprehensive rename and case-insensitive brand resolution ([d776c68](https://github.com/appydave/appydave-tools/commit/d776c686e582e714c07fafa959c07327f1e0d36b))

## [0.17.1](https://github.com/appydave/appydave-tools/compare/v0.17.0...v0.17.1) (2025-11-10)


### Bug Fixes

* review and implement codex recomedations ([32811a0](https://github.com/appydave/appydave-tools/commit/32811a0d4e0deda0a7e94c74dacf38c1f67a0e44))

# [0.17.0](https://github.com/appydave/appydave-tools/compare/v0.16.0...v0.17.0) (2025-11-09)


### Bug Fixes

* disable RuboCop for standalone bin scripts ([80e0e6a](https://github.com/appydave/appydave-tools/commit/80e0e6ac4a7289707549bc3708d990c6805c17d5))
* documentation update ([5beb2b6](https://github.com/appydave/appydave-tools/commit/5beb2b65af3c3a256409c7a9067526df2c269851))
* exclude bin scripts from Naming/PredicateName cop ([1b5d363](https://github.com/appydave/appydave-tools/commit/1b5d3638f8d19a86752792f67e5b7a9ddce91c37))


### Features

* add manifest generator ([bc6a4f1](https://github.com/appydave/appydave-tools/commit/bc6a4f14fe90471cd96a1dbc7c5e2900db4f08bb))
* video asset tools - implement VAT (Digital Asset Management) for multi-brand video projects ([16f29fc](https://github.com/appydave/appydave-tools/commit/16f29fcf48d492747fbf82a203e0d81057385eb0))

# [0.16.0](https://github.com/appydave/appydave-tools/compare/v0.15.0...v0.16.0) (2025-11-08)


### Bug Fixes

* fix cops ([6c1d59b](https://github.com/appydave/appydave-tools/commit/6c1d59bd870af519825556f7304d6ca1677d8649))


### Features

* update documentation and general purpose rename and fixes via claude ([027c3df](https://github.com/appydave/appydave-tools/commit/027c3dff11e572359e6f2d1ebc17010dc3b8d7ee))

# [0.15.0](https://github.com/appydave/appydave-tools/compare/v0.14.1...v0.15.0) (2025-11-08)


### Features

* update claude and git leaks ([0b8212f](https://github.com/appydave/appydave-tools/commit/0b8212fa65a920c608876c4f4f37c166dc552039))

## [0.14.1](https://github.com/appydave/appydave-tools/compare/v0.14.0...v0.14.1) (2025-08-06)


### Bug Fixes

* updagte claude and readmegs ([308af2f](https://github.com/appydave/appydave-tools/commit/308af2f3085f6bfd054c9d12154da7055d47bb3b))

# [0.14.0](https://github.com/appydave/appydave-tools/compare/v0.13.0...v0.14.0) (2025-04-27)


### Bug Fixes

* 'cops' ([51bc6f2](https://github.com/appydave/appydave-tools/commit/51bc6f2e7bd08a3aff165e6d488f3f99c4ab7f45))
* ci ([11e934b](https://github.com/appydave/appydave-tools/commit/11e934b2f4f6be2457dea65c46b37ae350480b91))
* cops ([94817c6](https://github.com/appydave/appydave-tools/commit/94817c6ecc930dcb79a59fa7d6d977ba2aa197b9))
* update gem file ([9b0d21d](https://github.com/appydave/appydave-tools/commit/9b0d21d278a3c2bd6669122f33e55f084c76997b))


### Features

* update gem file ([b15dbcb](https://github.com/appydave/appydave-tools/commit/b15dbcbb13e0025f82ab54d8a87104d0d0fa4e14))

# [0.13.0](https://github.com/appydave/appydave-tools/compare/v0.12.0...v0.13.0) (2024-12-03)


### Features

* move subtitle_master to subtitle_manager ([1c2d968](https://github.com/appydave/appydave-tools/commit/1c2d9680dce943bdfa65ec6ee079b40abdbd3890))

# [0.12.0](https://github.com/appydave/appydave-tools/compare/v0.11.11...v0.12.0) (2024-12-03)


### Bug Fixes

* update cops ([0efed07](https://github.com/appydave/appydave-tools/commit/0efed07376a7fa8d460a3ab03264a82764245ebe))


### Features

* add srt-join tool ([0576ed4](https://github.com/appydave/appydave-tools/commit/0576ed44f330869760832875126dd1f4c2bfcbd1))

## [0.11.11](https://github.com/appydave/appydave-tools/compare/v0.11.10...v0.11.11) (2024-11-26)


### Bug Fixes

* update clean srt specs ([e0da656](https://github.com/appydave/appydave-tools/commit/e0da656a3bf04f094bc3726a588a59d99d3d24a8))

## [0.11.10](https://github.com/appydave/appydave-tools/compare/v0.11.9...v0.11.10) (2024-11-26)


### Bug Fixes

* Add future requirement docs for SRT ([29eb02d](https://github.com/appydave/appydave-tools/commit/29eb02de587c3e61f6b92a1690dc5a3c657c0a34))

## [0.11.9](https://github.com/appydave/appydave-tools/compare/v0.11.8...v0.11.9) (2024-11-26)


### Bug Fixes

* SRT cleaner can work with string or file ([ddd3bdc](https://github.com/appydave/appydave-tools/commit/ddd3bdc7d70606bba91d81a7cdd5a9d3e8e7b409))

## [0.11.8](https://github.com/appydave/appydave-tools/compare/v0.11.7...v0.11.8) (2024-11-26)


### Bug Fixes

* alter gemspec ([046b267](https://github.com/appydave/appydave-tools/commit/046b26727e2934ae0cecac38f48c18abaa61c91b))

## [0.11.7](https://github.com/appydave/appydave-tools/compare/v0.11.6...v0.11.7) (2024-11-26)


### Bug Fixes

* move appydave-tools from klueless-io to appydave ([2a6f359](https://github.com/appydave/appydave-tools/commit/2a6f359901922ecd098c0362be0feceb05f7429e))
* move appydave-tools from klueless-io to appydave ([b8cf441](https://github.com/appydave/appydave-tools/commit/b8cf441fbca008753ba9e81e100d3156e7242f11))
* move appydave-tools from klueless-io to appydave ([1347969](https://github.com/appydave/appydave-tools/commit/13479698b73c7aa140c6b10afde10650a1ccc58c))

## [0.11.6](https://github.com/appydave/appydave-tools/compare/v0.11.5...v0.11.6) (2024-10-16)


### Bug Fixes

* support expanded path [#2](https://github.com/appydave/appydave-tools/issues/2) ([062b0ff](https://github.com/appydave/appydave-tools/commit/062b0ffcc2813426af6359be99de5fd5e1d61376))

## [0.11.5](https://github.com/appydave/appydave-tools/compare/v0.11.4...v0.11.5) (2024-10-16)


### Bug Fixes

* support expanded path ([42e6c77](https://github.com/appydave/appydave-tools/commit/42e6c7794529adc9e1be8324f8f981e782347669))

## [0.11.4](https://github.com/appydave/appydave-tools/compare/v0.11.3...v0.11.4) (2024-10-16)


### Bug Fixes

* testing gem naming conventions [#2](https://github.com/appydave/appydave-tools/issues/2) ([102e9b7](https://github.com/appydave/appydave-tools/commit/102e9b7ed1deaeff094e21376675eabc6bdd022b))

## [0.11.3](https://github.com/appydave/appydave-tools/compare/v0.11.2...v0.11.3) (2024-10-16)


### Bug Fixes

* testing gem naming conventions ([393ffde](https://github.com/appydave/appydave-tools/commit/393ffde6b9daf2182260b50ad63453751d0bea6c))

## [0.11.2](https://github.com/appydave/appydave-tools/compare/v0.11.1...v0.11.2) (2024-10-16)


### Bug Fixes

* gpt context documentation updated for using from another gem ([a71072c](https://github.com/appydave/appydave-tools/commit/a71072ce24e61dd164f44d7425bad3013f0bdf1f))

## [0.11.1](https://github.com/appydave/appydave-tools/compare/v0.11.0...v0.11.1) (2024-10-16)


### Bug Fixes

* gpt context documentation ([808fccd](https://github.com/appydave/appydave-tools/commit/808fccdea10c472522da02c8af7f9a2c9eaf361a))

# [0.11.0](https://github.com/appydave/appydave-tools/compare/v0.10.4...v0.11.0) (2024-10-16)


### Bug Fixes

* gpt context improvements ([1a1db97](https://github.com/appydave/appydave-tools/commit/1a1db976317d1b6056d14e226a5635c3b7dea83d))


### Features

* gpt_context has improved options, this may break some previous calls ([21c984a](https://github.com/appydave/appydave-tools/commit/21c984a61d215da93783a3df55f10301cae55e1c))

## [0.10.4](https://github.com/appydave/appydave-tools/compare/v0.10.3...v0.10.4) (2024-10-09)


### Bug Fixes

* cleanup code base before building documenation ([e473c44](https://github.com/appydave/appydave-tools/commit/e473c44546d8f0f5a35461fae263c348e7e2c58f))
* cleanup code base before building documenation ([38d8fb4](https://github.com/appydave/appydave-tools/commit/38d8fb46929e7c055308aa0b918c18a56fcd5842))
* cleanup code base before building documenation ([8dad12a](https://github.com/appydave/appydave-tools/commit/8dad12aadb9952f0174df45caed91c9e96070294))
* cleanup code base before building documenation ([eddfcc7](https://github.com/appydave/appydave-tools/commit/eddfcc78e39c93bfd4de6482690cc66cf90cc54a))
* extend prompt tools ([a628d08](https://github.com/appydave/appydave-tools/commit/a628d08fcdda521b7d148f0bab3261b879fca07d))
* extending bank reconciliation ([b435a20](https://github.com/appydave/appydave-tools/commit/b435a20237ef40a8a7d0a4f365ccd3eafdfcce1a))
* extending bank reconciliation ([b7878df](https://github.com/appydave/appydave-tools/commit/b7878dff0bca4ff1a3af7db19c280a8c245b6c3b))

## [0.10.3](https://github.com/appydave/appydave-tools/compare/v0.10.2...v0.10.3) (2024-06-17)


### Bug Fixes

* extending bank reconciliation with platform and banking mapping ([848b044](https://github.com/appydave/appydave-tools/commit/848b044bf4bb7c27bae6cf33aba400ab68eb105c))

## [0.10.2](https://github.com/appydave/appydave-tools/compare/v0.10.1...v0.10.2) (2024-06-17)


### Bug Fixes

* make progress on prompt completion tool ([fbc60b7](https://github.com/appydave/appydave-tools/commit/fbc60b712e3e18d7f73c47f4568bae65295557df))

## [0.10.1](https://github.com/appydave/appydave-tools/compare/v0.10.0...v0.10.1) (2024-06-13)


### Bug Fixes

* add base model ([b2952d6](https://github.com/appydave/appydave-tools/commit/b2952d661c48dd7f8b7f384d365010ef89713758))

# [0.10.0](https://github.com/appydave/appydave-tools/compare/v0.9.5...v0.10.0) (2024-06-13)


### Bug Fixes

* cops ([ce8e657](https://github.com/appydave/appydave-tools/commit/ce8e657e4a167e7327d86782096bcf5e0a8e226e))


### Features

* starting the prompt tools component ([089043b](https://github.com/appydave/appydave-tools/commit/089043bca08dfb79a1b5f3741b55bb66f808adae))

## [0.9.5](https://github.com/appydave/appydave-tools/compare/v0.9.4...v0.9.5) (2024-06-13)


### Bug Fixes

* implement update video command ([c46473d](https://github.com/appydave/appydave-tools/commit/c46473dc550e34c041418adfd52444014e094917))

## [0.9.4](https://github.com/appydave/appydave-tools/compare/v0.9.3...v0.9.4) (2024-06-12)


### Bug Fixes

* move youtube management data to activemodel ([12d3351](https://github.com/appydave/appydave-tools/commit/12d3351b2243c436d0f59e2f2822d9d82cc6ebd6))

## [0.9.3](https://github.com/appydave/appydave-tools/compare/v0.9.2...v0.9.3) (2024-06-12)


### Bug Fixes

* preperation fo the youtube automation tool ([42c1e1d](https://github.com/appydave/appydave-tools/commit/42c1e1d3a4ea53491b72140bbf35850e41ce0f1c))
* update rubocop version number ([b64739d](https://github.com/appydave/appydave-tools/commit/b64739d46a5b3ea6177c2f7512c720b6ed4e6257))

## [0.9.2](https://github.com/appydave/appydave-tools/compare/v0.9.1...v0.9.2) (2024-06-11)


### Bug Fixes

* check for ci errors with openai ([2a9d549](https://github.com/appydave/appydave-tools/commit/2a9d549eb95246568ca54c1ec0fb9735cc26cac9))
* prepare openai for CI testing ([09c0d5a](https://github.com/appydave/appydave-tools/commit/09c0d5a998d00abb52eb3f09125bb955af1917d9))
* prepare openai for CI testing [#2](https://github.com/appydave/appydave-tools/issues/2) ([82247fc](https://github.com/appydave/appydave-tools/commit/82247fc2f421bd88859d25b0fbe88493b6e6d87e))

## [0.9.1](https://github.com/appydave/appydave-tools/compare/v0.9.0...v0.9.1) (2024-06-11)


### Bug Fixes

* youtube manager update console output ([c06c6cb](https://github.com/appydave/appydave-tools/commit/c06c6cb64f14cb0319c918cb6e1f4e65acd41f83))

# [0.9.0](https://github.com/appydave/appydave-tools/compare/v0.8.0...v0.9.0) (2024-06-07)


### Features

* youtube manageger -> getvideo by id, detail/content report ([1ad0f6f](https://github.com/appydave/appydave-tools/commit/1ad0f6f7b0d56a3de31869d632591ebfbf33119e))

# [0.8.0](https://github.com/appydave/appydave-tools/compare/v0.7.0...v0.8.0) (2024-06-06)


### Bug Fixes

* update bank reconciliation components ([0f5dea1](https://github.com/appydave/appydave-tools/commit/0f5dea1f75baced1458619ead3fc5bd5bc69e0d5))


### Features

* subtitle master for cleaning the SRT files created by whisper AI ([9f7bd37](https://github.com/appydave/appydave-tools/commit/9f7bd3795f4361e0615307874a88370ab49f97a7))
* subtitle master for cleaning the SRT files created by whisper AI ([0475a9e](https://github.com/appydave/appydave-tools/commit/0475a9ec07f2735e52ce54db6afa96e30e00c0e6))

# [0.7.0](https://github.com/appydave/appydave-tools/compare/v0.6.1...v0.7.0) (2024-05-29)


### Features

* new tool for doing bank reconciliations with chart of account matching ([9b82605](https://github.com/appydave/appydave-tools/commit/9b8260571f6046470d5963354ee1c80e493a0f28))

## [0.6.1](https://github.com/appydave/appydave-tools/compare/v0.6.0...v0.6.1) (2024-05-26)


### Bug Fixes

* improved configuration printing ([89d769d](https://github.com/appydave/appydave-tools/commit/89d769d0741fc75b44db90931cf981feea83027f))

# [0.6.0](https://github.com/appydave/appydave-tools/compare/v0.5.0...v0.6.0) (2024-05-26)


### Features

* refactor channels with locations, removed channel projects ([6b64574](https://github.com/appydave/appydave-tools/commit/6b645742b0029a001792c8d405dcae0b1036f2c0))

# [0.5.0](https://github.com/appydave/appydave-tools/compare/v0.4.1...v0.5.0) (2024-05-26)


### Features

* add configuration support for bank_reconciliation tool ([cfd6909](https://github.com/appydave/appydave-tools/commit/cfd6909d7c1de4c1acd9b84aaea28c9c7a07cc3f))

## [0.4.1](https://github.com/appydave/appydave-tools/compare/v0.4.0...v0.4.1) (2024-05-26)


### Bug Fixes

* move configuration models in to own namespace ([0a8dc48](https://github.com/appydave/appydave-tools/commit/0a8dc486c3f610a91dac1941bc986a1d5b05e24e))

# [0.4.0](https://github.com/appydave/appydave-tools/compare/v0.3.8...v0.4.0) (2024-05-26)


### Bug Fixes

* remove from ci for now ([e4c9e22](https://github.com/appydave/appydave-tools/commit/e4c9e225e6fe35a00a7b4d83ff9f2795da737589))
* remove from ci for now ([30a114c](https://github.com/appydave/appydave-tools/commit/30a114c7cd0085ab92aeb906e1962ca3618631e8))
* remove from ci for now ([7062c3d](https://github.com/appydave/appydave-tools/commit/7062c3d69634ab281107b755533f3332b708eb56))


### Features

* Add line limit option and update default format handling ([a0eb426](https://github.com/appydave/appydave-tools/commit/a0eb426329ee2a997081cf1a5c219c05d07ff824))

## [0.3.8](https://github.com/appydave/appydave-tools/compare/v0.3.7...v0.3.8) (2024-05-25)


### Bug Fixes

* update settings ([0b0c256](https://github.com/appydave/appydave-tools/commit/0b0c256793b607db87001752071b0476c6390c5f))

## [0.3.7](https://github.com/appydave/appydave-tools/compare/v0.3.6...v0.3.7) (2024-05-19)


### Bug Fixes

* add test for project_name generation ([3a87d9b](https://github.com/appydave/appydave-tools/commit/3a87d9b6f942e1b4e6576adaea58eaf799f5d74f))

## [0.3.6](https://github.com/appydave/appydave-tools/compare/v0.3.5...v0.3.6) (2024-05-19)


### Bug Fixes

* add default configuration and support for project name ([65d7c3e](https://github.com/appydave/appydave-tools/commit/65d7c3e8b05bbf9db4510762cccbd419ca988611))
* fix issue in CI[#1](https://github.com/appydave/appydave-tools/issues/1) ([867937e](https://github.com/appydave/appydave-tools/commit/867937e2ed271e4afe8dbbe3b3cee9d5ff15d986))

## [0.3.5](https://github.com/appydave/appydave-tools/compare/v0.3.4...v0.3.5) (2024-05-19)


### Bug Fixes

* add support for configurable ([82852f8](https://github.com/appydave/appydave-tools/commit/82852f805809b133278de70be24314e83a1d4b05))

## [0.3.4](https://github.com/appydave/appydave-tools/compare/v0.3.3...v0.3.4) (2024-05-19)


### Bug Fixes

* Add debug capability to ConfigBase and update configurations ([d33c943](https://github.com/appydave/appydave-tools/commit/d33c9431a50fa44b2f4db7ccbaf2522105710aa7))
* resolve cop ([d56f670](https://github.com/appydave/appydave-tools/commit/d56f670ec69ea74438947dd1bb7296e7fa28f0f1))

## [0.3.3](https://github.com/appydave/appydave-tools/compare/v0.3.2...v0.3.3) (2024-05-18)


### Bug Fixes

* updating configuration with channels and channel_folders  ([d4f54aa](https://github.com/appydave/appydave-tools/commit/d4f54aa0f455f535b6e265f23e6fba123d099d26))

## [0.3.2](https://github.com/appydave/appydave-tools/compare/v0.3.1...v0.3.2) (2024-05-16)


### Bug Fixes

* updating settings configuration and tests ([18bdf2b](https://github.com/appydave/appydave-tools/commit/18bdf2bb2605f51a5779dfe649c40e98c2bd77ef))
* updating settings configuration and tests ([487ce36](https://github.com/appydave/appydave-tools/commit/487ce366b857ce38ed91b35e4b6cc15a8ef56d35))

## [0.3.1](https://github.com/appydave/appydave-tools/compare/v0.3.0...v0.3.1) (2024-05-16)


### Bug Fixes

* add settings config to configuration component ([2c8afd1](https://github.com/appydave/appydave-tools/commit/2c8afd164fd6aa00fa47a01c9007c784a8adf820))

# [0.3.0](https://github.com/appydave/appydave-tools/compare/v0.2.0...v0.3.0) (2024-05-16)


### Features

* configuration component ([2bf26f6](https://github.com/appydave/appydave-tools/commit/2bf26f690da17b651977eab79e7a3cd37ed2a3b5))

# [0.2.0](https://github.com/appydave/appydave-tools/compare/v0.1.0...v0.2.0) (2024-05-14)


### Features

* gpt context gatherer ([00e2c34](https://github.com/appydave/appydave-tools/commit/00e2c343eb97a2c436b265861a912dccf803149d))

# [0.1.0](https://github.com/appydave/appydave-tools/compare/v0.0.2...v0.1.0) (2024-05-08)


### Features

* gpt context gatherer ([0c8089c](https://github.com/appydave/appydave-tools/commit/0c8089c60258a6032ea2b1fa0796a43cdd8f28c2))
* gpt context gatherer ([fe07156](https://github.com/appydave/appydave-tools/commit/fe0715699ad40379a1f0a1a99193d191a74e500b))

## [0.0.2](https://github.com/appydave/appydave-tools/compare/v0.0.1...v0.0.2) (2024-05-07)


### Bug Fixes

* update semantic dependency ([e76705e](https://github.com/appydave/appydave-tools/commit/e76705eb925f0be271884acc5af5119e3fa57325))
* update semantic dependency ([45623c4](https://github.com/appydave/appydave-tools/commit/45623c4575689ef1e813eb89bc9c55f3bf4d374f))
* update semantic dependency ([2ebb9bc](https://github.com/appydave/appydave-tools/commit/2ebb9bcb582b67b6bf4d8ccb6db9eff0e3b095e5))

## [Unreleased]

## [0.1.0] - 2024-05-07

- Initial release
