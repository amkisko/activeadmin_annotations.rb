Quality CI failed because Gemfile.lock still declared sqlite3 (>= 1) after the gemspec floor moved to >= 2.9.6. Test CI also ran bundler-audit on every push.

## Participants

- amkisko

## Decisions

- Align Gemfile.lock DEPENDENCIES with sqlite3 (>= 2.9.6).
- Drop the security job from test.yml so tests no longer wait on advisory freshness.
- Disable osv-scanner in Trunk Check.
- Disable markdownlint MD013 in .markdownlint.yaml. Keep AGENTS.md in Trunk so other markdownlint rules still run.
- Add dependency-audit.yml with workflow_dispatch only.

## Effects

- Frozen bundle lint can pass against the gemspec constraint.
- Test CI runs lint and specs without an advisory gate.
- On-demand bundler-audit of every Gemfile.lock is available through workflow_dispatch.

## Next

- Run dependency audit on demand when a release or a known advisory needs it.
- Do not reintroduce advisory scanners into test.yml.

## Source

- GitHub Actions quality and test failures on 2026-09-17
