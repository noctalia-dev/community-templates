# Karere

Themes the WhatsApp Web interface inside [Karere](https://github.com/tobagin/karere)
using the current Noctalia palette.

Requires Karere **4.4.0 or later**, which supports loading a custom `user.css`
stylesheet natively. This works with the regular native `karere` or
[`karere-bin`](https://aur.archlinux.org/packages/karere-bin) AUR packages;
the old `karere-custom-css` fork is no longer required.

Noctalia generates the stylesheet at:

- Native: `$XDG_CONFIG_HOME/io.github.tobagin.karere/user.css`
  (normally `~/.config/io.github.tobagin.karere/user.css`).

The path matches Karere's upstream `user_css_path()` implementation. Enable
Karere in Noctalia's community templates; no additional manual setup or hooks
are needed. The manifest checks for `/usr/bin/karere` so that the stylesheet
can be generated even before Karere has created its configuration directory.

Karere 4.4.1 loads `user.css` when WhatsApp Web loads, but **does not
automatically reload it after Noctalia changes the theme**. Press **Ctrl+R**
in Karere to refresh the page and apply the newly rendered colors.

The template affects WhatsApp Web content, not Karere's native GTK interface,
and supports both light and dark Noctalia palettes.
