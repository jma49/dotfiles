#!/usr/bin/env python3
"""Build the Catppuccin Blur 2.0 theme family for Zed.

Starts from the official Catppuccin themes (catppuccin/zed, mauve accent, pinned
to OFFICIAL_REF) and applies the frosted-glass rules below, so syntax colors and
new theme keys follow upstream. To pick up an upstream update, bump OFFICIAL_REF
and rerun:

    python3 ~/dotfiles/zed/build-catppuccin-blur-2.py          # write the theme
    python3 ~/dotfiles/zed/build-catppuccin-blur-2.py --check  # CI: fail if stale

Glass layout follows Catppuccin Blur (github.com/jenslys/zed-catppuccin-blur):
the window background carries the tint and content layers are transparent,
because Zed paints some colors several times (the dock and every project panel
row both paint panel.background) and per-layer alpha would compound unevenly.
Unlike Catppuccin Blur, readability keys stay official: line numbers, active
line, borders and focus borders.

Legibility is checked against the glass over both a dark and a bright wallpaper.
Glass may only win back what translucency costs: a color's target is the lower of
the floor below and its contrast in the opaque official theme, so Latte keeps its
soft accents. A color that misses only changes OKLCH lightness (hue and chroma
stay Catppuccin's) and by at most MAX_SHIFT; the per-flavor tint covers the rest.
Selection is an opaque, mid-tone color on the lavender hue, solved to stand out
from the glass over either wallpaper.
"""

import colorsys
import copy
import json
import math
import sys
import urllib.request
from pathlib import Path

OFFICIAL_REF = "4314cb05c74d141b7962290a41d6087e8c0ad02f"
OFFICIAL_URL = f"https://raw.githubusercontent.com/catppuccin/zed/{OFFICIAL_REF}/themes/catppuccin-mauve.json"
OUT = Path(__file__).resolve().parent / ".config/zed/themes/catppuccin-blur-2.json"

# Catppuccin palette subset, plus per flavor the glass color and its tint alpha:
# the most glass that keeps lightness shifts within MAX_SHIFT. Light flavors and
# Frappé wash out sooner over a contrasting wallpaper, Espresso's black base can
# afford more; Mocha tints with crust instead of base to match kitty. Espresso
# and Iced Latte are Catppuccin Blur's extra flavors: Macchiato and Latte accents
# on near-black and icy-blue backgrounds.
PALETTES = {
    "Latte": dict(official="Latte", glass="base", tint="e6", base="#eff1f5", mantle="#e6e9ef",
                  crust="#dce0e8", surface0="#ccd0da", overlay1="#8c8fa1", text="#4c4f69",
                  lavender="#7287fd", mauve="#8839ef", cursor="#fe640b"),
    "Iced Latte": dict(official="Latte", glass="base", tint="e6", base="#e8f4ff", mantle="#ddeeff",
                       crust="#d0e8ff", surface0="#c0d8f0", overlay1="#8c8fa1", text="#4c4f69",
                       lavender="#7287fd", mauve="#8839ef", cursor="#fe640b"),
    "Frappé": dict(official="Frappé", glass="base", tint="e6", base="#303446", mantle="#292c3c",
                   crust="#232634", surface0="#414559", overlay1="#838ba7", text="#c6d0f5",
                   lavender="#babbf1", mauve="#ca9ee6", cursor="#ffa500"),
    "Macchiato": dict(official="Macchiato", glass="base", tint="e0", base="#24273a", mantle="#1e2030",
                      crust="#181926", surface0="#363a4f", overlay1="#8087a2", text="#cad3f5",
                      lavender="#b7bdf8", mauve="#c6a0f6", cursor="#ffa500"),
    "Mocha": dict(official="Mocha", glass="crust", tint="d7", base="#1e1e2e", mantle="#181825",
                  crust="#11111b", surface0="#313244", overlay1="#7f849c", text="#cdd6f4",
                  lavender="#b4befe", mauve="#cba6f7", cursor="#ffa500"),
    "Espresso": dict(official="Macchiato", glass="base", tint="c0", base="#000000", mantle="#0a0a0a",
                     crust="#000000", surface0="#1a1a1a", overlay1="#8087a2", text="#cad3f5",
                     lavender="#b7bdf8", mauve="#c6a0f6", cursor="#ffa500"),
}

