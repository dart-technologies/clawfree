#!/usr/bin/env python3
"""
生成 App Icon 的 Dark/Light/Tinted 三組版本
© 2026 Rollbytes Inc. All rights reserved.
"""

from PIL import Image, ImageFilter, ImageDraw, ImageChops
import os

# 品牌色
DARK_BG = (26, 26, 26)  # #1A1A1A
LIGHT_BG = (245, 245, 245)  # #F5F5F5
LOBSTER_ORANGE = (255, 107, 53)  # #FF6B35
TEAL = (0, 191, 165)  # #00BFA5

# 需要生成的尺寸
SIZES = [
    (20, 20, 2), (20, 20, 3),  # iPhone 20pt
    (29, 29, 1), (29, 29, 2), (29, 29, 3),  # iPhone 29pt
    (40, 40, 2), (40, 40, 3),  # iPhone 40pt
    (60, 60, 2), (60, 60, 3),  # iPhone 60pt
    (20, 20, 1),  # iPad 20pt
    (40, 40, 1),  # iPad 40pt
    (76, 76, 1), (76, 76, 2),  # iPad 76pt
    (83.5, 83.5, 2),  # iPad Pro
    (1024, 1024, 1),  # App Store
]

def remove_white_bg(img):
    """移除白色背景，返回帶 alpha 的圖片"""
    img = img.convert("RGBA")
    data = img.getdata()
    
    new_data = []
    for item in data:
        # 如果是白色或接近白色 (threshold 240)
        if item[0] > 240 and item[1] > 240 and item[2] > 240:
            new_data.append((255, 255, 255, 0))  # 透明
        else:
            new_data.append(item)
    
    img.putdata(new_data)
    return img

def create_dark_version(original_img):
    """Dark 版本：深色背景 + 原龍蝦 + 微妙 glow"""
    # 移除白底
    lobster = remove_white_bg(original_img)
    
    # 建立深色背景
    dark = Image.new("RGBA", lobster.size, DARK_BG + (255,))
    
    # 加上微妙的 orange glow（先模糊龍蝦的輪廓）
    glow = Image.new("RGBA", lobster.size, (0, 0, 0, 0))
    glow.paste(lobster, (0, 0), lobster)
    
    # 將 glow 改成 orange 色調
    glow_data = glow.getdata()
    new_glow = []
    for item in glow_data:
        if item[3] > 0:  # 非透明
            new_glow.append(LOBSTER_ORANGE + (int(item[3] * 0.3),))  # 30% opacity
        else:
            new_glow.append(item)
    glow.putdata(new_glow)
    
    # 模糊 glow
    glow = glow.filter(ImageFilter.GaussianBlur(radius=15))
    
    # 合成：背景 → glow → 龍蝦
    dark.paste(glow, (0, 0), glow)
    dark.paste(lobster, (0, 0), lobster)
    
    return dark.convert("RGB")

def create_light_version(original_img):
    """Light 版本：淺色背景 + 龍蝦 + 陰影"""
    lobster = remove_white_bg(original_img)
    
    # 建立淺色背景
    light = Image.new("RGBA", lobster.size, LIGHT_BG + (255,))
    
    # 建立陰影（偏移 + 模糊）
    shadow = Image.new("RGBA", lobster.size, (0, 0, 0, 0))
    shadow.paste(lobster, (5, 5), lobster)  # 向右下偏移 5px
    
    # 將陰影改成灰色半透明
    shadow_data = shadow.getdata()
    new_shadow = []
    for item in shadow_data:
        if item[3] > 0:
            new_shadow.append((50, 50, 50, int(item[3] * 0.2)))  # 20% opacity 灰影
        else:
            new_shadow.append(item)
    shadow.putdata(new_shadow)
    
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=8))
    
    # 合成：背景 → 陰影 → 龍蝦
    light.paste(shadow, (0, 0), shadow)
    light.paste(lobster, (0, 0), lobster)
    
    return light.convert("RGB")

def create_tinted_version(original_img):
    """Tinted 版本：單色剪影（orange）+ 深色背景"""
    lobster = remove_white_bg(original_img)
    
    # 建立深色背景
    tinted = Image.new("RGBA", lobster.size, DARK_BG + (255,))
    
    # 將龍蝦轉成 orange 剪影
    silhouette = Image.new("RGBA", lobster.size, (0, 0, 0, 0))
    silhouette_data = []
    
    for item in lobster.getdata():
        if item[3] > 100:  # 非透明（保留原 alpha）
            silhouette_data.append(LOBSTER_ORANGE + (item[3],))
        else:
            silhouette_data.append((0, 0, 0, 0))
    
    silhouette.putdata(silhouette_data)
    
    # 合成
    tinted.paste(silhouette, (0, 0), silhouette)
    
    return tinted.convert("RGB")

def generate_all_sizes(base_img, output_dir, prefix):
    """生成所有需要的尺寸"""
    os.makedirs(output_dir, exist_ok=True)
    
    for w, h, scale in SIZES:
        size = int(w * scale), int(h * scale)
        resized = base_img.resize(size, Image.Resampling.LANCZOS)
        
        # 檔名格式：Icon-App-20x20@2x.png
        if w == int(w):
            w_str = str(int(w))
        else:
            w_str = str(w)
        if h == int(h):
            h_str = str(int(h))
        else:
            h_str = str(h)
        
        filename = f"{prefix}-{w_str}x{h_str}@{int(scale)}x.png"
        resized.save(os.path.join(output_dir, filename), "PNG")
        print(f"✓ {filename}")

def main():
    base_dir = "/Users/roypctw/dev/clawfree/ios/Runner/Assets.xcassets"
    original_path = f"{base_dir}/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
    
    print("📖 讀取原始 icon...")
    original = Image.open(original_path)
    
    print("\n🌙 生成 Dark 版本...")
    dark = create_dark_version(original)
    dark_dir = f"{base_dir}/AppIcon-Dark.appiconset"
    generate_all_sizes(dark, dark_dir, "Icon-App")
    
    print("\n☀️  生成 Light 版本（更新原有）...")
    light = create_light_version(original)
    light_dir = f"{base_dir}/AppIcon.appiconset"
    generate_all_sizes(light, light_dir, "Icon-App")
    
    print("\n🎨 生成 Tinted 版本...")
    tinted = create_tinted_version(original)
    tinted_dir = f"{base_dir}/AppIcon-Tinted.appiconset"
    generate_all_sizes(tinted, tinted_dir, "Icon-App")
    
    print("\n✅ 所有版本生成完成！")

if __name__ == "__main__":
    main()
