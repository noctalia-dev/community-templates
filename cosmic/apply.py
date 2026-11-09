#!/usr/bin/env python3
"""Write Noctalia's palette into the COSMIC (libcosmic) theme configuration.

Applies the colors rendered into ``$XDG_CACHE_HOME/noctalia/cosmic-palette``
to every libcosmic application (cosmic-files, cosmic-edit, cosmic-term, ...).

COSMIC stores two kinds of config, and this script writes both:

``com.system76.CosmicTheme.<Mode>``
    The derived ``cosmic_theme::Theme`` that libcosmic reads at startup. This is
    the file set ``cosmic-settings`` itself persists after building a theme, so
    writing it here is equivalent to picking the theme in Settings.

``com.system76.CosmicTheme.<Mode>.Builder``
    The palette and inputs ``cosmic-settings`` edits. Apps do not read it, but
    keeping it in sync means a later ``cosmic-settings`` install shows this as
    a real custom theme instead of the built-in default.

``com.system76.CosmicTheme.Mode``
    ``is_dark`` selects which of the two derived themes apps load.

Color encoding matches cosmic-config v2: hex ``#RRGGBBAA`` inside
``Component``/``Container``/``palette``/``shade``, and the ``Rgb``/``Rgba``
struct form for ``Option<color>`` fields (libcosmic rejects hex there).

Usage: apply.py [dark|light]
"""

from __future__ import annotations

import os
import sys

# COSMIC themes this script owns. Each entry is (mode, CamelCase suffix).
MODES = (("dark", "Dark"), ("light", "Light"))


# --------------------------------------------------------------------------- #
# palette input
# --------------------------------------------------------------------------- #
def read_palette(path: str) -> dict[str, str]:
    palette: dict[str, str] = {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            palette[key.strip()] = value.strip()
    return palette


def normalize(value: str) -> str:
    value = value.strip().lstrip("#")
    return value[:6] if len(value) >= 6 else "000000"


def lookup(palette: dict[str, str], mode: str, key: str, *fallbacks: str) -> str:
    for candidate in (key, *fallbacks):
        raw = palette.get(f"{mode}_{candidate}")
        if raw and not raw.startswith("{{"):
            return normalize(raw)
    return "000000"


# --------------------------------------------------------------------------- #
# color helpers
# --------------------------------------------------------------------------- #
def rgb(value: str) -> tuple[int, int, int]:
    value = (value + "000000")[:6]
    return int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)


def clamp(value: float) -> int:
    return max(0, min(255, round(value)))


def mix(value: str, amount: float) -> str:
    """Lighten toward white, or darken toward black when ``amount`` is negative."""
    red, green, blue = rgb(value)
    factor = abs(amount)
    if amount >= 0:
        red, green, blue = (
            clamp(red + (255 - red) * factor),
            clamp(green + (255 - green) * factor),
            clamp(blue + (255 - blue) * factor),
        )
    else:
        red, green, blue = (
            clamp(red * (1 - factor)),
            clamp(green * (1 - factor)),
            clamp(blue * (1 - factor)),
        )
    return "%02X%02X%02X" % (red, green, blue)


def over(foreground: str, alpha: float, background: str) -> str:
    """Composite ``foreground`` at ``alpha`` over ``background``."""
    fr, fg, fb = rgb(foreground)
    br, bg, bb = rgb(background)
    return "%02X%02X%02X" % (
        clamp(fr * alpha + br * (1 - alpha)),
        clamp(fg * alpha + bg * (1 - alpha)),
        clamp(fb * alpha + bb * (1 - alpha)),
    )


def color(value: str, alpha: int = 255) -> str:
    """Serialize an Srgba/Srgb the way cosmic-config v2 does: #RRGGBBAA."""
    red, green, blue = rgb(value)
    return '"#%02X%02X%02X%02X"' % (red, green, blue, alpha)


def unit(component: int) -> str:
    return "%.8f" % (component / 255.0)


def some_rgb(value: str) -> str:
    red, green, blue = rgb(value)
    return "Some((red: %s, green: %s, blue: %s))" % (
        unit(red),
        unit(green),
        unit(blue),
    )


