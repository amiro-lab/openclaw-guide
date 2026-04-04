# 02. OpenClaw 아키텍처 & 소스코드 분석

> 실제 소스코드(`openclaw-src/`) 기반으로 작성된 분석입니다.

---

## 저장소 구조 (실제)

OpenClaw는 대규모 **TypeScript 모노레포**입니다:

```
openclaw/
├── src/              # 핵심 TypeScript 소스 (5,582+ 파일)
├── extensions/       # 번들된 플러그인 패키지 (채널 + 프로바이더)
├── skills/           # 내장 스킬 패키지 (~50개)
├── apps/
│   ├── android/      # Android 앱 (Kotlin)
│   ├── ios/          # iOS 앱 (Swift)
│   └── macos/        # macOS 앱 (SwiftUI)
├── docs/             # 공식 문서 (Mintlify)
├── packages/         # 공유 패키지 (clawdbot, moltbot 호환 래퍼 등)
├── Swabble/          # macOS 자동화 라이브러리 (Swift)
├── ui/               # 웹 UI
├── scripts/          # 빌드/배포 스크립트
├── test/             # 테스트 픽스처 및 헬퍼
├── .agents/skills/   # 자동화 에이전트 스킬
│   ├── openclaw-pr-maintainer/
│   ├── openclaw-release-maintainer/
│   ├── openclaw-ghsa-maintainer/
│   └── ...
├── AGENTS.md         # 저장소 가이드라인 (= CLAUDE.md)
└── .env.example      # 환경변수 예시
```

---

## src/ 핵심 모듈 맵

```
src/
├── gateway/          # 메인 게이트웨이 프로세스
│   └── protocol/     # WebSocket 프로토콜 스키마 (TypeBox)
├── agents/           # 에이전트 실행 엔진 (Anthropic/OpenAI 스트림)
├── acp/              # Agent Collaboration Protocol (멀티에이전트)
│   └── control-plane/# ACP 스폰 매니저
├── channels/         # 채널 인프라 (코어)
├── routing/          # 메시지 라우팅 (세션 키 시스템)
├── sessions/         # 세션 관리 및 기록
├── context-engine/   # 컨텍스트 어셈블리 엔진
├── plugin-sdk/       # 플러그인 공개 API 표면
├── plugins/          # 플러그인 디스커버리/로더/레지스트리
├── config/           # 설정 로딩 및 마이그레이션
├── secrets/          # 시크릿 관리 (SecretRef 시스템)
├── security/         # 보안 정책
├── canvas-host/      # Canvas 웹 UI 호스트 (A2UI)
├── mcp/              # Model Context Protocol 지원
├── hooks/            # 훅 시스템
├── cron/             # 스케줄러
├── tasks/            # 태스크 실행기
├── tts/              # 텍스트-음성 변환
├── realtime-voice/   # 실시간 음성
├── realtime-transcription/ # 실시간 전사
├── image-generation/ # 이미지 생성
├── media/            # 미디어 파이프라인
├── media-understanding/ # 미디어 이해 (비전)
├── web-fetch/        # 웹 페이지 가져오기 도구
├── web-search/       # 웹 검색 도구
├── pairing/          # 디바이스 페어링
├── daemon/           # 백그라운드 데몬
├── cli/              # CLI 진입점
├── commands/         # CLI 커맨드 구현
├── wizard/           # 셋업 마법사
├── infra/            # 인프라 유틸리티
├── logging/          # 로깅 서브시스템
└── tui/              # 터미널 UI
```

---

## Gateway 아키텍처 (핵심)

공식 문서 (`docs/concepts/architecture.md`) 기반:

```
┌─────────────────────────────────────────────────────────────┐
│                    메시징 채널 레이어                          │
│  WhatsApp(Baileys) / Telegram(grammY) / Discord / Slack /   │
│  Signal / iMessage / IRC / Matrix / Feishu / LINE / ...     │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                  Gateway (데몬 프로세스)                       │
│  WebSocket 서버: 127.0.0.1:18789 (기본값)                     │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │ Control- │  │  Agent   │  │  Cron    │  │  Canvas    │  │
│  │  Plane   │  │  Loop    │  │Scheduler │  │   Host     │  │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │ WebSocket
         ┌───────────────┼──────────────────┐
         ▼               ▼                  ▼
  ┌────────────┐  ┌────────────┐  ┌───────────────┐
  │ macOS/iOS  │  │  CLI 클라  │  │  Nodes        │
  │  앱 클라  │  │  이언트    │  │(Android/head- │
  │  이언트   │  │            │  │  less)        │
  └────────────┘  └────────────┘  └───────────────┘
```

