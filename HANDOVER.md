# HANDOVER — fix `query_brain`'s index path

**Launch** (on Roamy, iTerm2):

```
cd /Users/davidcruwys/dev/ad/appydave-tools
```

```
claude --permission-mode auto --model 'claude-sonnet-5' -n aptools-dev "You must be running in /Users/davidcruwys/dev/ad/appydave-tools — verify your cwd before anything else and STOP if it differs. Read /Users/davidcruwys/dev/ad/appydave-tools/HANDOVER.md in full and execute it. STOP after the fix is pushed and query_brain returns a result, and report before touching anything else. Do not change query_brain's behaviour beyond the index path and the error message."
```

**Model:** Sonnet. This is a mechanical two-line fix with a known cause.

---

## Status — written 2026-09-13 on `roamy`

| Item | State |
|---|---|
| Index path fix | not started |
| Error-message fix | not started |
| Index rebuild | not started. The existing index is dated 2026-09-10. |

## The defect (measured 2026-09-13)

`query_brain --find <x>` fails with `brains-index.json not found at /Users/davidcruwys/dev/ad/brains/audit/brains-index.json`.

- **The index exists**, at `/Users/davidcruwys/dev/ad/brains/.audit/brains-index.json` (with a dot).
- **The builder writes there:** `/Users/davidcruwys/dev/ad/appydave-plugins/appydave/skills/lexi/scripts/build_brain_index.py`
  line 269, `brains_root / '.audit' / 'brains-index.json'`.
- **The reader looks elsewhere:** `lib/appydave/tools/brain_context/options.rb:49` builds
  `File.join(brains_root, 'audit', 'brains-index.json')`.
- **Likely origin:** the brains repo split its `audit/` folder on 2026-05-12 (`a5bb3c2f`), and `query_brain`
  was never updated.
- **The error message is also stale:** `lib/appydave/tools/brain_context/brain_finder.rb:57` tells you to run
  `~/dev/ad/brains/.claude/skills/brain-librarian/scripts/build_brain_index.py`, and that path is dead.

## Do

1. In `/Users/davidcruwys/dev/ad/appydave-tools/lib/appydave/tools/brain_context/options.rb:49`, change `'audit'` to `'.audit'`.
2. In `/Users/davidcruwys/dev/ad/appydave-tools/lib/appydave/tools/brain_context/brain_finder.rb:57`, point the message at
   `python3 /Users/davidcruwys/dev/ad/appydave-plugins/appydave/skills/lexi/scripts/build_brain_index.py build --all ~/dev/ad/brains`.
3. Update any spec that asserts the old path. Check `spec/appydave/tools/brain_context/options_spec.rb` and
   `brain_query_spec.rb`.
4. Rebuild the index:
   `python3 /Users/davidcruwys/dev/ad/appydave-plugins/appydave/skills/lexi/scripts/build_brain_index.py build --all ~/dev/ad/brains`.
   It writes `/Users/davidcruwys/dev/ad/brains/.audit/brains-index.json`.
5. **Prove it:** `ruby /Users/davidcruwys/dev/ad/appydave-tools/bin/query_brain.rb --find creator-stack --meta` must
   return a JSON entry for `creator-stack`. The shell alias `query_brain` points at this same file, so no gem
   release is needed for local use.
6. Run `bundle exec rspec spec/appydave/tools/brain_context/` and `bundle exec rubocop` on the changed files. CI runs
   an unpinned rubocop, so a green local run is not proof that CI will pass.
7. Commit with **explicit paths** (never `git add -A`) and push. If `.audit/brains-index.json` is tracked in the brains
   repo, commit it there too, by explicit path. Then update this stamp with the SHA(s).

## Out of scope

- Any other `query_brain` or `query_omi` behaviour.
- Lexi's builder.
- Brain content.
