# Garden maze character art

The bundled assets were created with the built-in Imagegen tool and retain their generated alpha channels:

- `maze_walk_v3.png`: animal gait frames and shared portrait artwork.
- `human_run_directions_v5.png`: eight columns × eight rows, with eight run poses per direction. Rows are male south/east/north/west, then female south/east/north/west.
- `human_idle_directions_v5.png`: four columns × two rows; south/east/north/west standing poses for the male and female characters.

The atlas has four columns and eight rows. Rows contain lion, fox, wolf, cat, snake, owl, male adventurer and female adventurer; columns contain four locomotion frames. All share the garden maze's rounded 3D forms, warm light and elevated camera angle. The same atlas supplies cropped role portraits and character-picker artwork.

Sprites are sized in maze-room units and anchored at their feet. Their ground shadow stays at the movement/collision position; actors draw in foot-depth order. Human gait follows distance traveled, completes a brief settling step after a short move and switches to a matching directional idle pose. Standing characters breathe without shifting their ground position. The follow camera enlarges paths and actors together; a miniature map and full-map button preserve navigation.

`tool/character_motion_preview_test.dart` exports the game's actual character renderer to PNG frames. `artifacts/character_run_preview.gif` is a looping four-direction animation preview rendered from those frames.

Earlier generated image variants are retained locally for reference and are not bundled in the app.

## Generation prompt

Use case: stylized-concept.
Asset type: ONE cohesive production sprite animation atlas for a garden maze mobile game, exact FOUR columns by EIGHT rows, 32 equal square cells, tall canvas aspect ratio 1:2. True transparent background, no text or grid.
Game style: soft sculpted 3D mobile game diorama with rounded mossy stone maze walls, warm cream paths and pastel green grass. Characters must look like they BELONG inside this small garden maze. Natural recognizable animal/human anatomy with simplified clean materials, softly rounded forms and soft warm top-left lighting. Premium polished game art. No photorealistic cutouts, no stickers, no white outlines, no comic outlines, no dramatic lighting, no glossy plastic toys, no oversized heads.
Camera: elevated THREE-QUARTER view looking downward at about 55 degrees above the ground, like a top-down garden maze game. Show animal faces, backs and four legs together, and human head, torso, arms and feet. NOT flat side view and NOT straight overhead. All subjects face toward lower-right / southeast. Humans stand upright on the ground, do not lie horizontally.
Exact rows top to bottom:
1. golden male lion with rounded warm brown mane, clear feline face, muscular body, four paws and tufted tail;
2. orange red fox with bushy white-tipped tail;
3. silver-gray wolf;
4. orange tabby cat;
5. green snake with raised head;
6. brown owl in low flight;
7. adult male adventurer with short dark hair, bright teal jacket, navy pants, tan shoes;
8. adult female adventurer with dark ponytail, bright plum jacket, navy pants, tan shoes.
Each row shows FOUR coherent locomotion frames of the same individual, with alternating feet/paws and swinging arms, or flapping wings / snake undulation. Same body center and camera across all frames, no drift.
Compact silhouettes, strong local colors, clear face/mane and limbs designed for game display at 24 to 36 pixels. Every full body centered in its own cell, entirely inside central 80% with transparent gutters. No overlap across cells.
No grass, floors, scenery, shadows, captions, rings, circles, labels, borders or checkerboards. Only the single 4 by 8 sprite sheet on genuine transparent alpha.

## Directional human run prompt

Use case: stylized-concept.
Reference: preserve the two adventurers' exact sculpted 3D garden-game appearance, face, teal/plum clothing, backpacks, hair and proportions from the supplied image.
Asset type: ONE final DIRECTIONAL HUMAN RUN animation atlas, exact EIGHT columns by EIGHT rows, 64 equal square cells, square canvas at high resolution. Genuine transparent alpha, no labels or grid.
Each ROW is ONE complete 8-frame run cycle, all eight frames face the SAME direction. Exact rows:
1 MALE running SOUTH toward the viewer, face and chest visible.
2 MALE running EAST toward the right, side/three-quarter face visible.
3 MALE running NORTH away from the viewer, back of head and backpack visible.
4 MALE running WEST toward the left, side/three-quarter face visible.
5 FEMALE running SOUTH toward the viewer.
6 FEMALE running EAST toward the right.
7 FEMALE running NORTH away from the viewer, ponytail and backpack visible.
8 FEMALE running WEST toward the left.
Same elevated 55-degree downward camera for every sprite, grounded upright humans suited to a top-down garden maze. NORTH means back-facing, SOUTH means front-facing. Never rotate a human onto their side.
Eight frames left-to-right are a REAL RUN CYCLE with clearly alternating legs and arms: right-foot contact, recoil compression, left-knee high passing pose, left-leg extension flight, left-foot contact, recoil compression, right-knee high passing pose, right-leg extension flight. Opposite arms swing forward/back. Frame 5 must have the OPPOSITE leading foot to frame 1. Frames must not be repeated standing poses. Use clear separate legs and feet with visible stride and bent knees.
The SAME man/woman throughout: adult male with short dark hair, teal jacket, navy trousers, tan shoes, tan backpack; adult female dark ponytail, plum jacket, navy trousers, tan shoes, tan backpack. Soft warm upper-left light and rounded clean naturalistic 3D mobile-game materials.
Alignment: hip center stays at same pixel location in every cell and every direction. Same ground baseline and same human height. Entire body and limbs contained in central 84% of each cell with transparent gutters, no overlap, no clipping.
No animals, floors, scenery, shadows, text, arrows, grid lines, white outlines, colored backgrounds or checkerboards. Deliver the single uniform 8-column by 8-row transparent directional running atlas.

## Directional human idle prompt

Use case: stylized-concept.
Reference image supplies exact two human adventurers' sculpted 3D garden-game appearance, faces, teal/plum clothing, backpacks and hair.
Asset type: ONE small IDLE DIRECTION sprite atlas, exactly FOUR columns and TWO rows, eight equal square cells, wide canvas aspect ratio 2:1. True transparent alpha.
Row 1: same adult male adventurer, four standing directions left-to-right SOUTH (front), EAST (right), NORTH (back), WEST (left).
Row 2: same adult female adventurer, same directions SOUTH, EAST, NORTH, WEST.
Elevated 55-degree camera looking downward, upright natural human bodies standing ON the ground. Each character stands in a relaxed ready stance with BOTH feet firmly on the same ground baseline, legs separated slightly, arms relaxed, NO running pose, no lifted knee. Consistent body center and scale in all cells.
Male: short dark hair, teal jacket, navy trousers, tan shoes and tan backpack. Female: dark ponytail, plum jacket, navy trousers, tan shoes, tan backpack. Preserve same identity, proportions, soft warm top-left lighting and clean rounded 3D materials as reference.
Each entire person centered in central 84% of their square cell with generous transparent gutters. No animals, shadows, outlines, floors, scenery, text, labels, arrows, grid lines, backgrounds or checkerboards. Only this one uniform 4 by 2 transparent idle atlas.
