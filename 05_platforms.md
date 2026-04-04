# 05. 플랫폼 통합 가이드

## 채널 선택 가이드

| 플랫폼 | 추천도 | 설정 난이도 | 비용 | 자동화 친화도 |
|--------|--------|------------|------|--------------|
| **Telegram** | ⭐⭐⭐⭐⭐ | 쉬움 (3분) | 무료 | 매우 높음 |
| **Discord** | ⭐⭐⭐⭐ | 쉬움 (5분) | 무료 | 높음 |
| **Slack** | ⭐⭐⭐⭐ | 중간 (10분) | 무료/유료 | 높음 |
| **Signal** | ⭐⭐⭐ | 중간 | 무료 | 중간 |
| **WhatsApp** | ⭐⭐ | 어려움 | 유료 | **낮음 (차단 위험)** |
| **iMessage** | ⭐⭐⭐ | 중간 (macOS 전용) | 무료 | 중간 |

> **Telegram을 가장 먼저 연결하는 것을 강력 권장합니다.**  
> 공식 Bot API로 자동화 설계됨 → 차단 위험 없음, 무료, 빠른 설정.

---

## Telegram 설정

### 1단계: 봇 생성

1. Telegram에서 **@BotFather** 검색 및 대화 시작
2. `/newbot` 명령 전송
3. 봇 이름 입력 (예: `My OpenClaw`)
4. 봇 사용자명 입력 (예: `my_openclaw_bot`) — `_bot`으로 끝나야 함
5. 발급된 **토큰** 복사 (형식: `123456789:ABCdef...`)

### 2단계: 설정 파일 수정

```yaml
# ~/.openclaw/config.yaml
channels:
  telegram:
    enabled: true
    token: ${TELEGRAM_BOT_TOKEN}
    streaming: partial   # 실시간 타이핑 효과
```

```bash
# .env
TELEGRAM_BOT_TOKEN=123456789:ABCdef...
```

### 3단계: 재시작 및 테스트

```bash
openclaw restart
```

Telegram에서 봇에게 메시지를 보내면 응답합니다.

### Telegram 고급 설정

```yaml
channels:
  telegram:
    enabled: true
    token: ${TELEGRAM_BOT_TOKEN}
    streaming: partial
    allowed_users:          # 특정 사용자만 허용 (선택)
      - 123456789           # Telegram 사용자 ID
    allowed_groups: []      # 그룹 채팅 허용 목록
    parse_mode: Markdown    # HTML / Markdown / MarkdownV2
```

---

## Discord 설정

### 1단계: Discord Application 생성

1. [Discord Developer Portal](https://discord.com/developers/applications) 접속
2. **New Application** 클릭
3. 이름 입력 후 생성
4. 좌측 메뉴 **Bot** 클릭 → **Add Bot**
5. **Reset Token** → 토큰 복사
6. **Privileged Gateway Intents** 활성화:
   - `PRESENCE INTENT`
   - `SERVER MEMBERS INTENT`
   - `MESSAGE CONTENT INTENT` ← **반드시 활성화**

### 2단계: 봇 서버 초대

1. 좌측 **OAuth2** → **URL Generator**
2. `bot` 스코프 선택
3. Bot Permissions: `Send Messages`, `Read Message History`, `Add Reactions`
4. 생성된 URL로 봇을 서버에 초대

### 3단계: 설정 파일 수정

```yaml
channels:
  discord:
    enabled: true
    token: ${DISCORD_BOT_TOKEN}
    guild_ids:
      - "YOUR_SERVER_ID"    # 서버 ID (개발자 모드 활성화 후 우클릭)
```

```bash
DISCORD_BOT_TOKEN=MTxxxxxxx.Gxxxxx.xxxxx
```

---

## Slack 설정

### 1단계: Slack App 생성

1. [api.slack.com/apps](https://api.slack.com/apps) 접속
2. **Create New App** → **From scratch**
3. 앱 이름 및 워크스페이스 선택

### 2단계: 권한 설정

**OAuth & Permissions** → **Bot Token Scopes** 추가:
- `app_mentions:read`
- `chat:write`
- `im:history`
- `im:read`
- `im:write`

**Socket Mode** 활성화 → App-Level Token 생성 (`connections:write` 스코프)

### 3단계: 설정 파일 수정

```yaml
channels:
  slack:
    enabled: true
    bot_token: ${SLACK_BOT_TOKEN}
    app_token: ${SLACK_APP_TOKEN}
```

```bash
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
```

---

## WhatsApp 설정 (주의 사항)

> ⚠️ **경고:** WhatsApp AI 자동화는 **수일 내 계정 차단** 사례가 다수 보고됩니다.  
> WhatsApp Business API를 통한 공식 경로를 사용해도 비용이 발생합니다.  
> **개인 사용에는 Telegram을 강력히 권장합니다.**

공식 경로 (WhatsApp Business API):
```yaml
channels:
  whatsapp:
    enabled: true
    provider: meta_cloud    # 또는 twilio
    phone_number_id: ${WA_PHONE_NUMBER_ID}
    access_token: ${WA_ACCESS_TOKEN}
    verify_token: ${WA_VERIFY_TOKEN}
```

---

## Signal 설정

```yaml
channels:
  signal:
    enabled: true
    phone_number: "+821012345678"
    signal_cli_path: /usr/local/bin/signal-cli
```

> signal-cli 별도 설치 필요: `https://github.com/AsamK/signal-cli`

---

## iMessage 설정 (macOS 전용)

```yaml
channels:
  imessage:
    enabled: true
    # macOS BlueBubbles 서버 또는 직접 연동
    bluebubbles_url: http://localhost:1234
    bluebubbles_password: ${BLUEBUBBLES_PASSWORD}
```

---

## Microsoft Teams 설정

```yaml
channels:
  msteams:
    enabled: true
    app_id: ${TEAMS_APP_ID}
    app_password: ${TEAMS_APP_PASSWORD}
    tenant_id: ${TEAMS_TENANT_ID}
```

---

## 다중 채널 동시 사용

여러 채널을 동시에 활성화하면 **동일한 AI 어시스턴트**가 모든 채널에 응답합니다:

```yaml
channels:
  telegram:
    enabled: true
    token: ${TELEGRAM_BOT_TOKEN}
  discord:
    enabled: true
    token: ${DISCORD_BOT_TOKEN}
  slack:
    enabled: true
    bot_token: ${SLACK_BOT_TOKEN}
    app_token: ${SLACK_APP_TOKEN}
```

**활용 예시:**
- 아침 출근길: Telegram으로 일정 확인
- 업무 중: Slack으로 빠른 쿼리
- 게임하며: Discord로 정보 검색

---

## 채널별 권장 스트리밍 설정

| 채널 | 권장 streaming 값 | 이유 |
|------|------------------|------|
| Telegram | `partial` | 실시간 타이핑 효과 지원 |
| Discord | `full` | 메시지 편집 방식으로 스트리밍 |
| Slack | `disabled` | 잦은 편집이 알림 과부하 유발 |
| WhatsApp | `disabled` | 스트리밍 미지원 |

---

## 참고 링크

- [공식 채널 연결 문서](https://open-claw.bot/docs/channels/)
- [멀티채널 설정 가이드](https://lumadock.com/tutorials/openclaw-multi-channel-setup)
- [채널 비교 분석](https://zenvanriel.com/ai-engineer-blog/openclaw-channel-comparison-telegram-whatsapp-signal/)
- [WhatsApp 주의사항](https://blink.new/blog/openclaw-whatsapp-setup-status-2026)