def some_rgba(value: str, alpha: int = 255) -> str:
    red, green, blue = rgb(value)
    return "Some((red: %s, green: %s, blue: %s, alpha: %s))" % (
        unit(red),
        unit(green),
        unit(blue),
        unit(alpha),
    )


# --------------------------------------------------------------------------- #
# cosmic theme primitives
# --------------------------------------------------------------------------- #
def component(
    base: str,
    on: str,
    accent: str,
    border: str,
    dark: bool,
    *,
    divider: float = 0.20,
    hover: float = 0.10,
    pressed: float = 0.20,
) -> str:
    """Build a cosmic_theme::Component.

    cosmic lightens interactive surfaces in dark mode and darkens them in light
    mode, then composites dividers/disabled text against the base color.
    """
    overlay = "FFFFFF" if dark else "000000"
    hovered = over(overlay, hover, base)
    pressed_color = over(overlay, pressed, base)
    return (
        "( base: %s, hover: %s, pressed: %s, selected: %s, selected_text: %s, "
        "focus: %s, divider: %s, on: %s, disabled: %s, on_disabled: %s, "
        "border: %s, disabled_border: %s )"
    ) % (
        color(base),
        color(hovered),
        color(pressed_color),
        color(hovered),
        color(accent),
        color(accent),
        color(over(on, divider, base)),
        color(on),
        color(base, 128),
        color(over(on, 0.65, base)),
        color(border),
        color(border, 128),
    )


def overlay_color(dark: bool, *alphas: float) -> str:
    """Serialize a neutral state overlay at the given opacity.

    Successive alphas composite over the previous colour (alpha-over), which is
    how iced draws a hover/pressed overlay on top of an existing background.
    """
    value = 0.0
    for alpha in alphas:
        value = alpha + value * (1.0 - alpha)
    return color("FFFFFF" if dark else "000000", clamp(value * 255))


def overlay_component(
    on: str,
    accent: str,
    dark: bool,
    *,
    base: float = 0.0,
    hover: float = 0.10,
    pressed: float = 0.20,
) -> str:
    """Build a Component that lets whatever is behind it show through.

    libcosmic paints ``Button::Icon``/``Button::HeaderBar`` as
    ``icon_button.base`` inside a ``radius_xl`` box, so an opaque base turns
    every titlebar control into a filled circle. Upstream COSMIC therefore keeps
    these bases transparent and lets the composited state overlays carry hover
    and press, which is also how Adwaita/Nautilus keep headerbar buttons flat.
    """
    return (
        "( base: %s, hover: %s, pressed: %s, selected: %s, selected_text: %s, "
        "focus: %s, divider: %s, on: %s, disabled: %s, on_disabled: %s, "
        "border: %s, disabled_border: %s )"
    ) % (
        overlay_color(dark, base),
        overlay_color(dark, hover, base),
        overlay_color(dark, pressed, base),
        overlay_color(dark, hover, base),
        color(accent),
        color(accent),
        overlay_color(dark, 0.20, base),
        color(on),
        overlay_color(dark, base),
        color(on, 153),
        overlay_color(dark, base),
        overlay_color(dark, base),
    )


def container(
    base: str,
    on: str,
    accent: str,
    border: str,
    dark: bool,
    *,
    bump: float = 0.05,
) -> str:
    """Build a cosmic_theme::Container."""
    direction = 1 if dark else -1
    return (
        "( base: %s, component: %s, divider: %s, on: %s, small_widget: %s )"
    ) % (
        color(base),
        component(mix(base, direction * bump), on, accent, border, dark),
        color(over(on, 0.20, base)),
        color(on),
        color(base, 64),
    )


