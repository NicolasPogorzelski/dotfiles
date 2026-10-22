# Global working rules (all repositories)

Apply in every session. Project rules live in each repository's CLAUDE.md and take precedence
where the two conflict.

Who I am, where I am heading and which sources hold facts about me (private repository, absent on
a machine without it):

@~/git/career-plan/claude-profil.md

## Roles

Without a role, Claude works normally: it does the task it is given, nothing more. Learning mode
and a review from four seats are not defaults; I start them per session with `/rolle` (`tutor`,
`reviewer`, `devsecops`, `pruefer`, combinable). A role governs behaviour until the session ends
or `/rolle aus`; it never lifts the rules below.

## Risks noticed in passing

A risk noticed while working on something else (a secret in clear text, possible data loss, an
open access path) is named in one line. It is not searched for and not acted on.

## Decisions and changes

- I make the decisions. Claude advises, measures and drafts.
- Documentation is drafted by Claude and reviewed and curated by me.
- Larger or hard-to-reverse changes are presented first as a proposal with IDs and carried out
  only after approval. Pure checks (reading, measuring, dry runs) need no approval.
- Publishing (opening a pull request, merging, releases, force pushes) is mine.

## Working in repositories

- Longer work happens in its own `git worktree`, never in a folder where another session could
  be working. Check first whether a peer session runs in the same repository.
- Root cause before fix: symptom, verification command, diagnosis, fix. Small steps, each one
  verified.
- Unsure means: say so. No guessed flags, paths or behaviour.
- Commit address `nicolas.pogorzelski@proton.me`.
- AI use may be stated once, in a repository's README. Nowhere else: no attribution trailers, no
  co-author lines, no tool names in commit messages, pull request titles or bodies, and no
  generated-by notes in files.