**핵심 설계 원칙:**
- Gateway는 호스트당 **하나만** 실행 (WhatsApp 세션 충돌 방지)
- 모든 채널 + 클라이언트가 **동일한 WebSocket 서버**에 연결
- Canvas 웹 UI도 동일 포트(18789) 아래의 HTTP 경로로 제공

---

## WebSocket 프로토콜

`src/gateway/protocol/schema.ts` 기반:

```
연결 흐름:
1. Client → Gateway: req:connect (deviceIdentity + auth.token)
2. Gateway → Client: res (hello-ok | error + close)
3. Gateway → Client: event:presence (초기 상태 스냅샷)
4. Gateway → Client: event:tick

메시지 타입:
- 요청:  { type:"req", id, method, params }
- 응답:  { type:"res", id, ok, payload|error }
- 이벤트: { type:"event", event, payload, seq?, stateVersion? }

주요 메서드:
- connect     → 핸드셰이크 (반드시 첫 프레임)
- agent       → 에이전트 실행 요청
- agent.wait  → 에이전트 완료 대기
- send        → 채널로 메시지 전송
- health      → 헬스 체크
- status      → 채널 상태
- cron.*      → 크론 관리
```

**보안:**
- `OPENCLAW_GATEWAY_TOKEN` 설정 시 모든 연결에서 토큰 검증 필수
- 멱등성 키(idempotency key) 필요 (`send`, `agent` 메서드)
- 디바이스 페어링 기반 신뢰 모델 (`connect.challenge` 서명)

---

## 에이전트 루프 (Agent Loop)

`docs/concepts/agent-loop.md` 기반:

```
1. agent RPC 수신
   → 세션 키 해석 + 세션 메타데이터 저장
   → { runId, acceptedAt } 즉시 반환
         ↓
2. agentCommand 실행
   → 모델 + thinking 설정 해석
   → 스킬 스냅샷 로드
   → runEmbeddedPiAgent 호출
         ↓
3. runEmbeddedPiAgent
   → 세션별 + 글로벌 큐로 직렬화 (레이스 컨디션 방지)
   → 모델 + 인증 프로파일 해석
   → pi-agent-core 세션 구축
   → 이벤트 구독 + 스트리밍
   → 타임아웃 감시 (기본 48시간)
         ↓
4. subscribeEmbeddedPiSession (이벤트 → 스트림 매핑)
   → tool 이벤트  → stream: "tool"
   → assistant 델타 → stream: "assistant"
   → lifecycle 이벤트 → stream: "lifecycle" (start|end|error)
         ↓
5. 최종 응답 조합
   → assistant 텍스트 + reasoning
   → 인라인 도구 요약 (verbose 모드)
   → NO_REPLY 토큰 필터링
   → 채널로 전송
```

**에이전트 루프 훅 포인트:**

| 훅 이름 | 실행 시점 |
|---------|---------|
| `before_model_resolve` | 세션 로드 전, 모델 결정 전 |
| `before_prompt_build` | 메시지 로드 후, 프롬프트 전송 전 |
| `before_agent_reply` | LLM 호출 직전 (합성 응답 가능) |
| `before_tool_call` | 도구 실행 전 (차단 가능) |
| `after_tool_call` | 도구 실행 후 |
| `agent_end` | 에이전트 완료 후 |
| `message_received` | 인바운드 메시지 수신 시 |
| `message_sending` | 아웃바운드 메시지 전송 직전 (취소 가능) |
| `before_compaction` | 컨텍스트 압축 전 |

---

## 플러그인 시스템

`src/plugin-sdk/`, `src/plugins/`, `extensions/` 기반:

### 아키텍처 경계

```
외부 플러그인 (third-party)
    │ 반드시 이 경로만 사용
    ▼
openclaw/plugin-sdk/*    ← 공개 플러그인 API
    │
    ▼
src/channels/*           ← 코어 채널 구현 (직접 접근 불가)
src/plugins/*            ← 플러그인 디스커버리 + 레지스트리
src/gateway/protocol/*   ← 게이트웨이 컨트롤 플레인
```

### 플러그인 유형

