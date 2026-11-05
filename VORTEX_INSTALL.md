# ControllerRemap with Vortex

The release ZIP already uses the Farever extension's supported game-root layout. Keep `hlx/` directly at the archive root; upload the generated ZIP unchanged. No FOMOD or separate SFimgui/SFCursor downloads are needed.

## Player setup

1. Close Farever.
2. Install/update the [Farever Vortex extension](https://www.nexusmods.com/site/mods/2120), then restart Vortex and manage Farever. Verify its detected game folder contains Farever.exe.
3. Install the full ControllerRemap release ZIP, enable it and deploy mods. Downloading or staging an archive is not proof that its files reached the game folder.
4. Resolve file conflicts for the shared helpers. The deployed files should match the tested bundle, or a separately confirmed compatible version. Do not assume an older or newer shared DLL is compatible merely from its filename.
5. Verify the four paths below in the actual game folder, then restart Farever. Check that ControllerRemap no longer reports a helper problem.

```text
hlx/mods/controllerremap/controllerremap.hl
hlx/plugins/sfcursor/sfcursor.hdll
hlx/plugins/sfimgui/sfimgui.hdll
hlx/plugins/sfimgui/fonts/NotoSans-Regular.ttf
```

The [extension README](https://github.com/hlx-framework/vortex-farever-extension#supported-mod-zip-layouts) specifies game-root copying for this archive shape. Vortex's [deployment documentation](https://github.com/Nexus-Mods/Vortex/wiki/MODDINGWIKI-Users-General-Deployment-Methods) and [file-conflict guide](https://github.com/Nexus-Mods/Vortex/wiki/MODDINGWIKI-Users-General-Managing-File-Conflicts) explain the remaining deployment steps.

## Read-only deployment check

From this source checkout, run:

```powershell
& ./tools/check-install.ps1 -GamePath 'D:\SteamLibrary\steamapps\common\Farever'
```

Or supply the exact downloaded release ZIP:

```powershell
& ./tools/check-install.ps1 -GamePath 'D:\SteamLibrary\steamapps\common\Farever' -ReleaseZip 'D:\Downloads\ControllerRemap-1.2.3.zip'
```

The script checks the game executable location, all four required paths and their SHA-256 hashes. `MISSING` identifies absent/misplaced files. `DIFFERENT` identifies a version conflict requiring review; it does not automatically mean the file is incompatible. The script changes no game files, Vortex settings or deployment rules. Matching files do not prove a running process loaded them: restart the game and use the helper's runtime notice/HLX logs for that check.

## Author release check

Run the package audit first, then dry-run an installed Farever extension:

```powershell
python tools/verify-package.py
node tools/verify-vortex-install.cjs 'C:\Users\YourName\AppData\Roaming\Vortex\plugins\YourFareverExtensionFolder'
```

This reads the extension's actual installer, supplies the verified archive entries, and checks that every source maps to the same game-root destination, with both slash styles. It never calls the extension's setup/update hooks, deploys files or changes Vortex. The result is written to `build/vortex-install-verification.json`. It validates installer mapping, not a real Vortex deployment.

Keep HLX core listed as a requirement on the release page and link the Farever extension in the Vortex instructions. SFimgui, its font and SFCursor remain mandatory bundled runtime files. Our package audit already rejects a release ZIP missing any of them. Documentation and diagnostics stay outside the four-file player ZIP.

## Verified here — 2026-11-05

The locally installed Farever extension reports version 0.0.1; this is separate from the tester's unknown extension version. The extension's Nexus listing currently shows 0.0.6, while its GitHub changelog includes 0.0.7. Use the current published extension rather than treating the local copy as a release recommendation. No installed extension was updated or modified during this investigation.
