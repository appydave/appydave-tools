# Quick Status

Provide a quick status summary of the AppyDave Tools project without deep codebase exploration.

## Instructions

Read the following files and provide a concise summary:

1. **Read** `CHANGELOG.md` (last 2-3 versions only)
2. **Read** `docs/backlog.md` if it exists (requirements table)
3. **Run** `git log --oneline -10` for recent commits
4. **Run** `git status` for current working state

## Output Format

```
## AppyDave Tools Status

### Current Version
- v0.X.Y (from CHANGELOG.md)

### Recently Completed
- [List last 3-5 features from CHANGELOG]

### In Progress / Pending
- [Any uncommitted changes from git status]
- [Any pending FRs from backlog if exists]

### Recent Commits
- [Last 5-7 commits from git log]

### Active Work Areas
- [Which systems have recent activity: DAM, GPT Context, etc.]

### Next Actions
- [What should happen next based on the current state]
```

## Notes

- Keep it brief - this is a status check, not a deep dive
- Use CHANGELOG.md as source of truth for version history
- Check git status for uncommitted work
- If you need more detail, suggest running `/po` or `/dev` for a full session

## Related Agents

- `/po` - Product Owner for requirements work
- `/dev` - Developer for implementation
- `/uat` - User acceptance testing
- `/brainstorming-agent` - Idea capture and clustering