# Solid diagnostic boxes (info, warning, error, success), from Catppuccin Blur
DIAGNOSTICS = {
    "Latte": ("#cce9f3", "#ffe5c0", "#ffd7d9", "#d4eecf"),
    "Iced Latte": ("#c0e0ff", "#ffd8b8", "#ffcad5", "#c8e8c0"),
    "Frappé": ("#1f3137", "#382d20", "#3f2325", "#243427"),
    "Macchiato": ("#1e2f35", "#362c1f", "#3d2224", "#233225"),
    "Mocha": ("#1c2d33", "#342a1e", "#3b2022", "#213023"),
    "Espresso": ("#1a2b31", "#32281d", "#391e20", "#1f2e21"),
}

# Glass alpha for cards, the active tab, the scrollbar thumb and drop targets
GLASS = dict(card="d0", tab="b0", thumb="a0", drop="b0")
CLEAR = "#00000000"

# The blur averages the wallpaper into one color; these bound it on both sides
BACKDROPS = ("#0d0d0d", "#ebebeb")

# Contrast floors over the glass on either backdrop
TEXT_TARGETS = {
    "text": 7.0, "editor.foreground": 7.0, "terminal.foreground": 7.0,
    "text.muted": 4.5, "editor.active_line_number": 4.5,
    "text.placeholder": 3.0, "editor.line_number": 3.0,
    **{f"terminal.ansi.{name}": 4.5 for name in ("red", "green", "yellow", "blue", "magenta", "cyan")},
}
SYNTAX_TARGET = 4.5
SYNTAX_TARGETS = {"comment": 4.0, "comment.doc": 4.0, "hint": 3.0, "predictive": 3.0}
SELECTION_TEXT_CONTRAST = 4.5
MAX_SHIFT = 0.08  # OKLCH lightness


def parse(hex_color):
    """'#rrggbb' or '#rrggbbaa' -> ([r, g, b] in 0..1, alpha suffix)"""
    return [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)], hex_color[7:9]


def to_hex(color, alpha=""):
    return "#" + "".join(f"{round(min(max(c, 0), 1) * 255):02x}" for c in color) + alpha


def composite(hex_color, backdrop):
    color, alpha = parse(hex_color)
    a = int(alpha, 16) / 255 if alpha else 1.0
    return [c * a + b * (1 - a) for c, b in zip(color, backdrop)]


def luminance(color):
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in color]
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


