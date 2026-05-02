# Tuplet Glyph Input -- Emacs

How to type Tuplet's Unicode glyphs in Emacs without copying-
and-pasting. Three approaches, in order of "minimum setup":

1. **Built-in TeX input method** -- enable, type
   `\blacksquare`, `\to`, `\alpha`, etc. Works for many but not
   all Tuplet glyphs.
2. **Built-in Agda input method** -- broader coverage; ships
   with `agda2-mode` and is widely available.
3. **Custom Tuplet input method** -- declare the exact
   mappings the project uses. Best long-term option.

See `docs/glyphs.md` for the alphabet and codepoints. See
`docs/cli-inputs.md` for non-Emacs setups (Espanso, etc.).

## Approach 1: Built-in TeX input method

The simplest setup. No package to install:

```elisp
;; ~/.emacs.d/init.el
(add-hook 'find-file-hook
          (lambda ()
            (when (string-match "\\.tup$" (or (buffer-file-name) ""))
              (set-input-method "TeX"))))
```

After this, opening any `.tup` file enables TeX-style input.
Toggle on/off with `C-\`.

### TeX shortcuts -> Tuplet glyphs

| You type      | You get (codepoint)    | Tuplet role             |
|---------------|------------------------|-------------------------|
| `\blacksquare`| U+25AA                 | mint                    |
| `\leftarrow`  | U+27F5                 | assign                  |
| `\to`         | U+2500 U+2500 U+2500 U+2023 | map / signature   |
| `\rightarrow` | U+27F6                 | test arrow              |
| `\approx`     | U+2248                 | approx-equal            |
| `\neq`        | U+2260                 | not-equal               |
| `\leq`        | U+2264                 | leq                     |
| `\geq`        | U+2265                 | geq                     |
| `\pm`         | U+00B1                 | plus-minus              |
| `\times`      | U+00D7                 | multiplication          |
| `\div`        | U+00F7                 | division                |
| `\wedge`      | U+2227                 | logical and             |
| `\vee`        | U+2228                 | logical or              |
| `\neg`        | U+00AC                 | not                     |
| `\alpha`      | U+03B1                 | identifier              |
| `\beta`       | U+03B2                 | identifier              |
| `\rho`        | U+03C1                 | identifier              |
| `\lambda`     | U+03BB                 | identifier              |
| `\Sigma`      | U+03A3                 | identifier              |
| `\Z`          | U+2124                 | Integer type            |
| `\R`          | U+211D                 | Real type               |
| `\N`          | U+2115                 | Natural type            |
| `\in`         | U+2208                 | "is a" (type)           |
| `\infty`      | U+221E                 | infinity                |

### What TeX input method doesn't cover

The Tuplet kernel uses a few glyphs that TeX has no shortcut
for. Bind them yourself in `init.el` if you need them:

| Glyph (codepoint) | Tuplet role                   |
|-------------------|-------------------------------|
| U+25AA            | mint operator alias           |
| U+239B / U+239E   | shell-bracket parens          |
| U+23A7 / U+23AB   | curly-hook block delimiters   |
| U+22CF / U+22CE   | curly logical AND/OR (max/min)|
| U+2082..U+2089    | subscripts (arity suffix)     |
| U+02C0            | modifier letter glottal stop  |

## Approach 2: Agda input method

Wider coverage, better for math-heavy code. Available via
the `agda2-mode` package on MELPA, or standalone in the
`agda-input` library.

```elisp
;; Install agda2-mode from MELPA, or just install agda-input
;; standalone if you don't want the full Agda mode.
(use-package agda-input
  :ensure t
  :hook (find-file
         . (lambda ()
             (when (string-match "\\.tup$" (or (buffer-file-name) ""))
               (set-input-method "Agda")))))
```

Agda input includes everything in TeX plus subscripts,
double-struck letters, curly brackets U+23A7..U+23AB, and
many more shortcuts (`_2` -> U+2082, `\Bz` -> U+2124, etc).

For a pure Tuplet workflow this is the recommended
off-the-shelf setup -- minimum code, broadest coverage.

## Approach 3: Custom Tuplet input method

Define exactly the mappings the project agrees on. Most
robust against TeX/Agda updates.

The reference Quail input method ships in this repo at
`scripts/tuplet-input.el.example`. To install:

```bash
cp scripts/tuplet-input.el.example ~/.emacs.d/tuplet-input.el
```

Then in your init:

```elisp
(load (expand-file-name "tuplet-input.el" user-emacs-directory))

(add-hook 'find-file-hook
          (lambda ()
            (when (string-match "\\.tup$" (or (buffer-file-name) ""))
              (set-input-method "Tuplet"))))
```

The example file covers the full glyph table from
`docs/glyphs.md`: kernel forms, math relations, operators,
arity subscripts, type-set symbols, the boolean-suffix
modifier letter, and the lowercase + uppercase Greek block.
Roughly 50 mappings.

To extend or trim: edit your local copy and reload via `M-x
load-file`. The shipped `.example` file is the canonical
project agreement -- if you find yourself adding mappings you
think the project should adopt, open a PR updating the
`.example`.

## A `tuplet-mode` skeleton

Once syntax highlighting and indent matter, derive a minor
mode. This is a sketch; not yet shipped:

```elisp
(define-derived-mode tuplet-mode prog-mode "Tuplet"
  "Major mode for editing .tup files."
  (setq-local comment-start "# ")
  (setq-local comment-end "")
  (set-input-method "Tuplet"))

(add-to-list 'auto-mode-alist '("\\.tup\\'" . tuplet-mode))
```

## Other editors / IDEs

Out of scope for this doc. Quick pointers:

- **VS Code**: a custom keybindings JSON or a small extension
  consuming `editor.unicodeHighlight` plus snippets.
- **JetBrains IDEs**: Live Templates with Unicode in the
  expansion.
- **Vim/Neovim**: `:digraphs` or `lua` snippet plugins like
  `LuaSnip`.

When IDE support becomes a priority, file a tracking issue
and pick a reference implementation.

## Reference

- `docs/glyphs.md` -- the alphabet (canonical, minimal,
  suggested).
- `docs/cli-inputs.md` -- non-Emacs (CLI / Espanso / OS-level)
  setups.
