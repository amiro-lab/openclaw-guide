# 04. OpenClaw 설정 참조

> 실제 소스코드(`openclaw-src/docs/gateway/`) 기반으로 작성되었습니다.

---

## 설정 파일 위치

```
~/.openclaw/openclaw.json       # 기본 프로파일 (JSON5 형식)
~/.openclaw/.env                # 환경변수 (API 키 등)
```

> **중요:** 설정 파일은 `openclaw.json` (YAML이 아닌 **JSON5** 형식)  
> JSON5 = JSON + 주석 + 후행 쉼표 허용

다중 프로파일:
```bash
OPENCLAW_PROFILE=work openclaw gateway  # ~/.openclaw-work/openclaw.json 사용
```

---

## 환경변수 우선순위

```
1. 프로세스 환경변수 (셸에서 이미 export된 값)
2. ./.env (현재 디렉토리)
3. ~/.openclaw/.env (홈 디렉토리)
4. openclaw.json 내 env 블록
```

앞에 있는 소스가 항상 우선합니다. 이미 설정된 값은 덮어쓰지 않습니다.

---

## .env 파일 전체 참조 (`.env.example` 기반)

```bash
# ─── Gateway 인증 ────────────────────────────────────────────
# 게이트웨이가 loopback 밖으로 바인딩되는 경우 필수
OPENCLAW_GATEWAY_TOKEN=change-me-to-a-long-random-token
# 생성: openssl rand -hex 32

# 패스워드 방식 (토큰 또는 패스워드 중 하나만)
# OPENCLAW_GATEWAY_PASSWORD=change-me-to-a-strong-password

# ─── 경로 오버라이드 (선택) ───────────────────────────────────
# OPENCLAW_STATE_DIR=~/.openclaw
# OPENCLAW_CONFIG_PATH=~/.openclaw/openclaw.json
# OPENCLAW_HOME=~

# 셸 프로파일 로드 (선택)
# OPENCLAW_LOAD_SHELL_ENV=1
# OPENCLAW_SHELL_ENV_TIMEOUT_MS=15000

# ─── LLM 프로바이더 API 키 (최소 하나 필수) ─────────────────
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
# GEMINI_API_KEY=...
# OPENROUTER_API_KEY=sk-or-...

# 다중 키 로드밸런싱
# OPENAI_API_KEYS=sk-1,sk-2
# ANTHROPIC_API_KEYS=sk-ant-1,sk-ant-2

# 추가 프로바이더
# ZAI_API_KEY=...
# MINIMAX_API_KEY=...

# ─── 채널 토큰 ────────────────────────────────────────────────
TELEGRAM_BOT_TOKEN=123456:ABCDEF...
# DISCORD_BOT_TOKEN=...
# SLACK_BOT_TOKEN=xoxb-...
# SLACK_APP_TOKEN=xapp-...
# MATTERMOST_BOT_TOKEN=...
# MATTERMOST_URL=https://chat.example.com
# ZALO_BOT_TOKEN=...
# OPENCLAW_TWITCH_ACCESS_TOKEN=oauth:...

# ─── 도구 / 음성 / 미디어 ─────────────────────────────────────
# BRAVE_API_KEY=...
# PERPLEXITY_API_KEY=pplx-...
# FIRECRAWL_API_KEY=...
# ELEVENLABS_API_KEY=...
# DEEPGRAM_API_KEY=...
```

---

## openclaw.json 전체 예시

```json5
// ~/.openclaw/openclaw.json
{
  // ─── 모델 설정 ─────────────────────────────────────────────
  model: "anthropic/claude-sonnet-4-6",
  // 또는: "openai/gpt-4o", "ollama/llama3"

  // ─── 에이전트 설정 ─────────────────────────────────────────
  agents: {
    defaults: {
      workspace: "~/.openclaw/workspace",
    },
    list: [
      {
        id: "main",
        name: "메인 어시스턴트",
        workspace: "~/.openclaw/workspace",
        model: "anthropic/claude-sonnet-4-6",
      },
    ],
  },

  // ─── 채널 설정 ─────────────────────────────────────────────
  channels: {
    defaults: {
      groupPolicy: "allowlist",    // open | allowlist | disabled
    },
    telegram: {
      accounts: {
        default: {
          botToken: "${TELEGRAM_BOT_TOKEN}",
          dmPolicy: "pairing",     // pairing | allowlist | open | disabled
        },
      },
    },
    discord: {
      accounts: {
        default: {
          token: "${DISCORD_BOT_TOKEN}",
          groupPolicy: "allowlist",
          guilds: {
            "GUILD_ID_HERE": {
              channels: {
                "CHANNEL_ID_HERE": { allow: true, requireMention: false },
              },
            },
          },
        },
      },
    },
    slack: {
      accounts: {
        default: {
          botToken: "${SLACK_BOT_TOKEN}",
          appToken: "${SLACK_APP_TOKEN}",
        },
      },
    },
  },

  // ─── 바인딩 (멀티에이전트 라우팅) ────────────────────────
  bindings: [
    { agentId: "main", match: { channel: "telegram" } },
    { agentId: "main", match: { channel: "discord" } },
  ],

  // ─── 도구 설정 ─────────────────────────────────────────────
  tools: {
    allow: ["read", "write", "exec", "web_search", "web_fetch"],
    deny: [],
    // deny가 항상 allow보다 우선
    agentToAgent: {
      enabled: false,
    },
  },

  // ─── 샌드박스 ─────────────────────────────────────────────
  sandbox: {
    mode: "off",   // off | auto | all
  },

  // ─── 게이트웨이 설정 ───────────────────────────────────────
  gateway: {
    mode: "local",
    bind: "loopback",
    port: 18789,
    auth: {
      token: "${OPENCLAW_GATEWAY_TOKEN}",
    },
  },

  // ─── 메모리 백엔드 ─────────────────────────────────────────
  memory: {
    backend: "builtin",   // builtin | lancedb | qmd
  },
}
```

