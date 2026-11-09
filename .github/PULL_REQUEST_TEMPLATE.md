<!-- If this PR is not ready for review yet, please mark it as Draft. -->

## Template

- **App:** <!-- e.g. Fuzzel -->
- **Template id (directory):** `<id>`
- [ ] New template
- [ ] Update to an existing template

## What it themes

<!-- Which config file(s) of the app get rendered, and what the user sees change. -->

## Testing

<!-- Test it as a user template first (see the README), then say what you ran. -->

- **App version tested:** <!-- e.g. fuzzel 1.11.0 -->
- [ ] Applied a dark theme and confirmed the app picked it up
- [ ] Applied a light theme and confirmed the app picked it up
- [ ] Re-applied twice and the app config is still correct (hooks are idempotent)

## Screenshots

For new templates and updates that change the app's appearance, attach screenshots of the app with the theme applied in both dark and light modes. If the app supports only one mode, include that mode and explain the limitation.

Screenshots are not required for nonvisual updates (for example, output paths, installation detection, hooks that do not change appearance, or documentation). State why the update is nonvisual below.

### Dark mode
<!-- Paste screenshot(s) here, or explain why not applicable. -->

### Light mode
<!-- Paste screenshot(s) here, or explain why not applicable. -->

## Hooks

<!-- Skip this section if the template has no pre_hook or post_hook. -->

- **What the hook does:** <!-- e.g. rewrites `theme = "..."` in the app's config so it points at the rendered file -->
- [ ] It is idempotent: running it twice does not duplicate lines or corrupt the config.
- [ ] It fails loudly (non-zero exit, message on stderr) when the app's config is missing.
- [ ] It downloads nothing and executes nothing it did not ship in this directory.
- [ ] It touches only this app's own config.

## Checklist

- [ ] The directory name matches the `[catalog.<id>]` id in `template.toml`.
- [ ] `category` is one of: `ai`, `audio`, `browser`, `chat`, `compositor`, `editor`, `gaming`, `launcher`, `system`, `terminal`, `misc`.
- [ ] Every `input_path` names a file that exists in this directory.
- [ ] A non-empty `README.md` documents what is themed, prerequisites, setup, output paths, and any hook side effects.
- [ ] No generated output or app-specific personal config is committed.
- [ ] Dark/light screenshots are included, or I explained why screenshots or a mode are not applicable.
