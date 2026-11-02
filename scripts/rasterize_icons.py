import os
import shutil
from playwright.sync_api import sync_playwright
from PIL import Image

svg_dir = r"keylire\assets\icon"
svgs = ["icon_full", "icon_foreground", "icon_monochrome"]

with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe")
    for name in svgs:
        svg_path = os.path.join(svg_dir, f"{name}.svg")
        png_path = os.path.join(svg_dir, f"{name}.png")
        with open(svg_path, "r", encoding="utf-8") as f:
            svg_content = f.read()
        
        html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
html, body {{ width: 1024px; height: 1024px; overflow: hidden; background: transparent; }}
svg {{ display: block; width: 1024px; height: 1024px; }}
</style>
</head>
<body>
{svg_content}
</body>
</html>"""
        page = browser.new_page(viewport={"width": 1024, "height": 1024}, device_scale_factor=1)
        page.set_content(html)
        page.screenshot(path=png_path, omit_background=True)
        page.close()
        im = Image.open(png_path)
        print(f"{name}.png generated: size={im.size}, mode={im.mode}")
    browser.close()

# Replace root keylire_icon.png and assets/icon/keylire_icon.png
shutil.copyfile(os.path.join(svg_dir, "icon_full.png"), "keylire_icon.png")
shutil.copyfile(os.path.join(svg_dir, "icon_full.png"), os.path.join(svg_dir, "keylire_icon.png"))
print("Replaced keylire_icon.png in root and assets/icon/")

