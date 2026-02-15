#!/bin/bash
# 自动截图序列（模拟动画）
for i in {1..30}; do
  /usr/sbin/screencapture -x -T 0 frames/frame_$(printf "%03d" $i).png
  sleep 1
done
# 合成视频
ffmpeg -framerate 1 -pattern_type glob -i 'frames/*.png' -c:v libx264 -pix_fmt yuv420p -y four_devices_demo.mp4
