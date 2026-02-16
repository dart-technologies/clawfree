#!/usr/bin/env python3
"""
測試三設備同步 Demo
===================
模擬 Watch App 發送完整的 12 步對話到 WebSocket 服務器
用於測試 iPhone + macOS 是否能正確接收訊息並展示 genUI

使用方式：python3 test_demo_sync.py
"""

import requests
import time
import sys

# Demo 腳本（與 Watch 一致的 12 步）
DEMO_SCRIPT = [
    # Step 2: User speaks
    {"text": "Plan a 3-day foodie trip to Tokyo", "isUser": True, "delay": 5.0},
    
    # Step 3: AI Thinking (skip - no text)
    
    # Step 4: Agent created
    {"text": "I've created a Travel Concierge Agent with Claude Opus 4.6, all tools and channels enabled.", "isUser": False, "delay": 8.0},
    
    # Step 5: User confirms
    {"text": "OK, confirm", "isUser": True, "delay": 1.5},
    
    # Step 6: Agent saved
    {"text": "✓ Agent saved successfully!", "isUser": False, "delay": 2.0},
    
    # Step 7: AI starts planning
    {"text": "Perfect! I'll start planning your 3-day foodie trip to Tokyo now.", "isUser": False, "delay": 2.5},
    
    # Step 8: User requests itinerary
    {"text": "Generate Itinerary", "isUser": True, "delay": 1.5},
    
    # Step 8b: AI thinking (skip - no text)
    
    # Step 9: Itinerary ready
    {"text": "Here's your Tokyo foodie adventure:\n\n• Day 1: Tsukiji Market\n• Day 2: Ramen masterclass\n• Day 3: Michelin kaiseki\n\nFlight: ANA ✓\nHotel: Hoshinoya Tokyo", "isUser": False, "delay": 8.0},
    
    # Step 10: User books trip
    {"text": "Book Trip", "isUser": True, "delay": 1.5},
    
    # Step 11: Booking in progress
    {"text": "Booking your trip now...", "isUser": False, "delay": 2.0},
    
    # Step 12: Complete (shown on Watch only, not sent to server)
]

def send_message(text: str, is_user: bool) -> bool:
    """發送訊息到 WebSocket 服務器"""
    try:
        response = requests.post(
            'http://localhost:8080/message',
            json={
                'text': text,
                'isUser': is_user,
                'source': 'test_script'
            },
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ 已發送: [{('使用者' if is_user else 'AI')}] {text[:60]}...")
            print(f"   廣播給 {data.get('broadcast_count', 0)} 個客戶端")
            return True
        else:
            print(f"❌ 發送失敗: HTTP {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ 發送失敗: {e}")
        return False

def main():
    print("🎬 開始執行 Demo 同步測試")
    print("=" * 60)
    print()
    
    # 檢查服務器健康狀態
    try:
        response = requests.get('http://localhost:8080/health', timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ WebSocket 服務器運行中")
            print(f"   已連接客戶端: {data.get('clients', 0)}")
            print()
        else:
            print("❌ WebSocket 服務器無法連接")
            sys.exit(1)
    except Exception as e:
        print(f"❌ 無法連接到 WebSocket 服務器: {e}")
        print("   請先啟動: python3 demo_sync_server.py")
        sys.exit(1)
    
    print("開始發送 12 步 Demo 訊息...")
    print()
    
    # 執行 Demo 腳本
    step = 1
    for msg in DEMO_SCRIPT:
        print(f"第 {step} 步:")
        
        if send_message(msg['text'], msg['isUser']):
            delay = msg.get('delay', 2.0)
            print(f"   等待 {delay} 秒...")
            time.sleep(delay)
            step += 1
        else:
            print("❌ 發送失敗，中止測試")
            sys.exit(1)
        
        print()
    
    print("=" * 60)
    print("🎉 Demo 測試完成！")
    print()
    print("請檢查 iPhone + macOS 是否：")
    print("1. 顯示所有對話訊息")
    print("2. 正確觸發 genUI：")
    print("   - 'Plan trip' → Agent Creation Form")
    print("   - 'Generate Itinerary' → Itinerary View")
    print("   - 'Book Trip' → Booking Confirmation")

if __name__ == '__main__':
    main()
