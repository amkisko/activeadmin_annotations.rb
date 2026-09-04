# CHANGELOG

## Unreleased

- Create the review record when the first annotation is saved.
- Make the annotator read-only when browsing a content version other than the one under review.
- Show This version is read-only. when a save targets a different content version.
- Show Annotation access denied when a reviewer opens or changes another reviewer's annotation.
- Permit only status and notes on the review form.
- Copy annotation comment, offsets, and field.
- Install annotation tables on SQLite with json columns and on PostgreSQL with jsonb.
- Escape ordinary panel strings and sanitize html-safe host HTML.
- Show saved and pending marks when the browser has no custom highlight support.

## 0.1.1 (2026-07-14)

- Return forbidden responses with access-denied messages for cross-reviewer review and annotation mutations instead of not-found wording.

## 0.1.0 (2026-07-10)

- Add span-level annotations inside a bounded ActiveAdmin block.
- Add review and span models with JSONL export from the reviews index.
- Add Stimulus annotator and clipboard controllers with panel helper `activeadmin_annotations_panel`.
- Add `ActiveAdmin::Annotations::ReviewPanel` for revision pinning, stale banners, and advance-to-latest review flows.
- Add optional content revision pinning (`:auto`, `:active_version`, custom resolvers).
- Add `ActiveAdmin::Annotations::Annotatable` concern for host models.
- Add configurable review admin menu visibility via `review_menu_visible`.
- Add optional annotation categories and copy instructions via initializer settings.
- Add composite index on `annotation_spans` for panel load by review, field, and revision.
- Add PostgreSQL GIN index on review `metadata_json` for follow-up filtering.
