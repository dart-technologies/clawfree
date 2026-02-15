#!/usr/bin/env python3
"""
创建带装置外壳的 mockup 影片
"""
from PIL import Image, ImageDraw, ImageFont
import os

def create_device_frame(device_type, screen_img, output_path):
    """为截图添加装置边框"""
    
    # 装置规格 (外框 + 屏幕区域)
    specs = {
        'watch': {
            'frame_size': (400, 480),
            'screen_area': (320, 400),
            'screen_offset': (40, 60),
            'color': '#1c1c1e',
            'radius': 40,
            'label': '⌚ Apple Watch'
        },
        'iphone': {
            'frame_size': (400, 850),
            'screen_area': (360, 780),
            'screen_offset': (20, 50),
            'color': '#1c1c1e',
            'radius': 50,
            'label': '📱 iPhone'
        },
        'macbook': {
            'frame_size': (600, 400),
            'screen_area': (560, 350),
            'screen_offset': (20, 30),
            'color': '#2c2c2e',
            'radius': 10,
            'label': '💻 MacBook'
        },
        'ipad': {
            'frame_size': (500, 700),
            'screen_area': (460, 640),
            'screen_offset': (20, 40),
            'color': '#1c1c1e',
            'radius': 30,
            'label': '📱 iPad'
        }
    }
    
    spec = specs[device_type]
    
    # 创建边框
    frame = Image.new('RGB', spec['frame_size'], spec['color'])
    draw = ImageDraw.Draw(frame)
    
    # 添加圆角效果（简化版）
    # 实际应该用 ImageDraw.rounded_rectangle 但需要 PIL 9.0+
    
    # 调整屏幕截图大小
    screen = Image.open(screen_img)
    screen = screen.resize(spec['screen_area'])
    
    # 粘贴屏幕到边框中
    frame.paste(screen, spec['screen_offset'])
    
    # 添加标签
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
    except:
        font = ImageFont.load_default()
    
    text_bbox = draw.textbbox((0, 0), spec['label'], font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_x = (spec['frame_size'][0] - text_width) // 2
    draw.text((text_x, 10), spec['label'], fill='#888', font=font)
    
    frame.save(output_path)
    return output_path

# 主程序
if __name__ == '__main__':
    os.chdir('/Users/roypctw/dev/clawfree/demo_videos')
    
    # 为每个装置创建 mockup
    devices = {
        'watch': 'watch_screen.png',
        'iphone': 'iphone_screen.png',
        'ipad': 'ipad_screen.png'
    }
    
    os.makedirs('mockups', exist_ok=True)
    
    for device, screen_file in devices.items():
        if os.path.exists(screen_file):
            output = f'mockups/{device}_mockup.png'
            create_device_frame(device, screen_file, output)
            print(f"✅ {device} mockup 已创建：{output}")
    
    # MacBook 用特殊的 genUI 画面
    # 创建一个简单的 MacBook mockup（后面会替换成真实内容）
    print("✅ 所有 mockup 已准备完成")
