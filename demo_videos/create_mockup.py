#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

# 设置路径
base_dir = "/Users/roypctw/dev/clawfree/demo_videos"
os.chdir(base_dir)

# 加载截图
watch = Image.open("watch_screen.png")
iphone = Image.open("iphone_screen.png")
ipad = Image.open("ipad_screen.png")

# 调整大小
target_height = 500
watch = watch.resize((int(watch.width * target_height / watch.height), target_height))
iphone = iphone.resize((int(iphone.width * target_height / iphone.height), target_height))
ipad = ipad.resize((int(ipad.width * target_height / ipad.height), target_height))

# 创建 MacBook 占位图
macbook_width = iphone.width
macbook = Image.new('RGB', (macbook_width, target_height), color='#1c1c1e')
draw = ImageDraw.Draw(macbook)
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 40)
except:
    font = ImageFont.load_default()
text = "💻 MacBook\nChat + genUI"
draw.multiline_text((macbook_width//2, target_height//2), text, 
                     fill='white', font=font, anchor='mm', align='center')

# 计算总宽度
total_width = watch.width + iphone.width + macbook.width + ipad.width + 60  # 间距
total_height = target_height + 100  # 标题空间

# 创建画布
canvas = Image.new('RGB', (total_width, total_height), color='#1a1a1a')

# 粘贴装置截图
x_offset = 20
y_offset = 80
canvas.paste(watch, (x_offset, y_offset))
x_offset += watch.width + 10
canvas.paste(iphone, (x_offset, y_offset))
x_offset += iphone.width + 10
canvas.paste(macbook, (x_offset, y_offset))
x_offset += macbook.width + 10
canvas.paste(ipad, (x_offset, y_offset))

# 添加标题
draw = ImageDraw.Draw(canvas)
try:
    title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 50)
except:
    title_font = ImageFont.load_default()
title = "🎬 Clawfree 四裝置同步 Demo"
draw.text((total_width//2, 40), title, fill='white', font=title_font, anchor='mm')

# 添加装置标签
try:
    label_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 20)
except:
    label_font = ImageFont.load_default()
labels = ["⌚ Watch", "📱 iPhone", "💻 MacBook", "📱 iPad"]
x_positions = [20 + watch.width//2, 
               30 + watch.width + iphone.width//2,
               40 + watch.width + iphone.width + macbook.width//2,
               50 + watch.width + iphone.width + macbook.width + ipad.width//2]
for label, x_pos in zip(labels, x_positions):
    draw.text((x_pos, 60), label, fill='#aaaaaa', font=label_font, anchor='mm')

# 保存
canvas.save("four_devices_mockup.png")
print(f"✅ Mockup 已生成：{os.path.getsize('four_devices_mockup.png')} bytes")