# Values cosmic ships by default, reproduced so a partial palette never produces
# a malformed config.
SPACING = (
    "( space_none: 0, space_xxxs: 4, space_xxs: 8, space_xs: 12, space_s: 16, "
    "space_m: 24, space_l: 32, space_xl: 48, space_xxl: 64, space_xxxl: 128 )"
)
CORNER_RADII = (
    "( radius_0: (0.0, 0.0, 0.0, 0.0), radius_xs: (4.0, 4.0, 4.0, 4.0), "
    "radius_s: (8.0, 8.0, 8.0, 8.0), radius_m: (16.0, 16.0, 16.0, 16.0), "
    "radius_l: (32.0, 32.0, 32.0, 32.0), radius_xl: (160.0, 160.0, 160.0, 160.0) )"
)
ALPHA_MAP = (
    "( extremely_low: 0.9, extremely_low_2: 0.87692, very_low: 0.85385, "
    "very_low_2: 0.83076, low: 0.80769, low_2: 0.78461, medium: 0.76154, "
    "medium_2: 0.73846, high: 0.71538, high_2: 0.69231, very_high: 0.66023, "
    "very_high_2: 0.64615, extremely_high: 0.62308, extremely_high_2: 0.6 )"
)


def neutral_ramp(palette: dict[str, str], mode: str) -> list[str]:
    """Return COSMIC's 11-step neutral ramp (0 = darkest).

    Noctalia exposes a mode-independent tonal neutral ramp; COSMIC wants the
    light palette reversed so neutral_0 is the lightest step.
    """
    steps = []
    for index in range(11):
        raw = palette.get(f"neutral_{index}", "")
        if raw and not raw.startswith("{{"):
            steps.append(normalize(raw))
        else:
            grey = clamp(index * 25.5)
            steps.append("%02X%02X%02X" % (grey, grey, grey))
    if mode == "light":
        steps.reverse()
    return steps


def palette_inner(
    mode: str, colors: dict[str, str], neutral: list[str]
) -> str:
    """Serialize a cosmic_theme::CosmicPaletteInner."""
    return (
        '( name: "noctalia-%s", bright_red: %s, bright_green: %s, '
        "bright_orange: %s, gray_1: %s, gray_2: %s, "
        "neutral_0: %s, neutral_1: %s, neutral_2: %s, neutral_3: %s, "
        "neutral_4: %s, neutral_5: %s, neutral_6: %s, neutral_7: %s, "
        "neutral_8: %s, neutral_9: %s, neutral_10: %s, "
        "accent_blue: %s, accent_indigo: %s, accent_purple: %s, "
        "accent_pink: %s, accent_red: %s, accent_orange: %s, "
        "accent_yellow: %s, accent_green: %s, accent_warm_grey: %s, "
        "ext_warm_grey: %s, ext_orange: %s, ext_yellow: %s, ext_blue: %s, "
        "ext_purple: %s, ext_pink: %s, ext_indigo: %s )"
    ) % (
        mode,
        color(colors["error"]),
        color(colors["tertiary"]),
        color(colors["secondary"]),
        color(colors["surface"]),
        color(colors["surface_container_low"]),
        *[color(step) for step in neutral],
        color(colors["primary"]),
        color(colors["primary"]),
        color(colors["tertiary"]),
        color(colors["tertiary"]),
        color(colors["error"]),
        color(colors["tertiary"]),
        color(colors["tertiary"]),
        color(colors["tertiary"]),
        color(colors["outline"]),
        color(colors["outline"]),
        color(colors["tertiary"]),
        color(colors["tertiary"]),
        color(colors["primary"]),
        color(colors["tertiary"]),
        color(colors["error"]),
        color(colors["primary"]),
    )


# --------------------------------------------------------------------------- #
# theme construction
# --------------------------------------------------------------------------- #
# Noctalia token -> fallbacks, for palettes that predate a role.
ROLE_FALLBACKS = {
    "surface": ("surface_dim",),
    "on_surface": ("on_background",),
    "surface_container_low": ("surface_container",),
    "surface_container": ("surface_container_low",),
    "surface_container_high": ("surface_container",),
    "surface_container_highest": ("surface_container_high", "surface_container"),
    "surface_variant": ("surface_container_high", "surface_container"),
    "outline": ("outline_variant", "on_surface_variant"),
    "outline_variant": ("outline",),
    "primary": ("source_color",),
    "on_primary": ("surface",),
    "primary_container": ("surface_container",),
    "on_primary_container": ("on_surface",),
    "secondary": ("primary",),
    "secondary_container": ("surface_container_high", "surface_container"),
    "on_secondary_container": ("on_surface",),
    "tertiary": ("primary",),
    "on_tertiary": ("on_primary", "surface"),
    "error": ("primary",),
    "on_error": ("on_primary", "surface"),
}


