# rhun – Noctalia Theme

Applies Noctalia's active palette to [rhun](https://rhun.app) — a fast, native, assembly-written code editor.

One theme is provided:

| Theme file       | Config name |
| ---------------- | ----------- |
| `noctalia.theme` | `noctalia`  |

## What gets themed

| Area                | Keys                                                                                                                                                                                                                  |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Core UI**         | `bg`, `fg`, `accent`, `accent_fg`                                                                                                                                                                                     |
| **Panels / chrome** | `panel`, `panel_fg`, `border`, `titlebar`                                                                                                                                                                             |
| **Editor**          | `selection`, `line_highlight`, `line_number`, `line_number_active`, `cursor`, `muted`                                                                                                                                 |
| **States**          | `hover`, `active`, `popup`, `input`, `scrollbar`, `match`, `guide`                                                                                                                                                    |
| **Status**          | `error`, `warning`, `success`                                                                                                                                                                                         |
| **Git gutter**      | `git_added`, `git_modified`, `git_deleted`                                                                                                                                                                            |
| **Extensions**      | `inlay`, `inlay_bg`, `ghost`, `codelens`, `highlight`, `highlight_write`, `info`, `hint`                                                                                                                              |
| **File icons**      | 10 icon color roles                                                                                                                                                                                                   |
| **Syntax**          | `keyword`, `type`, `function`, `string`, `number`, `comment`, `constant`, `operator`, `punctuation`, `preproc`, `builtin`, `variable`, `attribute`, `tag`, `heading`, `escape`, `link`, `inserted`, `deleted`, `text` |
| **Terminal**        | Full 16-color palette                                                                                                                                                                                                 |

## Selecting the theme in rhun

Open the theme picker with **Ctrl+K Ctrl+T**, or set it in `~/.config/rhun/config`:

```ini
[ui]
dark_theme  = noctalia
light_theme = noctalia
```

## Color mapping (feedback palette · dark)

| Role                                 | Noctalia token            |
| ------------------------------------ | ------------------------- |
| Background                           | `surface`                 |
| Foreground                           | `on_surface`              |
| Accent / cursor / function / heading | `primary`                 |
| Keyword                              | `terminal_normal_magenta` |
| String                               | `terminal_normal_green`   |
| Comment                              | `terminal_bright_black`   |
| Number                               | `terminal_normal_yellow`  |
| Operator                             | `terminal_normal_cyan`    |
| Type                                 | `terminal_bright_blue`    |
| Constant                             | `terminal_bright_magenta` |
| Builtin                              | `terminal_bright_cyan`    |
| Attribute / secondary                | `secondary`               |
| Tag / tertiary                       | `tertiary`                |
| Preproc                              | `terminal_bright_red`     |
| Escape                               | `terminal_bright_yellow`  |
| Error                                | `terminal_normal_red`     |
| Warning                              | `terminal_normal_yellow`  |
| Success / git_added                  | `terminal_normal_green`   |