def contrast(a, b):
    hi, lo = sorted([luminance(a), luminance(b)], reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def to_oklch(color):
    r, g, b = (c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in color)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return L, math.hypot(A, B), math.atan2(B, A)


def from_oklch(L, C, h):
    A, B = C * math.cos(h), C * math.sin(h)
    l = (L + 0.3963377774 * A + 0.2158037573 * B) ** 3
    m = (L - 0.1055613458 * A - 0.0638541728 * B) ** 3
    s = (L - 0.0894841775 * A - 1.2914855480 * B) ** 3
    lin = (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
           -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
           -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)
    return [12.92 * c if c <= 0.0031308 else 1.055 * max(c, 0) ** (1 / 2.4) - 0.055 for c in lin]


def legible(hex_color, glasses, opaque_base, floor, dark):
    """Shift OKLCH lightness until the color is as legible on glass as the official
    theme made it on its opaque base (capped at floor), within MAX_SHIFT."""
    color, alpha = parse(hex_color)
    target = min(floor, contrast(composite(hex_color, opaque_base), opaque_base))
    L, C, h = to_oklch(color)
    step = 0.005 if dark else -0.005
    candidate = hex_color
    for _ in range(round(MAX_SHIFT / 0.005)):
        if min(contrast(composite(candidate, glass), glass) for glass in glasses) >= target:
            break
        L += step
        candidate = to_hex(from_oklch(L, C, h), alpha)
    return candidate


def selection(p, glasses, text):
    """Opaque lavender-hue color: distinct from the glass, text still legible.

    Mid tones only, since extremes win on contrast but read as a hole rather than
    a highlight; among colors within 3% of the most distinct, the least saturated.
    """
    hue = colorsys.rgb_to_hls(*parse(p["lavender"])[0])[0]
    candidates = []
    for sat in (x / 20 for x in range(9, 14)):
        for light in (x / 200 for x in range(50, 170)):
            color = parse(to_hex(colorsys.hls_to_rgb(hue, light, sat)))[0]
            if contrast(text, color) >= SELECTION_TEXT_CONTRAST:
                candidates.append((min(contrast(color, glass) for glass in glasses), sat, color))
    best = max(score for score, _, _ in candidates)
    return to_hex(min((c for c in candidates if c[0] >= best * 0.97), key=lambda c: c[1])[2])


def build(flavor, official):
    p = PALETTES[flavor]
    dark = official["appearance"] == "dark"
    style = copy.deepcopy(official["style"])
    glass_color = p[p["glass"]]
    tint = glass_color + p["tint"]
    info, warning, error, success = DIAGNOSTICS[flavor]
    style.update({
        "background.appearance": "blurred",
        "background": tint,
        # Content: transparent, shows the window tint
        **{key: CLEAR for key in (
            "editor.background", "editor.gutter.background", "toolbar.background", "terminal.background",
            "panel.background", "scrollbar.track.background", "scrollbar.track.border",
            "tab_bar.background", "tab.inactive_background",
        )},
        # Cards and sticky project panel headers stay solid enough to read
        "surface.background": p["base"] + GLASS["card"],
        "panel.overlay_background": glass_color,
        # Chrome: same tint as the window, also when the window is inactive
        "title_bar.background": tint,
        "title_bar.inactive_background": tint,
        "status_bar.background": tint,
        "tab.active_background": p["mantle"] + GLASS["tab"],
        "elevated_surface.background": p["mantle"],
        # Borderless buttons get a faint fill so they read on glass
        "ghost_element.background": p["mantle"] + "60",
        "ghost_element.hover": p["mantle"] + "90",
        "ghost_element.active": p["mauve"] + "30",
        "ghost_element.selected": p["mauve"] + "50",
        # Diagnostic boxes are solid so they stay legible over bright wallpapers
        "hint.background": p["surface0"] + "c0",
        "info.background": info,
        "warning.background": warning,
        "error.background": error,
        "success.background": success,
        "drop_target.background": p["mauve"] + GLASS["drop"],
        "scrollbar.thumb.background": p["overlay1"] + GLASS["thumb"],
        # Separators: surface0; focus ring: lavender
        "border": p["surface0"],
        "border.variant": p["surface0"] + "80",
        "border.focused": p["lavender"],
    })
    if flavor in ("Espresso", "Iced Latte"):
        # Remaining official surfaces would keep the source flavor's background hue
        for key, value in list(style.items()):
            if value == official["style"]["panel.background"]:
                style[key] = p["mantle"]

    glasses = [composite(tint, parse(backdrop)[0]) for backdrop in BACKDROPS]
    opaque_base = parse(official["style"]["editor.background"])[0]
    for key, floor in TEXT_TARGETS.items():
        if style.get(key):
            style[key] = legible(style[key], glasses, opaque_base, floor, dark)
    for name, syntax in style["syntax"].items():
        if syntax.get("color"):
            floor = SYNTAX_TARGETS.get(name, SYNTAX_TARGET)
            syntax["color"] = legible(syntax["color"], glasses, opaque_base, floor, dark)

    players = style["players"]
    players[0] = {**players[0], "cursor": p["cursor"], "background": p["cursor"],
                  "selection": selection(p, glasses, parse(style["text"])[0])}
    return {"name": f"Catppuccin {flavor} (Blur 2.0)", "appearance": official["appearance"], "style": style}


def main():
    with urllib.request.urlopen(OFFICIAL_URL, timeout=30) as response:
        themes = json.load(response)["themes"]
    official = {t["name"].removeprefix("Catppuccin "): t for t in themes}
    for flavor, p in PALETTES.items():
        style = official[p["official"]]["style"]
        if flavor == p["official"]:
            # Guard against palette typos: these keys hold the flavor's colors upstream
            checks = {"base": "editor.background", "mantle": "panel.background", "crust": "title_bar.background",
                      "surface0": "border", "overlay1": "editor.line_number", "text": "text"}
            for name, key in checks.items():
                assert style[key].lower() == p[name], f"{flavor} {name}: {p[name]} != {key} {style[key]}"
    family = {
        "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
        "name": "Catppuccin Blur 2.0",
        "author": "jma49, built from catppuccin/zed and jenslys/zed-catppuccin-blur",
        "themes": [build(flavor, official[p["official"]]) for flavor, p in PALETTES.items()],
    }
    rendered = json.dumps(family, indent=2, ensure_ascii=False) + "\n"
    if "--check" in sys.argv[1:]:
        if OUT.read_text() != rendered:
            sys.exit(f"{OUT} is stale: rerun {Path(__file__).name}")
        print(f"{OUT.name} is up to date")
        return
    OUT.write_text(rendered)
    for theme in family["themes"]:
        print(f"{theme['name']}: selection {theme['style']['players'][0]['selection']}")


if __name__ == "__main__":
    main()
