# Testing

## Commands

Full suite (matches CI: parallel shards via Polyrun):

```bash
make test
```

Lint (RuboCop and RBS):

```bash
make lint
```

Focused runs:

```bash
bundle exec rspec spec/
```

See `polyrun.yml`. `make test` runs `hooks.before_suite` before specs.

## Layout

- `spec/` — unit and integration specs for lib, app models, and services
- `spec/dummy/` — minimal Rails app for ActiveRecord-backed specs

## Guidelines

- Test configuration and export macro behavior in this repo.
- Add or update specs before bugfixes; run `make lint && make test` before a PR.
- Coverage threshold: `config/polyrun_coverage.yml`; CI runs a separate `coverage` job with `POLYRUN_COVERAGE=1`.
