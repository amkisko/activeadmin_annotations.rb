# activeadmin_annotations

[![Gem Version](https://badge.fury.io/rb/activeadmin_annotations.svg)](https://badge.fury.io/rb/activeadmin_annotations) [![Test Status](https://github.com/amkisko/activeadmin_annotations.rb/actions/workflows/test.yml/badge.svg)](https://github.com/amkisko/activeadmin_annotations.rb/actions/workflows/test.yml)

Collect span-level text highlights and comments inside a bounded ActiveAdmin block.

The gem stays domain-agnostic: the host app chooses what review context means, which optional categories to offer, where to render the panel, and whether annotations are pinned to content revisions.

## Requirements

- Ruby 3.2+
- Rails 7.1+
- ActiveAdmin 3.0+
- PostgreSQL recommended for production (SQLite works for development; some metadata filters use Postgres JSON operators)

## Host app setup

Subject models and the reviewer model should use UUID primary keys. Migrations store `subject_id` and `reviewer_id` as UUIDs.

Set the reviewer model in the initializer:

```ruby
ActiveAdmin::Annotations.reviewer_class_name = "User"
```

The reviewer must be available as `current_user` (or your ActiveAdmin authentication helper) when the panel renders.

The Review admin menu item is visible when `review_menu_visible` returns true for the signed-in user. Default checks `user.administrator?`. Override in the initializer:

```ruby
ActiveAdmin::Annotations.review_menu_visible = ->(user) { user&.can_review_annotations? }
```

## Installation

Add to your Gemfile:

```ruby
gem "activeadmin_annotations"
```

Then:

```bash
bundle install
rails activeadmin_annotations:install:migrations
rails db:migrate
```

Configure the reviewer model and optional categories:

```ruby
# config/initializers/activeadmin_annotations.rb
ActiveAdmin::Annotations.reviewer_class_name = "User"
ActiveAdmin::Annotations.review_menu_visible = ->(user) { user&.administrator? }
ActiveAdmin::Annotations.category_label = "Category"
ActiveAdmin::Annotations.categories = {
  "needs_follow_up" => "Needs follow-up"
}
ActiveAdmin::Annotations.copy_instructions = <<~TEXT
  These annotations capture span-level review notes for evaluation datasets.
TEXT
```

`copy_instructions` can be a string or a callable `(annotation, review) -> string`.
It is prepended to the text copied from the annotation show page.

## Host model

```ruby
class Article < ApplicationRecord
  include ActiveAdmin::Annotations::Annotatable
end
```

## ActiveAdmin panel (basic, no content revisions)

When the subject does not use content revisions, render the panel directly:

```ruby
text_node helpers.activeadmin_annotations_panel(
  subject: resource,
  field: :body,
  context: {title: resource.title, author: resource.author_name},
  context_panels: [
    {title: "Metadata", content: JSON.pretty_generate(resource.metadata)}
  ],
  content: markdown(resource.body)
)
```

The gem stores annotations against the live subject text. If the reviewed text changes, stale detection uses `context_digest` only. No version UI is shown.

## Content revisions (optional)

Annotations use character offsets. If reviewed text can change in place, pin annotations to a content revision.

The gem does not depend on `active_version`. Revisions are optional and disabled unless:

- `content_revision_strategy` is `:active_version` or `:auto` (default), and the subject model uses `has_revisions` from [active_version](https://github.com/amkisko/active_version.rb), or
- you provide custom revision resolvers (below).

### Using active_version (recommended when content changes)

`active_version` is not a gem dependency. When present on a subject, the gem follows this convention:

- `subject.class.has_revisions?` is true
- `subject.current_version` returns the head revision number
- `subject.at_version(number)` returns a read-only copy at that revision

Pinned version `N` on the head `H` resolves content as:

- `N == H` → live `subject`
- `N < H` → `subject.at_version(N + 1)` (active_version stores the previous text in the next revision row)

Setup in the host app:

```bash
rails g active_version:revisions Article
rails db:migrate
```

```ruby
class Article < ApplicationRecord
  include ActiveAdmin::Annotations::Annotatable
  has_revisions(only: %i[title body])
end
```

Then either render the panel through `ActiveAdmin::Annotations::ReviewPanel` (handles pinning, stale state, and version filtering):

```ruby
text_node ActiveAdmin::Annotations::ReviewPanel.render(
  subject: resource,
  reviewer: current_user,
  field: :body,
  view_context: self,
  context_builder: ->(content_subject) { {title: content_subject.title} },
  content_builder: ->(content_subject) { markdown(content_subject.body) },
  advance_review_url: advance_annotation_review_admin_article_path(resource)
)
```

Wire the stale-banner action on the host subject resource:

```ruby
# app/admin/articles.rb
ActiveAdmin.register Article do
  member_action :advance_annotation_review, method: :post do
    context = {title: resource.title, body: resource.body}
    ActiveAdmin::Annotations::ReviewService.advance_to_latest!(
      subject: resource,
      reviewer: current_user,
      context: context,
      latest_content_revision_version: resource.current_version
    )
    redirect_to resource_path, notice: "Review moved to the latest content version."
  end
end
```

Pass the same path helper to `ReviewPanel.render` as `advance_review_url`. The panel shows the button only when the review is stale and a URL is present.

Or pass revision options manually to `activeadmin_annotations_panel`.

Enable active_version detection explicitly:

```ruby
ActiveAdmin::Annotations.content_revision_strategy = :active_version
```

### Custom revision backend (no active_version)

Disable auto-detection and provide callables (use `:auto`, not `:none`):

```ruby
ActiveAdmin::Annotations.content_revision_strategy = :auto

ActiveAdmin::Annotations.current_content_revision_version = lambda do |subject|
  subject.published_version
end

ActiveAdmin::Annotations.content_subject_for_revision = lambda do |subject, version|
  subject.versions.find_by!(number: version)
end
```

With custom resolvers, revision mode is enabled even without `active_version`.

### Revision configuration reference

- `content_revision_strategy` — `:auto` (default), `:active_version`, or `:none` / `false`
- `current_content_revision_version` — `(subject) -> Integer` override for head version
- `content_subject_for_revision` — `(subject, version) -> Object` override for rendered content
- `content_revision_label` — `false`, format string (`"Draft %{version}"`), or `(version) -> String`
- `stale_content_review_message` — string (`%{pinned_version}`, `%{latest_version}`) or `(review, pinned_version:, latest_version:)`
- `stale_context_message` — string or `(review)` when revisions are off but `context_digest` changed

Disable all revision UI and logic:

```ruby
ActiveAdmin::Annotations.content_revision_strategy = :none
```

## Storage

- `ActiveAdmin::Annotations::Review` — one row per subject + reviewer, with frozen `context_json`
- `ActiveAdmin::Annotations::Annotation` — span highlights tied to a review and field name
- `content_revision_version` — optional pin when revision mode is enabled (defaults to `0`)

## Export

ActiveAdmin registers review and span resources. Use the Export JSONL action on the reviews index for downstream tooling.

## Theme customization

The panel loads `activeadmin_annotations.css` and uses stable `aa-annotations-*` class names. Action buttons use ActiveAdmin's `action-item-button` so they inherit your admin chrome; colors, spacing, borders, and text highlights are overridden in the host app.

### Override styles

Add a host stylesheet that loads after the gem asset (for example in your ActiveAdmin layout or `app/assets/stylesheets/active_admin/`):

```css
/* app/assets/stylesheets/active_admin/custom_annotations.css */
.aa-annotations-sidebar {
  border-color: var(--border-color, #e5e7eb);
}

.aa-annotations-save-button {
  background-color: var(--primary, #2563eb);
  border-color: var(--primary, #2563eb);
}

::highlight(aa-annotations-saved) {
  background-color: color-mix(in srgb, var(--primary, #2563eb) 30%, #fef08a);
}

::highlight(aa-annotations-pending) {
  background-color: color-mix(in srgb, var(--primary, #2563eb) 40%, #fef08a);
  text-decoration-color: var(--primary, #2563eb);
}
```

Gem defaults include `.dark .aa-annotations-*` rules for ActiveAdmin 4 dark mode. Mirror host overrides under `.dark` when you change light-mode colors.

Main layout hooks: `.aa-annotations-panel`, `.aa-annotations-layout`, `.aa-annotations-sidebar`, `.aa-annotations-annotatable`, `.aa-annotations-composer`, `.aa-annotations-stale-banner`.

### Override partials

Copy views from the gem into `app/views/active_admin/annotations/`:

- `_panel.html.erb` — review UI and composer
- `_read_only_content.html.erb` — content-only fallback when no reviewer is signed in
- `_copy_details_action.html.erb` — copy action on the span show page

Override `_panel.html.erb` when you need different markup or to pin a custom Stimulus controller on the annotator root.

## Authorization

The gem registers ActiveAdmin resources for reviews and spans. Member actions use your host authorization adapter.

Span create, update, destroy, and copy actions verify that the signed-in reviewer owns the target review. Host policies should still gate who may access annotation resources at all (`create?`, `update?`, `destroy?`, `show?`).

With [ActionPolicy](https://github.com/palkan/action_policy) (or ActiveAdmin's ActionPolicy adapter), allow the span Copy details action explicitly:

```ruby
# app/policies/active_admin/annotations/annotation_policy.rb
class ActiveAdmin::Annotations::AnnotationPolicy < ApplicationPolicy
  def copy_text?
    show?
  end
end
```

Review resources use the usual CRUD predicates (`index?`, `show?`, `create?`, `update?`) from your app policy base class.

Place policies under `app/policies/active_admin/annotations/` so Zeitwerk maps them to `ActiveAdmin::Annotations::*Policy`.

## Dependencies

Required:

- Rails >= 7.1
- ActiveAdmin >= 3.0

Optional (host app):

- `active_version` for revision snapshots — not bundled; follow active_version setup when content can regenerate

## Development

From the gem root:

```bash
bundle install
bundle exec appraisal install
bundle exec rubocop
bundle exec polyrun parallel-rspec --workers 5 --merge-failures
```

Matrixed Rails versions use [Appraisal](https://github.com/thoughtbot/appraisal): `gemfiles/rails72.gemfile`, `rails8ruby34.gemfile`, and `rails8truffleruby.gemfile`. Run `bundle exec appraisal rspec` to execute RSpec in each gemfile context.

Shared agent guidance is managed with [pray](https://github.com/kiskolabs/pray) via `Prayfile`.

[Trunk](https://docs.trunk.io) config lives in `.trunk/`; CI can run `trunk` via `.github/workflows/_trunk_check.yml`. Releases: `make release` or `usr/bin/release.rb`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and pull requests are welcome at https://github.com/amkisko/activeadmin_annotations.rb/issues

## License

MIT — see [LICENSE.md](LICENSE.md).

## Sponsors

Sponsored by [Kisko Labs](https://www.kiskolabs.com).

<a href="https://www.kiskolabs.com">
  <img src="kisko.svg" width="200" alt="Sponsored by Kisko Labs" />
</a>
