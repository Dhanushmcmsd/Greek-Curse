# Asset provenance — combat polish

## Imported reusable assets

- `assets/environment/ruins/rock_diffuse.jpg`, `rock_normal.jpg`, `rock_roughness.jpg`: Rock 01, Poly Haven, 1K PBR texture maps. CC0. https://polyhaven.com/a/rock_01
- `assets/environment/ruins/storm_sky.hdr`: Kloofendal Overcast (Pure Sky), Poly Haven, 1K HDR panorama. CC0. https://polyhaven.com/a/kloofendal_overcast_puresky
- Asset metadata/downloads retrieved using the Poly Haven public API. Powered by Poly Haven: https://polyhaven.com/ . Textures retain separate albedo, normal and roughness maps and mipmap import settings.

## Authored assets

- `assets/vfx/soft_flame.png`, `impact_streak.png`, `blood_drop.png`: original mathematical opacity masks authored for this project, no game extraction.
- `assets/shaders/arena_marble.gdshader`: original procedural stone shader from the preceding pass.
- Ruin geometry dressing, shaders, timers, combat rules and effect code: project source.

## REA investigation

REA 6.7.0 was installed/configured for Codex using the requested setup command (scoped to Codex). It installed its skill and preserved the existing Codex configuration via a backup.

Supplied target: `D:\Games\Mortal Kombat 1\data\games\MK1.nsp` (45,491,644,624 bytes), inside an emulator distribution. This is not a Legacy Kollection PC asset directory. REA successfully inventoried `Launcher.exe` as a PE file with no embedded asset container. The game package itself was rejected with `unsupported_target / file_format_rejected`: “Cannot open artifact: unsupported binary format.” No native analysis provider was configured. No game textures, animations, models, executable code, emulator keys or package contents were added to this repository.

Local diagnostic outputs remain in ignored `build/rea_setup.json`, `build/rea_mk_launcher.json`, and `build/rea_mk_package.json`. They are not evidence of recovered combat logic. Existing user-supplied fight videos and image sequences remain visual reference only. Public reference: https://www.mortalkombat.com/en-sg/patch-notes (hit reactions, combo scaling and synchronized-animation behavior are design references, not copied implementation).

## Original generated background

`assets/environment/ruins/olympus_backdrop.png` was generated with the built-in image-generation tool and copied into the project. It is a distant matte on a depth-tested 3D plane; the fighting floor, fighters, detached limbs and effects remain real-time 3D. No image from Mortal Kombat was used as an edit target.

Generation prompt:

> Create an original high quality dark fantasy fighting-game arena background matte painting, wide landscape 16:9, realistic physically based cinematic game environment. Ancient Greek ruined Olympus temple on a stormy mountainside at blue hour, immense weathered carved basalt and limestone colonnades with broken capitals and relief sculptures, cracked stairs ascending in distant center, distant jagged mountains and turbulent cloud layers seen through the ruin, small warm amber braziers at far sides, drifting low ground mist. Eye-level side-on fighting game camera with horizon 45% down, no people, no fighters, no weapons, no text, no interface, no logos. Central lower third is open dark unobtrusive ground receding toward the background, leaving room for separately rendered game characters. Architectural detail and eroded stone realism, cool steel blue shadows with restrained warm fire accents, clear silhouettes, varied depth, subdued foreground. Not a screenshot or copy of an existing game: original Greek mythology art. Asset intended as distant background for a real-time 3D fighting arena. Avoid shiny plastic, geometric placeholder blocks, excessive bloom, symmetrical repeated cubes, purple neon, cartoon styling.

## Original flagstone material (follow-up)

`assets/environment/ruins/olympus_flagstones.png` was generated with the built-in image-generation tool on 2026-10-28 and copied into the project. Original saved output: `C:/Users/Admin/.codex/generated_images/01a18318-b226-7872-a142-f9e3dad4e09c/exec-1dc31c71-c4a6-447c-923f-54153b213a49.png`.

Prompt: Create a production game material texture, square 2048x2048, strictly orthographic top-down seamless tileable albedo texture of ancient Greek ruined temple paving. Large irregular rectangular charcoal grey limestone flagstones with thin worn joints, pale mineral streaks, chipped eroded edges, small cracks, dark damp weathering, tiny subtle moss in a few joints. Realistic scanned stone quality. Cool neutral grey with restrained warm grey undertones. Flat diffuse overcast illumination, no directional shadows, no perspective, no borders, no text, no props, no vignette. Tiles must meet seamlessly at all four edges. Entire image is the continuous stone surface. Strong fine-grained texture and age variation without large bright patches. This will be used on a 3D fighting arena floor adjoining photorealistic stormy Greek ruins.
