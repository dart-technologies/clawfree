#!/usr/bin/env python3
"""
合成 MyChat 三設備 Demo 視頻
將 Watch | iPhone | macOS 三個視頻並排合成為一個視頻
"""

import os
import subprocess
import sys
from pathlib import Path

# 設定
DEMO_DIR = Path(__file__).parent / "demo_videos"
WATCH_VIDEO = DEMO_DIR / "watch_demo_v8_no_control_20260216_223714.mp4"
OUTPUT_VIDEO = DEMO_DIR / "mychat_3device_demo_final.mp4"

def get_latest_demo(pattern: str):
    """取得最新的 demo 視頻檔案"""
    files = sorted(DEMO_DIR.glob(pattern), key=lambda x: x.stat().st_mtime, reverse=True)
    if not files:
        print(f"❌ 找不到符合 {pattern} 的檔案")
        return None
    return files[0]

def get_video_info(video_path: Path):
    """取得視頻資訊（寬度、高度、時長）"""
    cmd = [
        "ffprobe", "-v", "error",
        "-select_streams", "v:0",
        "-show_entries", "stream=width,height,duration",
        "-show_entries", "format=duration",
        "-of", "csv=p=0",
        str(video_path)
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ 無法取得 {video_path.name} 的資訊")
        return None
    
    lines = result.stdout.strip().split('\n')
    width, height, *rest = lines[0].split(',')
    duration = lines[-1] if len(lines) > 1 else rest[0] if rest else "0"
    
    return {
        'width': int(width),
        'height': int(height),
        'duration': float(duration)
    }

def merge_videos(watch_path: Path, iphone_path: Path, macos_path: Path, output_path: Path):
    """合成三個視頻為並排格式"""
    print("📊 分析視頻資訊...")
    
    watch_info = get_video_info(watch_path)
    iphone_info = get_video_info(iphone_path)
    macos_info = get_video_info(macos_path)
    
    if not all([watch_info, iphone_info, macos_info]):
        return False
    
    print(f"   Watch:  {watch_info['width']}x{watch_info['height']} ({watch_info['duration']:.2f}s)")
    print(f"   iPhone: {iphone_info['width']}x{iphone_info['height']} ({iphone_info['duration']:.2f}s)")
    print(f"   macOS:  {macos_info['width']}x{macos_info['height']} ({macos_info['duration']:.2f}s)")
    print()
    
    # 計算目標高度（使用最大高度）
    target_height = max(watch_info['height'], iphone_info['height'], macos_info['height'])
    
    # 計算縮放後的寬度（保持比例）
    watch_scale_width = int(watch_info['width'] * target_height / watch_info['height'])
    iphone_scale_width = int(iphone_info['width'] * target_height / iphone_info['height'])
    macos_scale_width = int(macos_info['width'] * target_height / macos_info['height'])
    
    total_width = watch_scale_width + iphone_scale_width + macos_scale_width
    
    print(f"📐 輸出尺寸: {total_width}x{target_height}")
    print()
    
    # 使用最短的視頻時長
    min_duration = min(watch_info['duration'], iphone_info['duration'], macos_info['duration'])
    print(f"⏱️  使用時長: {min_duration:.2f}s")
    print()
    
    print("🎬 開始合成視頻...")
    
    # FFmpeg 命令：並排三個視頻
    # 1. 縮放所有視頻到相同高度
    # 2. 水平排列（Watch | iPhone | macOS）
    # 3. 截取到最短時長
    cmd = [
        "ffmpeg", "-y",
        "-i", str(watch_path),
        "-i", str(iphone_path),
        "-i", str(macos_path),
        "-filter_complex",
        f"[0:v]scale={watch_scale_width}:{target_height}[v0];"
        f"[1:v]scale={iphone_scale_width}:{target_height}[v1];"
        f"[2:v]scale={macos_scale_width}:{target_height}[v2];"
        f"[v0][v1][v2]hstack=inputs=3[v]",
        "-map", "[v]",
        "-t", str(min_duration),
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "23",
        "-pix_fmt", "yuv420p",
        str(output_path)
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"❌ FFmpeg 錯誤:")
        print(result.stderr)
        return False
    
    print(f"✅ 合成完成: {output_path}")
    print()
    
    # 顯示輸出檔案資訊
    if output_path.exists():
        size_mb = output_path.stat().st_size / 1024 / 1024
        print(f"📁 檔案大小: {size_mb:.2f} MB")
        output_info = get_video_info(output_path)
        if output_info:
            print(f"📊 輸出尺寸: {output_info['width']}x{output_info['height']}")
            print(f"⏱️  時長: {output_info['duration']:.2f}s")
    
    return True

def main():
    print("🎬 MyChat 三設備 Demo 視頻合成")
    print("=" * 50)
    print()
    
    # 檢查 Watch demo
    if not WATCH_VIDEO.exists():
        print(f"❌ Watch demo 不存在: {WATCH_VIDEO}")
        return 1
    
    print(f"✅ Watch demo: {WATCH_VIDEO.name}")
    
    # 尋找最新的 iPhone demo
    iphone_video = get_latest_demo("iphone_demo_*.mp4")
    if not iphone_video:
        print("❌ 找不到 iPhone demo")
        print("   請先執行: ./record_three_device_demo.sh")
        return 1
    
    print(f"✅ iPhone demo: {iphone_video.name}")
    
    # 尋找最新的 macOS demo
    macos_video = get_latest_demo("macos_demo_*.mp4")
    if not macos_video:
        print("❌ 找不到 macOS demo")
        print("   請先執行: ./record_macos_demo.sh")
        return 1
    
    print(f"✅ macOS demo: {macos_video.name}")
    print()
    
    # 合成視頻
    if merge_videos(WATCH_VIDEO, iphone_video, macos_video, OUTPUT_VIDEO):
        print()
        print("🎉 完成！")
        print(f"📦 輸出檔案: {OUTPUT_VIDEO}")
        print()
        print("💡 下一步:")
        print("   1. 播放視頻確認效果")
        print("   2. 傳送到 Telegram Topic 9062")
        print()
        print("   傳送指令:")
        print(f"   message(action=send, filePath='{OUTPUT_VIDEO}', threadId=9062)")
        return 0
    else:
        return 1

if __name__ == "__main__":
    sys.exit(main())
