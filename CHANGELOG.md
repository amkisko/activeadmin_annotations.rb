# CHANGELOG

## 0.1.0 (2026-07-06)

- Add span-level annotations inside a bounded ActiveAdmin block.
- Add review and span models with JSONL export from the reviews index.
- Add Stimulus annotator and clipboard controllers with panel helper `activeadmin_annotations_panel`.
- Add optional content revision pinning (`:auto`, `:active_version`, custom resolvers).
- Add `ActiveAdmin::Annotations::Annotatable` concern for host models.
- Add configurable review admin menu visibility via `review_menu_visible`.
- Add PostgreSQL GIN index on review `metadata_json` for follow-up filtering.