```
플러그인이 등록할 수 있는 것:
├── channels      → 새 메시징 채널 추가
├── providers     → 새 LLM 프로바이더 추가
├── tools         → 새 도구 추가
├── skills        → 새 스킬 추가
├── speech        → 음성 처리
└── image_gen     → 이미지 생성
```

### 번들 플러그인 목록 (`extensions/`)

**채널:**
`telegram`, `discord`, `slack`, `signal`, `imessage`, `whatsapp`, `matrix`,
`msteams`, `googlechat`, `irc`, `line`, `feishu`, `mattermost`, `nextcloud-talk`,
`bluebubbles`, `nostr`, `twitch`, `tlon`, `zalo`, `zalouser`, `qqbot`, `xiaomi`

**LLM 프로바이더:**
`openai`, `anthropic`, `anthropic-vertex`, `google`, `groq`, `ollama`, `openrouter`,
`mistral`, `deepseek`, `minimax`, `moonshot`, `litellm`, `vllm`, `sglang`,
`amazon-bedrock`, `huggingface`, `microsoft`, `microsoft-foundry`, `nvidia`,
`cloudflare-ai-gateway`, `vercel-ai-gateway`, `byteplus`, `volcengine`, `qianfan`,
`modelstudio`, `stepfun`, `chutes`, `copilot-proxy`, `github-copilot`, `zai`,
`xai`, `kimi-coding`, `kilocode`

**도구:**
`brave`, `duckduckgo`, `exa`, `firecrawl`, `perplexity`, `tavily`, `searxng` (검색),
`browser` (브라우저 제어), `diffs` (파일 diff), `llm-task` (LLM 서브태스크),
`openshell` (셸 실행), `opencode`, `opencode-go` (코딩)

**미디어/음성:**
`elevenlabs`, `deepgram`, `fal`, `speech-core`, `talk-voice`, `voice-call`,
`image-generation-core`, `media-understanding-core`

**기타:**
`memory-core`, `memory-lancedb`, `acpx`, `lobster`, `device-pair`,
`diagnostics-otel`, `shared`

---

## 내장 스킬 (`skills/`)

약 50개의 내장 스킬 포함:

| 카테고리 | 스킬 |
|---------|------|
| **메모** | apple-notes, bear-notes, obsidian, notion |
| **할일** | apple-reminders, things-mac, trello, taskflow |
| **개발** | github, gh-issues, coding-agent |
| **음악** | spotify-player, sonoscli, songsee |
| **음성** | openai-whisper, openai-whisper-api, sherpa-onnx-tts, voice-call |
| **파일** | nano-pdf, video-frames, camsnap, peekaboo |
| **검색** | xurl, goplaces, gifgrep |
| **채널** | slack, discord, imsg, wacli, bluebubbles |
| **시스템** | tmux, oracle, eightctl, blucli, ordercli |
| **AI** | gemini, model-usage, skill-creator |
| **기타** | weather, healthcheck, 1password, himalaya, summarize, session-logs |

---

## 멀티에이전트 시스템

`docs/concepts/multi-agent.md` 기반:

### 에이전트(Agent)란?

각 에이전트는 완전히 격리된 "브레인":
```
~/.openclaw/
├── workspace/                  # 기본 에이전트 워크스페이스
│   ├── MEMORY.md               # 장기 메모리
│   ├── SOUL.md                 # 페르소나 정의
│   ├── AGENTS.md               # 에이전트 행동 규칙
│   └── USER.md                 # 사용자 정보
└── agents/
    └── <agentId>/
        ├── sessions/           # 대화 기록 (.jsonl)
        └── agent/
            └── auth-profiles.json  # 인증 프로파일 (에이전트별 독립)
```

### 바인딩 라우팅 우선순위

```
1. peer 매치 (특정 DM/그룹 ID)
2. parentPeer 매치 (스레드 상속)
3. guildId + roles (Discord 역할 라우팅)
4. guildId (Discord 서버)
5. teamId (Slack 팀)
6. accountId (채널 계정)
7. channel (채널 전체)
8. 기본 에이전트 (fallback)
```

### 멀티에이전트 설정 예시

```json5
// ~/.openclaw/openclaw.json
{
  agents: {
    list: [
      {
        id: "chat",
        name: "일상 어시스턴트",
        workspace: "~/.openclaw/workspace-chat",
        model: "anthropic/claude-sonnet-4-6",
      },
      {
        id: "work",
        name: "업무 전용",
        workspace: "~/.openclaw/workspace-work",
        model: "anthropic/claude-opus-4-6",
        sandbox: { mode: "all" },
        tools: { deny: ["write", "browser"] },
      },
    ],
  },
  bindings: [
    { agentId: "chat", match: { channel: "whatsapp" } },
    { agentId: "work", match: { channel: "telegram" } },
  ],
}
```

