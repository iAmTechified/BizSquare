import os
from PIL import Image

source_path = r"c:\Users\User\Desktop\wm4b\BizSquare NO BG.png"
base_dir = r"c:\Users\User\Desktop\wm4b"

print(f"Loading source image from: {source_path}")
img = Image.open(source_path).convert("RGBA")

# 1. Save master icons in assets
assets_targets = [
    os.path.join(base_dir, "mobile", "assets", "images", "bizsquare_icon.png"),
    os.path.join(base_dir, "mobile", "assets", "images", "bizsquare_icon_nobg.png"),
    os.path.join(base_dir, "mobile", "assets", "icons", "bizsquare_icon.png"),
    os.path.join(base_dir, "mobile", "android", "app", "src", "main", "res", "drawable", "bizsquare_icon.png"),
]

for target in assets_targets:
    os.makedirs(os.path.dirname(target), exist_ok=True)
    master = img.resize((512, 512), Image.Resampling.LANCZOS)
    master.save(target, "PNG")
    print(f"Saved master icon: {target}")

# 2. Notification icon (96x96)
notif_target = os.path.join(base_dir, "mobile", "android", "app", "src", "main", "res", "drawable", "ic_notification.png")
notif = img.resize((96, 96), Image.Resampling.LANCZOS)
notif.save(notif_target, "PNG")
print(f"Saved notification icon: {notif_target}")

# 3. Android Mipmap standard launcher icons & round icons
mipmap_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, size in mipmap_sizes.items():
    dir_path = os.path.join(base_dir, "mobile", "android", "app", "src", "main", "res", folder)
    os.makedirs(dir_path, exist_ok=True)
    
    # Standard launcher icon
    launcher_path = os.path.join(dir_path, "ic_launcher.png")
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(launcher_path, "PNG")
    print(f"Saved {folder}/ic_launcher.png ({size}x{size})")

    # Round launcher icon
    round_path = os.path.join(dir_path, "ic_launcher_round.png")
    resized.save(round_path, "PNG")
    print(f"Saved {folder}/ic_launcher_round.png ({size}x{size})")

# 4. Android Adaptive Icon Foregrounds (108dp base grid, centered with safe zone)
adaptive_sizes = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}

for folder, size in adaptive_sizes.items():
    dir_path = os.path.join(base_dir, "mobile", "android", "app", "src", "main", "res", folder)
    os.makedirs(dir_path, exist_ok=True)
    
    fg_canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    # Inner logo size is ~72% of total canvas for adaptive icon safe zone
    logo_size = int(size * 0.72)
    inner_logo = img.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    offset = (size - logo_size) // 2
    fg_canvas.paste(inner_logo, (offset, offset), inner_logo)
    
    fg_path = os.path.join(dir_path, "ic_launcher_foreground.png")
    fg_canvas.save(fg_path, "PNG")
    print(f"Saved {folder}/ic_launcher_foreground.png ({size}x{size})")

print("All icons successfully generated and saved!")
