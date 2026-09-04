# Panel HTML sanitization and mark fallback

## Participants

- Andrei Makarov

## Decisions

- Escape ordinary panel strings. Sanitize html-safe host HTML with the Rails SafeList sanitizer already in the graph. Keep paragraphs. Strip scripts and event handlers.
- Keep custom highlight painting when the browser supports it. Otherwise wrap marks from offset pairs and recompute each range after a wrap.
- Split the annotator into selection, highlights, list, client, and composer modules. Pin each module on the importmap. Leave the Stimulus controller name unchanged.

## Effects

- Panel locals pass through ActiveAdmin::Annotations::PanelHtml.prepare before the view prints content.
- Saved and pending marks remain visible in browsers without custom highlight support.
- annotator_controller.js is Stimulus glue. Composer session, selection offsets, highlight painting, list items, and fetch live in sibling modules.

## Next

- Raise the coverage floor after the coverage CI job is measured with the new HTTP specs.

## Source

- usr/docs/issues/20260904144400_engineering-audit.md
- CHANGELOG.md 0.1.2
- lib/activeadmin/annotations/panel_html.rb
- app/helpers/active_admin/annotations/panel_helper.rb
- app/assets/controllers/activeadmin_annotations/annotator_controller.js
- app/assets/controllers/activeadmin_annotations/highlights.js
- README.md