def build_theme(
    palette: dict[str, str], mode: str
) -> tuple[dict[str, str], dict[str, str]]:
    """Return (derived Theme files, ThemeBuilder files) for one mode."""
    dark = mode == "dark"
    colors = {
        role: lookup(palette, mode, role, *fallbacks)
        for role, fallbacks in ROLE_FALLBACKS.items()
    }
    neutral = neutral_ramp(palette, mode)

    base = colors["surface"]
    on = colors["on_surface"]
    accent = colors["primary"]
    on_accent = colors["on_primary"]
    outline_variant = colors["outline_variant"]
    tertiary = colors["tertiary"]
    on_tertiary = colors["on_tertiary"]
    error = colors["error"]
    on_error = colors["on_error"]

    background = container(base, on, accent, outline_variant, dark, bump=0.03)
    # libcosmic paints the nav bar/sidebar with `primary.base` and nested panels
    # with `secondary.base`. Material's `*_container` roles are tinted accents and
    # read as bright slabs there, so map the containers onto the neutral surface
    # ramp instead: window = surface, sidebar = surface_container, panels =
    # surface_container_high. That is also what Noctalia's GTK template uses for
    # `sidebar_bg_color`.
    primary = container(
        colors["surface_container"],
        on,
        accent,
        outline_variant,
        dark,
        bump=0.05,
    )
    secondary = container(
        colors["surface_container_high"],
        on,
        accent,
        outline_variant,
        dark,
        bump=0.05,
    )

    theme = {
        "name": '"Noctalia %s"' % ("Dark" if dark else "Light"),
        "background": background,
        "primary": primary,
        "secondary": secondary,
        # No blur/transparency is requested, so the transparent variants mirror
        # their opaque counterparts.
        "transparent_background": background,
        "transparent_primary": primary,
        "transparent_secondary": secondary,
        # Standard buttons are a translucent neutral wash, so they pick up the
        # container they sit in (window, sidebar, panel) like Adwaita buttons do.
        "button": overlay_component(
            on, accent, dark, base=0.10, hover=0.14, pressed=0.20
        ),
        "accent": component(accent, on_accent, accent, accent, dark, divider=0.40),
        "success": component(
            tertiary, on_tertiary, accent, tertiary, dark, divider=0.40
        ),
        "destructive": component(
            error, on_error, accent, error, dark, divider=0.40
        ),
        # COSMIC has no dedicated warning palette entry; Noctalia's tertiary is
        # the closest equivalent and stays legible on the same surfaces.
        "warning": component(
            tertiary, on_tertiary, accent, tertiary, dark, divider=0.40
        ),
        "accent_button": component(
            accent, on_accent, accent, accent, dark, divider=0.40
        ),
        "success_button": component(
            tertiary, on_tertiary, accent, tertiary, dark, divider=0.40
        ),
        "destructive_button": component(
            error, on_error, accent, error, dark, divider=0.40
        ),
        "warning_button": component(
            tertiary, on_tertiary, accent, tertiary, dark, divider=0.40
        ),
        # Flat controls: no base fill, only a hover/pressed overlay. This is what
        # keeps the titlebar window controls from drawing a filled circle.
        "icon_button": overlay_component(on, accent, dark),
        "link_button": overlay_component(accent, accent, dark),
        "list_button": overlay_component(on, accent, dark),
        "text_button": overlay_component(on, accent, dark),
        "palette": palette_inner(mode, colors, neutral),
        "spacing": SPACING,
        "corner_radii": CORNER_RADII,
        "is_dark": "true" if dark else "false",
        "is_high_contrast": "false",
        "gaps": "(0, 8)",
        "active_hint": "3",
        "window_hint": some_rgb(accent),
        "frosted": "Medium",
        "frosted_windows": "false",
        "frosted_system_interface": "false",
        "frosted_panel": "false",
        "frosted_applets": "false",
        "frosted_maximized_apps": "false",
        "alpha_map": ALPHA_MAP,
        "shade": color("000000", 82),
        "accent_text": "None",
        "control_tint": "None",
        "text_tint": "None",
    }

    builder = {
        "palette": "%s(%s)" % (
            "Dark" if dark else "Light",
            palette_inner(mode, colors, neutral),
        ),
        "spacing": SPACING,
        "corner_radii": CORNER_RADII,
        "neutral_tint": "None",
        "bg_color": some_rgba(base),
        "primary_container_bg": some_rgba(colors["primary_container"]),
        "secondary_container_bg": some_rgba(colors["secondary_container"]),
        "text_tint": "None",
        "accent": some_rgb(accent),
        "success": some_rgb(tertiary),
        "warning": some_rgb(tertiary),
        "destructive": some_rgb(error),
        "frosted": "Medium",
        "gaps": "(0, 8)",
        "active_hint": "3",
        "window_hint": some_rgb(accent),
        "frosted_windows": "false",
        "frosted_system_interface": "false",
        "frosted_panel": "false",
        "frosted_applets": "false",
        "frosted_maximized_apps": "false",
        "alpha_map": ALPHA_MAP,
    }
    return theme, builder


