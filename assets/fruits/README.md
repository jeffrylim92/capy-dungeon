# Fruit images

Drop fruit artwork here using the fruit ID as the filename. Recognised IDs:

- `apple.png`
- `carrot.png`
- `berry.png`
- `leaf.png`

## Format

| Property | Recommended |
|---|---|
| Format | **PNG** (with alpha) — also accepts `.webp`, `.jpg`, `.svg` |
| Background | Transparent |
| Dimensions | Square, **128×128** or **256×256** |
| Aspect | Doesn't have to be exactly square — the sprite is auto-scaled so its longest side is ~100 px on screen |

Tap hitbox stays 90×90 px regardless of art size (defined on `Fruit.tscn`'s `CollisionShape2D`). If your art is much bigger than that you may want to widen the collision shape for easier tapping.

If a fruit ID has no matching image, the coloured-square placeholder is shown instead — so you can ship art for one fruit at a time.
