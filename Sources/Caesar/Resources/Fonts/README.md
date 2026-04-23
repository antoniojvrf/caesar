# Bundled fonts

These TTFs ship inside the Caesar bundle and are registered at app launch by
`FontLoader.registerBundledFonts()`.

| File | Family | License |
|---|---|---|
| `InterVariable.ttf` | `Inter Variable` | SIL Open Font License 1.1 |
| `EBGaramond.ttf` | `EB Garamond` | SIL Open Font License 1.1 |
| `EBGaramond-Italic.ttf` | `EB Garamond` | SIL Open Font License 1.1 |

## Why EB Garamond?

The brand board specifies a display serif branded *Caesar Display*. Until the
licensed family is dropped into this folder, EB Garamond acts as a faithful
stand-in — classical proportions, high contrast, editorial feel.

## Swapping in Caesar Display

1. Drop `CaesarDisplay-*.ttf` (or `.otf`) into this folder.
2. The loader picks them up automatically at launch (anything with a `.ttf` /
   `.otf` extension in this directory is registered).
3. `AppTypography` will resolve *Caesar Display* first, EB Garamond second,
   system serif last — no code changes required.
