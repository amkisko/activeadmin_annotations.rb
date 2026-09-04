# JavaScript tests through Polyrun shards

## Decisions

JavaScript tests under spec/javascript are discovered by glob, written to a paths file, and fanned out with polyrun run-shards the same way RSpec uses spec/**/*_spec.rb.

polyrun.javascript.yml keeps that glob off the RSpec partition. make test, CI, and usr/bin/release.rb all run that command before parallel-rspec.

Matching names are *.{test,spec}.{mjs,js,cjs}. A single file still shards; empty extra workers skip.

Annotator helpers that Node can import live in app/assets/javascripts and are pinned as activeadmin_annotations/annotator_logic. Stimulus modules keep importmap specifiers, not relative paths.

## Effects

Makefile gained test-javascript. Node tests cover HTML escaping, create payload, saved highlight offset pairs, and whether custom highlights are present.

## Next

A later pass can add more helper files under the same glob.

## Source

polyrun.javascript.yml. Makefile. .github/workflows/test.yml. usr/bin/release.rb.