# --------------------------------------------------------------------------- #
# output
# --------------------------------------------------------------------------- #
def write_tree(root: str, files: dict[str, str]) -> None:
    """Write each config key as its own file, only when the value changed."""
    os.makedirs(root, exist_ok=True)
    for name, value in files.items():
        path = os.path.join(root, name)
        try:
            with open(path, encoding="utf-8") as handle:
                if handle.read() == value:
                    continue
        except FileNotFoundError:
            pass
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(value)


def main(argv: list[str]) -> int:
    if len(argv) > 2 or (len(argv) == 2 and argv[1] not in ("dark", "light")):
        print("Usage: apply.py [dark|light]", file=sys.stderr)
        return 2

    config_home = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    cache_home = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
    cosmic_dir = os.path.join(config_home, "cosmic")
    palette_path = os.path.join(cache_home, "noctalia", "cosmic-palette")

    if not os.path.isdir(cosmic_dir):
        print(
            "Error: %s does not exist; launch a COSMIC app once so it writes "
            "its configuration, then re-apply the theme." % cosmic_dir,
            file=sys.stderr,
        )
        return 1
    if not os.path.isfile(palette_path):
        print(
            "Error: rendered palette not found at %s" % palette_path,
            file=sys.stderr,
        )
        return 1

    palette = read_palette(palette_path)
    mode = argv[1] if len(argv) == 2 else palette.get("mode", "dark")
    if mode not in ("dark", "light"):
        mode = "dark"

    for current, suffix in MODES:
        theme, builder = build_theme(palette, current)
        write_tree(
            os.path.join(cosmic_dir, f"com.system76.CosmicTheme.{suffix}", "v2"),
            theme,
        )
        write_tree(
            os.path.join(
                cosmic_dir, f"com.system76.CosmicTheme.{suffix}.Builder", "v2"
            ),
            builder,
        )

    # libcosmic apps call Theme::system_preference(), which reads this key.
    mode_dir = os.path.join(cosmic_dir, "com.system76.CosmicTheme.Mode", "v1")
    write_tree(mode_dir, {"is_dark": "true" if mode == "dark" else "false"})
    auto_switch = os.path.join(mode_dir, "auto_switch")
    if not os.path.exists(auto_switch):
        # Do not override a user's configured day/night switching.
        write_tree(mode_dir, {"auto_switch": "false"})

    # Noctalia already themes GTK/Qt; keep COSMIC from overriding those.
    write_tree(
        os.path.join(cosmic_dir, "com.system76.CosmicTk", "v1"),
        {"apply_theme_global": "false"},
    )

    print("COSMIC colors applied successfully (%s)" % mode)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