---

## LLM 프로바이더 설정

### 모델 지정 형식

```
provider/model-name
예: "anthropic/claude-opus-4-6"
    "openai/gpt-4o"
    "ollama/llama3"
    "openrouter/anthropic/claude-3.5-sonnet"
```

### Anthropic (Claude)

```json5
{
  model: "anthropic/claude-opus-4-6",
  // API 키는 ANTHROPIC_API_KEY 환경변수로
}
```

지원 모델:
- `anthropic/claude-opus-4-6`
- `anthropic/claude-sonnet-4-6`
- `anthropic/claude-haiku-4-5-20251001`

### OpenAI

```json5
{
  model: "openai/gpt-4o",
}
```

### Ollama (로컬)

```bash
# 먼저 모델 설치
ollama pull llama3
```

```json5
{
  model: "ollama/llama3",
}
```

```bash
# .env
OLLAMA_API_KEY=ollama-local   # 임의 값 (인증 불필요)
```

### OpenRouter

```json5
{
  model: "openrouter/anthropic/claude-opus-4-6",
}
```

### 멀티 키 로드밸런싱

```bash
OPENAI_API_KEYS=sk-key1,sk-key2,sk-key3
ANTHROPIC_API_KEYS=sk-ant-key1,sk-ant-key2
```

### 채널별 모델 오버라이드

```json5
{
  channels: {
    modelByChannel: {
      discord: {
        "CHANNEL_ID_1": "anthropic/claude-opus-4-6",    // 특정 채널 → Opus
        "CHANNEL_ID_2": "openai/gpt-4o-mini",           // 특정 채널 → 가벼운 모델
      },
      telegram: {
        "-1001234567890": "anthropic/claude-sonnet-4-6",
      },
    },
  },
}
```

---

## DM 정책

| 정책 | 동작 |
|------|------|
| `pairing` (기본) | 모르는 사람은 페어링 코드 → 승인 필요 |
| `allowlist` | `allowFrom`에 있는 사람만 허용 |
| `open` | 모든 DM 허용 (`allowFrom: ["*"]` 필요) |
| `disabled` | 모든 DM 무시 |

```json5
{
  channels: {
    telegram: {
      accounts: {
        default: {
          botToken: "${TELEGRAM_BOT_TOKEN}",
          dmPolicy: "allowlist",
          allowFrom: ["tg:123456789", "tg:987654321"],
        },
      },
    },
  },
}
```

---

## 그룹 정책

| 정책 | 동작 |
|------|------|
| `allowlist` (기본) | 허용 목록의 그룹만 응답 |
| `open` | 모든 그룹에 응답 (멘션 게이팅은 유지) |
| `disabled` | 모든 그룹 메시지 무시 |

---

## CLI 설정 명령어

```bash
# 값 설정
openclaw config set model "anthropic/claude-opus-4-6"
openclaw config set gateway.bind loopback

# 값 확인
openclaw config get model

# 전체 설정 보기
openclaw config show

# 설정 진단
openclaw doctor
openclaw doctor --fix     # 자동 수정 시도
```

---

## 다중 프로파일

```bash
# 개인용 (기본: ~/.openclaw/)
openclaw gateway

# 업무용 (별도: ~/.openclaw-work/)
OPENCLAW_PROFILE=work openclaw gateway

# 설정 경로 직접 지정
OPENCLAW_CONFIG_PATH=/custom/path/openclaw.json openclaw gateway
```

---

## 보안 설정 요약

```json5
{
  gateway: {
    auth: {
      token: "${OPENCLAW_GATEWAY_TOKEN}",   // 원격 접근 시 필수
    },
    bind: "loopback",    // 로컬만: loopback / 원격: 0.0.0.0 (비권장)
  },
}
```

> **Canvas 주의:** Canvas 웹 UI는 기본적으로 게이트웨이와 같은 포트(18789)를 사용합니다.  
> 원격 노출 시 반드시 토큰 인증을 설정하세요.

---

## 참고 링크

- [공식 설정 참조](https://docs.openclaw.ai/gateway/configuration-reference)
- [설정 예시](https://docs.openclaw.ai/gateway/configuration-examples)
- [Gateway 진단 (doctor)](https://docs.openclaw.ai/gateway/doctor)
- [실제 파일: `openclaw-src/docs/gateway/configuration-reference.md`](./openclaw-src/docs/gateway/configuration-reference.md)
