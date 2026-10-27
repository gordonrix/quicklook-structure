# quicklook-structure

macOS Quick Look preview for protein structure files (`.pdb`, `.ent`, `.cif`, `.mmcif`).
Select a file in Finder, press Space, and get an interactive 3Dmol cartoon with one
color per chain.

Styling matches the single-structure viewer in `generate_and_align_structures`
(`gas_html.render_structure_html`): white background, orthographic projection with
a thin black outline, oval cartoon with arrows, the GAS categorical palette, ligands
as magenta-carbon sticks, waters hidden, and a hover label showing chain, residue
and B-factor (pLDDT for AlphaFold / Boltz models).

## Install

Needs only the Xcode command-line tools (`clang`, `codesign`), not Xcode.

```bash
./build.sh
```

This builds `Structure Preview.app` in `$TMPDIR`, ad-hoc signs it, installs it to
`~/Applications`, and registers the extension with Quick Look. Rerun it after any
change. `./build.sh --no-install` only builds.

## How it works

- `src/viewer.html` is the viewer page. `build.sh` inlines `src/Resources/3Dmol-min.js`
  (3Dmol.js 2.5.5) into it, so previews make no network requests.
- `src/PreviewViewController.m` is the Quick Look extension: a `WKWebView` that loads
  the page with the file's text spliced in (`src/ViewerPage.m`). All parsing and
  rendering happen in 3Dmol.
- `src/App-Info.plist` declares the `org.rcsb.pdb` and `org.wwpdb.mmcif` file types.
  Without them macOS assigns `.pdb`/`.cif` anonymous `dyn.*` types that no extension
  can claim. They conform to `public.plain-text`, so text tools still treat them as text.
- The native code is Objective-C rather than Swift so it builds with command-line
  tools whose Swift compiler and SDK don't match.

To debug the page outside Quick Look:

```bash
"$HOME/Applications/Structure Preview.app/Contents/MacOS/StructurePreview" --render in.cif out.html
```

## Uninstall

```bash
pluginkit -r "$HOME/Applications/Structure Preview.app/Contents/PlugIns/StructurePreviewExtension.appex"
rm -rf "$HOME/Applications/Structure Preview.app"
qlmanage -r
```

## License

3Dmol.js is BSD-3-Clause (https://github.com/3dmol/3Dmol.js).