---

## 메모리 시스템

`docs/concepts/memory.md` 기반:

**메모리는 단순한 마크다운 파일:**
```
~/.openclaw/workspace/
├── MEMORY.md           # 장기 기억 (모든 DM 세션 시작 시 로드)
└── memory/
    ├── 2026-04-03.md   # 어제 노트 (자동 로드)
    └── 2026-04-04.md   # 오늘 노트 (자동 로드)
```

**메모리 도구:**
- `memory_search` → 시맨틱 검색 (임베딩 프로바이더 필요)
- `memory_get` → 특정 파일/라인 읽기

**메모리 백엔드:**
- `memory-core` (기본): 파일 기반
- `memory-lancedb`: LanceDB 벡터 검색
- 외부 프로바이더: Honcho, QMD

---

## 설정 파일

**중요: 설정 파일은 `openclaw.json` (JSON5 형식)**

```
~/.openclaw/
├── openclaw.json       # 메인 설정 파일 (JSON5)
├── .env                # 환경변수 (API 키 등)
├── credentials/        # 채널 자격증명
│   └── whatsapp/       # WhatsApp 세션 파일
├── workspace/          # 기본 에이전트 워크스페이스
└── agents/
    └── main/
        └── sessions/   # 대화 기록
```

---

## 개발 환경

`AGENTS.md` 기반:

```bash
# 패키지 매니저: pnpm (또는 Bun)
pnpm install

# 개발 실행
pnpm openclaw ...    # Bun으로 TypeScript 직접 실행
pnpm dev

# 빌드
pnpm build           # TypeScript 컴파일
pnpm tsgo            # 타입 체크

# 테스트
pnpm test            # Vitest 실행
pnpm test:coverage   # 커버리지 포함

# 린트/포맷
pnpm check           # Oxlint + Oxfmt
pnpm format:fix      # 포맷 자동 수정

# 설정 스키마 검사
pnpm config:docs:gen
pnpm config:docs:check
```

**기술 스택:**
- 언어: TypeScript (ESM, strict)
- 런타임: Node.js 22+ / Bun
- 테스트: Vitest (V8 커버리지, 70% 임계값)
- 린터: Oxlint
- 포맷터: Oxfmt
- 스키마: TypeBox + Zod
- 모바일: Swift (iOS/macOS), Kotlin (Android)

---

## ACP (Agent Collaboration Protocol)

`src/acp/` 기반:

외부 코딩 에이전트 하네스와 통신하는 프로토콜:
- OpenCode, Kilocode, Kimi-coding 등 외부 코딩 에이전트 연동
- 서브에이전트 스폰 및 결과 스트리밍
- `src/acp/control-plane/` — 스폰 매니저 + 세션 액터 큐

---

## .agents/ 자동화 스킬

저장소 내 AI 기반 자동화:

```
.agents/skills/
├── openclaw-pr-maintainer/   # PR 트리아지, 리뷰, 랜딩
├── openclaw-release-maintainer/ # 릴리즈 버전 조율
├── openclaw-ghsa-maintainer/ # 보안 취약점(GHSA) 처리
├── openclaw-test-heap-leaks/ # 힙 리크 테스트
├── parallels-discord-roundtrip/ # Discord 통합 테스트
└── security-triage/          # 보안 이슈 분류
```

---

## 참고 파일

| 파일 | 설명 |
|------|------|
| `src/gateway/protocol/schema.ts` | Gateway WebSocket 프로토콜 스키마 |
| `src/plugin-sdk/plugin-entry.ts` | 플러그인 진입점 계약 |
| `src/plugin-sdk/channel-contract.ts` | 채널 플러그인 계약 |
| `src/plugins/contracts/registry.ts` | 플러그인 레지스트리 계약 |
| `docs/concepts/architecture.md` | Gateway 아키텍처 공식 문서 |
| `docs/concepts/agent-loop.md` | 에이전트 루프 공식 문서 |
| `docs/concepts/multi-agent.md` | 멀티에이전트 라우팅 문서 |
| `docs/plugins/architecture.md` | 플러그인 아키텍처 문서 |
| `AGENTS.md` | 저장소 전체 가이드라인 |
| `.env.example` | 환경변수 전체 참조 |
