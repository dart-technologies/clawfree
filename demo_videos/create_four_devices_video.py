#!/usr/bin/env python3
"""
合成四装置并排的影片
"""
from PIL import Image, ImageDraw, ImageFont
import os

def create_combined_frame(output_path):
    """创建四装置并排画面"""
    
    # 加载装置 mockups
    watch = Image.open('mockups/watch_mockup.png')
    iphone = Image.open('mockups/iphone_mockup.png')
    ipad = Image.open('mockups/ipad_mockup.png')
    
    # 创建 MacBook mockup（用之前的静态画面）
    macbook_width = 600
    macbook_height = 400
    macbook = Image.new('RGB', (macbook_width, macbook_height), '#2c2c2e')
    draw = ImageDraw.Draw(macbook)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 20)
        label_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
    except:
        font = ImageFont.load_default()
        label_font = font
    
    # MacBook 标签
    draw.text((macbook_width//2 - 60, 10), '💻 MacBook', fill='#888', font=label_font)
    
    # MacBook 内容（Chat + genUI）
    draw.text((macbook_width//2 - 80, macbook_height//2 - 40), 
              'Chat + genUI', fill='white', font=font)
    draw.text((macbook_width//2 - 100, macbook_height//2), 
              '🤖 Create Agent', fill='#007aff', font=label_font)
    draw.text((macbook_width//2 - 90, macbook_height//2 + 30), 
              '✈️ Plan a Trip', fill='#007aff', font=label_font)
    
    # 统一高度（以最高的装置为准）
    max_height = max(watch.height, iphone.height, macbook.height, ipad.height)
    
    # 调整装置尺寸使高度一致
    def resize_to_height(img, target_height):
        ratio = target_height / img.height
        new_width = int(img.width * ratio)
        return img.resize((new_width, target_height))
    
    target_height = 600  # 统一高度
    watch = resize_to_height(watch, target_height)
    iphone = resize_to_height(iphone, target_height)
    macbook = resize_to_height(macbook, target_height)
    ipad = resize_to_height(ipad, target_height)
    
    # 计算总宽度
    gap = 30
    total_width = watch.width + iphone.width + macbook.width + ipad.width + gap * 5
    total_height = target_height + 100
    
    # 创建画布
    canvas = Image.new('RGB', (total_width, total_height), '#1a1a1a')
    
    # 添加标题
    draw = ImageDraw.Draw(canvas)
    try:
        title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
    except:
        title_font = font
    title = "🎬 Clawfree 四裝置同步 Demo"
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    draw.text((total_width//2 - title_width//2, 30), title, fill='white', font=title_font)
    
    # 粘贴装置
    y_offset = 80
    x = gap
    canvas.paste(watch, (x, y_offset))
    x += watch.width + gap
    canvas.paste(iphone, (x, y_offset))
    x += iphone.width + gap
    canvas.paste(macbook, (x, y_offset))
    x += macbook.width + gap
    canvas.paste(ipad, (x, y_offset))
    
    canvas.save(output_path)
    return output_path

# 创建多帧（模拟动画）
if __name__ == '__main__':
    os.chdir('/Users/roypctw/dev/clawfree/demo_videos')
    
    # 创建单帧（静态）
    output = 'four_devices_with_frames.png'
    create_combined_frame(output)
    print(f"✅ 四装置合成完成：{output}")
    
    # 复制多份作为视频帧（30 帧 = 30 秒 @ 1fps）
    os.makedirs('video_frames', exist_ok=True)
    base_img = Image.open(output)
    for i in range(1, 31):
        base_img.save(f'video_frames/frame_{i:03d}.png')
    
    print(f"✅ 已生成 30 帧视频帧")
    print("⏳ 正在合成视频...")
