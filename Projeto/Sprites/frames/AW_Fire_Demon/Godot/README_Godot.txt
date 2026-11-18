AW - FIRE DEMON: GODOT 4 FILES (tested in Godot 4.7.2)

HOW TO USE
1. Copy the WHOLE pack folder (AW_Fire_Demon_Complete_v1.0) anywhere inside your Godot project.
   Keep the folder structure: these files point to ../<Palette>/... with relative paths.
2. Project Settings > Rendering > Textures > Default Texture Filter = Nearest (pixel art).
3. Open Godot/Demon_Example.tscn and press F6: it plays all 10 animations and the Attack -> Attack2 combo.

FILES
Demon_<Palette>.tres         SpriteFrames, With_FX   (Ember, Azure, Venom, Obsidian)
Demon_<Palette>_NoFX.tres    SpriteFrames, body only
Demon_<Palette>_FXOnly.tres  SpriteFrames, effect layer only (RunToIdle, Attack, Attack2): draw it above No_FX
Demon_Shadow.tres            SpriteFrames, shadow: draw it below the body, modulate alpha ~0.35
Demon_Example.tscn / demon_example.gd   example scene

SETUP OF AN AnimatedSprite2D
- centered = Off, offset = (-59, -108): the node position is then the FEET pivot, for every animation
  (the wider Attack/Attack2/Death cells grow only to the right).
- Every animation runs at 100 FPS with a per-frame duration = ms / 10, so the variable frame times of
  Data/demon.json are already applied. Do not change the speed unless you want the whole animation faster.
- Loop is on for Idle, Walk and Run only. Use the animation_finished signal for the rest.
- Walk speed 74 px/s, Run speed 193 px/s (at 1x) so the feet do not slide.
- Hit frames, hitboxes and the cancel window are in Data/demon.json and Animation_Guide.txt.
