# Tuplet Glyph Input -- CLI / Editor-Agnostic

How to type Tuplet's Unicode glyphs from any program, not
just Emacs. The recommended path is **Espanso**, a free
cross-platform text expander that watches what you type and
expands triggers into Unicode. Alternatives by OS are noted
below.

See `docs/glyphs.md` for the alphabet and `docs/emacs-inputs.md`
for the Emacs-specific path.

## Recommended: Espanso

Espanso runs in the background, watches keystrokes, and
expands a trigger like `:mint` into the mint glyph. It
works in any program -- shells, editors, browsers, REPLs.

### Install

| OS       | Install                                                               |
|----------|-----------------------------------------------------------------------|
| macOS    | `brew install espanso`                                                |
| Linux    | Snap, AppImage, or .deb from https://espanso.org/install/             |
| Windows  | `winget install Espanso.Espanso` or installer from espanso.org        |

Then:

```bash
espanso start
espanso path config   # prints config dir
```

### Set up Tuplet matches

This repo ships a reference matchfile at
`scripts/tuplet-espanso.yml.example`. Drop it in:

```bash
cp scripts/tuplet-espanso.yml.example \
   "$(espanso path config)/match/tuplet.yml"
espanso restart
```

After this, typing the triggers in any application produces
the Unicode replacement.

### Convention

The reference file uses these prefixes (all start with `:` so
they don't collide with normal typing):

| Prefix  | Family                                  | Example                |
|---------|-----------------------------------------|------------------------|
| `:mint` | Kernel mint                             | `:mint` -> U+25AA      |
| `:la`   | Assignment arrow                        | `:la` -> U+27F5        |
| `:ra`   | Mapping arrow                           | `:ra` -> U+2500 U+2500 U+2500 U+2023 |
| `:Ra`   | Test arrow                              | `:Ra` -> U+27F6        |
| `:gX`   | Greek lowercase (`:galpha`, `:grho`)    | `:galpha` -> U+03B1    |
| `:GX`   | Greek uppercase (`:GSigma`, `:GPi`)     | `:GSigma` -> U+03A3    |
| `:sN`   | Subscript digit (`:s2`, `:s3`, `:s4`)   | `:s2` -> U+2082        |
| `:tX`   | Type symbol (`:tZ`, `:tR`, `:tN`)       | `:tZ` -> U+2124        |
| `:?`    | Boolean suffix (modifier glottal stop)  | `:?` -> U+02C0         |
| `:max`  | max wedge / `:min` -> min wedge         | `:max` -> U+22CF       |
| `:approx` `:neq` `:leq` `:geq` `:pm`    | math relations | `:approx` -> U+2248 |

Total: ~50 entries. See the matchfile for the complete list.

### Per-app scoping (optional)

Espanso supports per-app filters; restrict Tuplet expansions
to your editor and shell to avoid expanding `:mint` in casual
chat:

```yaml
# At the top of tuplet.yml:
filter_class: "(Code|iTerm2|Alacritty|Emacs|Terminal)"
matches:
  - trigger: ":mint"
    replace: "▪"
  ...
```

The exact `filter_class` value is OS-specific; see
https://espanso.org/docs/matches/scopes.

### When Espanso isn't an option

If you can't run a background daemon (e.g., remote shell over
SSH on a locked-down host), see the per-OS sections below.

## Linux: XKB compose key

The Compose key is a long-standing X server / Wayland feature
that turns sequences like `<Compose> <a> <e>` into `ae`. You
can extend it for Tuplet glyphs.

### Enable the Compose key

In a desktop environment with a Settings app, find
"Keyboard" -> "Compose key" and pick a key (Caps Lock and
Right Alt are common). On bare X:

```bash
setxkbmap -option compose:caps    # or compose:ralt
```

### Add Tuplet sequences

The reference XCompose entries ship at
`scripts/tuplet-XCompose.example`. Append to `~/.XCompose`
(create if needed):

```bash
cat scripts/tuplet-XCompose.example >> ~/.XCompose
```

Each entry is one line of the form
`<Multi_key> <chord> : "<glyph>" UXXXX # name`. Triggers use
mnemonic chords -- e.g., Compose followed by `m i n t`
produces U+25AA (black small square); Compose `l a` produces the assign
arrow; Compose `g a` produces alpha. See the file for the
full list (~25 entries).

GTK / Qt apps re-read `~/.XCompose` on launch; restart the
app to pick up changes.

Pros: no daemon, works in every X11/Wayland app.
Cons: Wayland support varies; some apps (Chromium-based)
ignore XCompose without compositor help.

## macOS: Karabiner-Elements / Keyboard Maestro / built-in text replacement

### Built-in (System Settings)

System Settings -> Keyboard -> Text Replacements lets you
register short triggers that expand to longer strings,
including Unicode. It's lighter than a dedicated tool but
slower and synced via iCloud.

Triggers like `:mint` can replace with the mint glyph `▪`
(U+25AA) system-wide. Add each glyph from `docs/glyphs.md`
as a row.

Pros: zero install. Cons: small UI, no scoping, sync delays.

### Karabiner-Elements

For more control, Karabiner can map sequences to Unicode by
sending the codepoint via shell:

```bash
brew install --cask karabiner-elements
```

Then in `~/.config/karabiner/karabiner.json` add custom
"complex modifications" rules. The reference setup is
similar to Espanso's matchfile -- one entry per glyph -- so
most users prefer Espanso on macOS.

### Keyboard Maestro

Commercial tool with a friendlier UI than Karabiner. Same
trigger -> Unicode mapping. Worth it if you already use it.

## Windows: AutoHotKey

AHK scripts can map keystrokes to Unicode codepoints.
Reference snippet:

```autohotkey
::: mint:: SendInput {U+25AA}    ; mint
::: la::   SendInput {U+27F5}    ; assign
::: ra::   SendInput {U+2500}{U+2500}{U+2500}{U+2023} ; map
::: Ra::   SendInput {U+27F6}    ; test arrow
::: approx:: SendInput {U+2248}
::: leq::  SendInput {U+2264}
::: geq::  SendInput {U+2265}
::: pm::   SendInput {U+00B1}
::: s2::   SendInput {U+2082}    ; arity 2
::: galpha:: SendInput {U+03B1}
; ... etc.
```

Save as `tuplet.ahk`, double-click to run. Pin to startup if
desired.

Pros: native Windows feel. Cons: scriptlet hot reload is
manual.

## Reference

- `scripts/tuplet-espanso.yml.example` -- canonical matchfile.
- `scripts/tuplet-input.el.example` -- Emacs Quail input
  method (same trigger conventions).
- `docs/glyphs.md` -- the alphabet.
- `docs/emacs-inputs.md` -- Emacs-specific approaches.

## Web UI -- deferred

A web-ui for Tuplet (along the lines of `web-sw-cor24-apl`
which has a good in-browser glyph picker / chord input)
isn't built yet. When it is, that doc will mirror this one.
