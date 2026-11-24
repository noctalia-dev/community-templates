# CachyOS Package Installer

Themes the [CachyOS Package Installer](https://github.com/CachyOS/packageinstaller) (`cachyos-pi`) with the Noctalia
palette: window, sidebar, cards, text, accent, and the Arch and error badges. Both the dark and the light palette are
written, so the app's own Light / Dark / Follow the desktop setting keeps working.

Only the surface, text, `primary`, `tertiary` and `error` tokens are used: they read well in every color scheme. The app
blends the rest from them (badge backgrounds, text on the accent, the banner on the start page) and keeps accent colors
readable on the cards, so schemes such as `faithful`, whose container colors do not pair with their `on_*` colors, look
right as well.

Enable **CachyOS Package Installer** in **Noctalia Settings -> Templates**. The theme is written to
`$XDG_CONFIG_HOME/CachyOS/cachyos-pi/themes/noctalia.json` (`~/.config/CachyOS/cachyos-pi/themes/noctalia.json` by
default). There is no hook, and nothing else is changed.

Then pick **Noctalia** under **Settings -> Colours** in the app, once. From then on a new wallpaper or palette changes the
app's colours at once, without a restart: the app watches its theme folder.

## Requirements

A version of `cachyos-pi` with theme files (the folder above), added in
[CachyOS/packageinstaller#167](https://github.com/CachyOS/packageinstaller/pull/167). The app creates that folder when it starts, and the
template is skipped until the folder exists, so start the app once after installing or updating it.

Tested with cachyos-pi 2.0.0 with that change and Noctalia 5.6.0, with the `m3-tonal-spot`,
`vibrant` and `faithful` schemes.
