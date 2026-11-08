"""Render the home header's Material icon as launcher artwork.

Requires Pillow and the Flutter SDK on PATH. After running this script, run
`dart run flutter_launcher_icons` to regenerate the platform icons.
"""

from pathlib import Path
import re
import shutil

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
GOLD = "#FFC23D"
NIGHT = "#1E1846"


def main():
    flutter = shutil.which("flutter")
    if flutter is None:
        raise SystemExit("Flutter must be on PATH.")
    sdk = Path(flutter).resolve().parent.parent
    icons = (sdk / "packages/flutter/lib/src/material/icons.dart").read_text()
    codepoint = re.search(
        r"call_split_rounded = IconData\(\s*(0x[0-9a-f]+)", icons
    )
    if codepoint is None:
        raise SystemExit("Could not find Icons.call_split_rounded in Flutter.")
    font = ImageFont.truetype(
        str(sdk / "bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf"),
        round(SIZE * 28 / 44),
    )
    glyph = chr(int(codepoint.group(1), 16))
    bounds = font.getbbox(glyph)
    mask = Image.new("L", (bounds[2] - bounds[0], bounds[3] - bounds[1]))
    ImageDraw.Draw(mask).text(
        (-bounds[0], -bounds[1]), glyph, font=font, fill=255
    )
    mask = mask.crop(mask.getbbox())
    foreground = Image.new("RGBA", (SIZE, SIZE))
    position = ((SIZE - mask.width) // 2, (SIZE - mask.height) // 2)
    foreground.paste(NIGHT, position, mask)
    icon = Image.new("RGBA", (SIZE, SIZE), GOLD)
    icon.alpha_composite(foreground)
    output = ROOT / "assets/branding"
    output.mkdir(parents=True, exist_ok=True)
    icon.convert("RGB").save(output / "wayout_icon.png")
    foreground.save(output / "wayout_icon_foreground.png")
    icon.convert("RGB").resize((512, 512), Image.Resampling.LANCZOS).save(
        output / "google_play_icon_512.png"
    )
    print("Rendered the home header icon in gold and dark purple.")


if __name__ == "__main__":
    main()
