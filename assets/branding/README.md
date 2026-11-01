# WayOut app icon

Original maze-and-escape artwork generated with the built-in imagegen tool.
The cream maze and golden exit arrow remain readable at launcher sizes.

- `wayout_icon.png`: full-resolution opaque master, shared by native and web icons.
- `wayout_icon_foreground.png`: transparent Android adaptive foreground.
- `google_play_icon_512.png`: 512 × 512, 32-bit PNG for the Play Console listing.

Native launcher resources are generated using `flutter_launcher_icons` 0.14.4.
The adaptive background is `#123F35`; the 22% foreground inset keeps the complete
symbol inside Android's circular safe area. iOS icons are generated without alpha.

## Regenerate

```sh
flutter pub get
dart run flutter_launcher_icons
cp web/icons/Icon-512.png assets/branding/google_play_icon_512.png
```

Check the Play asset remains a 32-bit PNG, 512 × 512 and no larger than 1024 KB.
Use the fully square source; Play and native launchers apply their own masks.

Sources: [package documentation](https://pub.dev/packages/flutter_launcher_icons),
[Google Play asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151),
[Play icon design](https://developer.android.com/distribute/google-play/resources/icon-design-specifications).

## Master artwork prompt

Use case: logo-brand. Asset type: final launcher app icon for WayOut, a polished mobile arrow and maze puzzle game. Create a premium, memorable, highly legible geometric maze-and-escape emblem: a simple bold ivory maze made of a few thick softly rounded right-angle walls, with a warm golden-yellow path ending in a clear arrow escaping toward the upper right. The maze should subtly suggest interlocking W-shaped paths, but do not write letters. Distinctive and elegant, satisfying puzzle-game identity, clean professional 2D icon artwork, strong silhouette, restrained flat colors and only extremely subtle internal shading. Exact full-bleed solid deep forest-emerald background #123F35 all the way to every edge. Ivory #FFF3D7 walls and golden #F2BB51 arrow. Center the complete symbol with a generous even margin, main emblem occupies about 70 percent of square width and height; no important detail near the edges, balanced clear negative space between walls. No words, no text, no characters, no small scenery, no badges, no logos from other companies, no border, no enclosing tile, no outer rounded corners, no drop shadow, no mockup, no perspective. A single finished square app icon, 1024 by 1024 pixels. Must look excellent at 48 pixels.

## Adaptive foreground prompt

Edit the provided original WayOut icon into a CLEAN FLAT VECTOR-STYLE transparent foreground. Keep the exact ivory maze silhouette and gold escape-arrow silhouette, including the W-shaped bottom path, with the same positions and scale as this original. Replace all dark green background and all gaps with genuine transparency. VERY IMPORTANT: edges and negative spaces must be perfectly clean and smooth, with NO white crumbs, NO stray marks, NO haloes, NO residual background, NO paint splatter, NO shadow, NO noise. Use solid warm ivory #FFF3D7 and solid warm gold #F2BB51 instead of texture or shading, to ensure precise crisp silhouettes at tiny size. Do not change the maze layout or arrow geometry. Preserve the original square canvas with generous transparent margins. One transparent PNG, flat professional app-logo foreground only.
