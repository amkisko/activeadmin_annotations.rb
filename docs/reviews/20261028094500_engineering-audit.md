# Engineering audit and release check

## Decisions

- Review annotation access, browser assets, Rails integration, release flow, tests, CI, package contents, resource use, and identifying traces.
- Use the local Rails test application and Ruby 4.0.2 bundle. Do not treat the dummy application's policy as a host authorization policy.

## Effects

- Release confirmation: medium severity, high confidence, observed at usr/bin/release.rb. End of input previously passed the publish prompt. The focused spec failed before the fix and passed afterward. Entered empty lines still confirm.
- CI token scope: hardening note at .github/workflows/test.yml. The test workflow now has read-only contents permission; YAML parsing confirms the key. Its pull request trigger was already present.
- make test, including JavaScript tests, bundle check, git diff --check, gem build, and Gem::Package#verify passed. The built 0.1.3 gem has 46 files and is 30720 bytes.
- Cold require in a Rails and ActiveAdmin host fixture used 0.541 user CPU seconds, 0.393 system CPU seconds, and 82870272 bytes peak RSS on this machine. A standalone require without Rails boot fails because the engine expects Rails to be loaded. Package build used 0.095 user CPU seconds, 0.046 system CPU seconds, and 30654464 bytes peak RSS. These are one-run measurements without a stated production ceiling.
- Reviews and spans hold reviewer identifiers and annotation text. The gem has no independent network client; host request logs and browser traffic were not captured. Review visibility and subject authorization depend on the host's ActiveAdmin policy; a two-role host fixture would validate that policy. Browser accessibility and visual states need a running host surface.
- The second source and test pass found no further confirmed, fixable findings within the tested host contract.

## Next

- Run the full CI matrix and a host-policy test with two reviewer roles before publishing.

## Source

- admin/annotations.rb
- admin/annotation_reviews.rb
- lib/activeadmin/annotations/review_access.rb
- usr/bin/release.rb
- .github/workflows/test.yml
- spec/requests/annotation_spans_spec.rb
- spec/release_confirmation_spec.rb
