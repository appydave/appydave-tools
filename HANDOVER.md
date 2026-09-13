# HANDOVER — finish the `query_brain` fix: rebuild the index, prove it, run the suite

**Launch** (on Roamy, iTerm2):

```
cd /Users/davidcruwys/dev/ad/appydave-tools
```

```
claude --permission-mode auto --model 'claude-sonnet-5' -n aptools-dev "You must be running in /Users/davidcruwys/dev/ad/appydave-tools — verify your cwd before anything else and STOP if it differs. Run git pull first. Read /Users/davidcruwys/dev/ad/appydave-tools/HANDOVER.md in full, read its status stamp first and skip anything it records as landed, then execute it. STOP after query_brain finds creator-stack and report before touching anything else. Do not change query_brain's code again."
```

**Model:** Sonnet. The work is mechanical: rebuild, prove, run the suite.

---

## Status — updated 2026-09-13 on `roamy`

| Item | State |
|---|---|
| Index path `'audit'` → `'.audit'` (`options.rb`) | ✅ **LANDED — `6616fef`** (2026-09-10). Do not redo. |
| Dead `brain-librarian` hint → Lexi builder (`brain_finder.rb:57`) | ✅ **LANDED — `6616fef`**. Do not redo. |
| Spec that locked in the old path (`options_spec.rb`) | ✅ **LANDED — `6616fef`**, with a guard against pointing back at the `audit` brain. |
| rspec suite for these changes | **never run.** `6616fef` records that `spec_helper` failed to load in its shell (bundler/rbenv). |
| Index rebuild | **not started.** The index is dated 2026-09-10. |
| Proof with `--find creator-stack --meta` | **fails today: returns `[]`**. See below. |

**Measured on Roamy, 2026-09-13, after pulling `6616fef`:**
- `ruby bin/query_brain.rb --find cole-medin --meta` returns the `cole-medin` entry. The path fix works.
- `ruby bin/query_brain.rb --find creator-stack --meta` returns `[]`.
- **Cause:** `/Users/davidcruwys/dev/ad/brains/.audit/brains-index.json` was built 2026-09-10 12:28 and holds 0 mentions of
  `creator-stack`, whose `INDEX.md` says `created: 2026-09-11`. The index is simply older than the brain.

**Why this handover exists at all:** Roamy's checkout was one commit behind origin, so `query_brain` still raised.
A `git pull` fixed the code. The remaining gap is the stale index.

## Do

1. `git pull`. HEAD must contain `6616fef`.
2. Rebuild the index:
   `python3 /Users/davidcruwys/dev/ad/appydave-plugins/appydave/skills/lexi/scripts/build_brain_index.py build --all ~/dev/ad/brains`.
   It writes `/Users/davidcruwys/dev/ad/brains/.audit/brains-index.json`.
3. **Prove it:** `ruby /Users/davidcruwys/dev/ad/appydave-tools/bin/query_brain.rb --find creator-stack --meta` must return a JSON
   entry named `creator-stack`. Also re-run `--find cole-medin --meta` as a control.
4. Run the suite: `bundle exec rspec spec/appydave/tools/brain_context/`. If `spec_helper` still won't load, report the
   exact error. Don't fix the Ruby toolchain inside this session.
5. `.audit/brains-index.json` **is tracked** in the brains repo. Commit it there with an **explicit path**
   (`git add .audit/brains-index.json`, never `git add -A`, because other windows work in that repo), then push.
6. Update this stamp with the SHA and the rspec result, then commit this file here and push.

## Out of scope

- Any further change to `query_brain` or `query_omi` code.
- Lexi's builder.
- Brain content.
- The Ruby/bundler toolchain.
