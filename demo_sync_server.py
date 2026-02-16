#!/usr/bin/env python3
"""
三設備同步 Demo 伺服器
=====================
- HTTP POST /message ← Watch App 發送訊息
- WebSocket /ws ← iPhone + macOS Flutter App 接收訊息
- 接收 Watch 訊息後廣播給所有 WebSocket 客戶端

啟動方式：python3 demo_sync_server.py
預設埠號：8080
"""

import asyncio
import json
import logging
from datetime import datetime
from aiohttp import web

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

# 所有已連線的 WebSocket 客戶端
ws_clients: set[web.WebSocketResponse] = set()


async def handle_message(request: web.Request) -> web.Response:
    """處理 Watch App 發送的 HTTP POST 訊息，廣播給所有 WebSocket 客戶端"""
    global ws_clients
    try:
        data = await request.json()
        text = data.get('text', '')
        is_user = data.get('isUser', True)
        source = data.get('source', 'watch')

        msg = json.dumps({
            'type': 'chat_message',
            'text': text,
            'isUser': is_user,
            'source': source,
            'timestamp': datetime.now().isoformat(),
        })

        logger.info(f'📨 收到訊息 [{source}]: "{text[:60]}" → 廣播給 {len(ws_clients)} 個客戶端')

        # 廣播給所有 WebSocket 客戶端
        disconnected = set()
        for ws in ws_clients:
            try:
                await ws.send_str(msg)
            except Exception:
                disconnected.add(ws)
        ws_clients -= disconnected

        return web.json_response({'status': 'ok', 'broadcast_count': len(ws_clients)})

    except Exception as e:
        logger.error(f'❌ 處理訊息失敗: {e}')
        return web.json_response({'error': str(e)}, status=400)


async def handle_ws(request: web.Request) -> web.WebSocketResponse:
    """處理 WebSocket 連線（iPhone / macOS Flutter App）"""
    ws = web.WebSocketResponse()
    await ws.prepare(request)

    ws_clients.add(ws)
    client_id = f'{request.remote}:{id(ws)}'
    logger.info(f'🔗 WebSocket 連線: {client_id} (目前 {len(ws_clients)} 個客戶端)')

    # 發送歡迎訊息
    await ws.send_str(json.dumps({
        'type': 'system',
        'text': 'Connected to Demo Sync Server',
        'timestamp': datetime.now().isoformat(),
    }))

    try:
        async for msg in ws:
            if msg.type == web.WSMsgType.TEXT:
                logger.info(f'📩 WebSocket 收到: {msg.data[:80]}')
            elif msg.type == web.WSMsgType.ERROR:
                logger.error(f'❌ WebSocket 錯誤: {ws.exception()}')
    finally:
        ws_clients.discard(ws)
        logger.info(f'🔌 WebSocket 斷線: {client_id} (剩餘 {len(ws_clients)} 個客戶端)')

    return ws


async def handle_health(request: web.Request) -> web.Response:
    """健康檢查端點"""
    return web.json_response({
        'status': 'ok',
        'clients': len(ws_clients),
        'timestamp': datetime.now().isoformat(),
    })


def create_app() -> web.Application:
    app = web.Application()
    app.router.add_post('/message', handle_message)
    app.router.add_get('/ws', handle_ws)
    app.router.add_get('/health', handle_health)
    return app


if __name__ == '__main__':
    PORT = 8080
    logger.info(f'🚀 Demo Sync Server 啟動中...')
    logger.info(f'   HTTP POST  → http://localhost:{PORT}/message')
    logger.info(f'   WebSocket  → ws://localhost:{PORT}/ws')
    logger.info(f'   健康檢查   → http://localhost:{PORT}/health')
    web.run_app(create_app(), port=PORT)
