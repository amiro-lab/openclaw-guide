# 06. 도구(Tools) & 플러그인(Plugins) 시스템

## 개요

**도구(Tool)**는 에이전트가 텍스트 생성 이상의 **실제 작업을 수행**하는 수단입니다.  
**플러그인(Plugin)**은 새로운 채널, 도구, 스킬 등을 OpenClaw에 **추가하는 패키지**입니다.

---

## 내장 도구 목록

### 웹 도구

| 도구명 | 설명 |
|--------|------|
| `web_search` | Brave Search API를 통한 웹 검색 |
| `web_fetch` | URL에서 콘텐츠 가져오기 (HTML → 마크다운 변환) |
| `browser_control` | OpenClaw 전용 브라우저 제어 (자동화) |

### 파일 시스템 도구

| 도구명 | 설명 |
|--------|------|
| `file_read` | 파일 읽기 |
| `file_write` | 파일 쓰기/생성 |
| `file_list` | 디렉토리 목록 조회 |
| `file_search` | 파일 내용 검색 |

### 실행 도구

| 도구명 | 설명 |
|--------|------|
| `shell_exec` | 셸 명령 실행 |
| `ssh_exec` | SSH 원격 실행 (샌드박스 환경) |

### 메시징 도구

| 도구명 | 설명 |
|--------|------|
| `send_message` | 채널로 메시지 전송 |
| `channel_action` | Discord/Slack 채널 액션 |

### 미디어 처리 도구

| 도구명 | 설명 |
|--------|------|
| `pdf_tool` | PDF 분석 (Anthropic/Google 모델: 네이티브, 나머지: 텍스트/이미지 추출) |
| `image_generate` | 이미지 생성 (프로바이더 설정 시) |

### 스케줄링 도구

| 도구명 | 설명 |
|--------|------|
| `cron_create` | 반복 작업 등록 |
| `cron_list` | 등록된 크론 목록 조회 |
| `cron_delete` | 크론 작업 삭제 |
| `wakeup_set` | 특정 시간에 한 번 실행할 작업 예약 |

---

## 도구 접근 제어

```yaml
# config.yaml
tools:
  allow:
    - web_search
    - web_fetch
    - file_read
    - pdf_tool
  deny:
    - shell_exec     # deny가 allow보다 항상 우선
    - file_write
```

> **보안 원칙:** 필요한 도구만 허용, `shell_exec`는 신중하게 사용

---

## 채팅에서 도구 직접 호출

```
# 웹 검색
오늘 서울 날씨를 검색해줘

# 파일 읽기
~/Documents/report.pdf 파일을 분석해줘

# 크론 등록
매일 오전 9시에 뉴스 요약해서 알려줘
```

---

## 플러그인 시스템

### 플러그인 구조

```
플러그인 패키지
├── package.json         # npm 패키지 정보
├── skill.yaml           # OpenClaw 메타데이터
│   ├── name
│   ├── version
│   ├── description
│   └── capabilities:    # 제공하는 기능 선언
│       - tools
│       - channels
│       - providers
│       - speech
│       - image_generation
└── index.js             # 진입점
```

### 플러그인 설치

```bash
# ClawHub (공식 레지스트리) 에서 설치
openclaw skill install <skill-name>

# npm에서 직접 설치
openclaw skill install npm:<package-name>

# 로컬 설치 (개발 중인 플러그인)
openclaw skill install ./my-local-skill
```

### 플러그인 목록 조회

```bash
openclaw skill list
```

### 플러그인 제거

```bash
openclaw skill remove <skill-name>
```

---

## ClawHub — 커뮤니티 스킬 허브

- **공식 레지스트리:** https://openclaw.ai (ClawHub)
- 등록된 스킬 수: **13,729개** (2026년 2월 기준)
- **awesome-openclaw-skills**: [5,400+ 필터링된 스킬 모음](https://github.com/VoltAgent/awesome-openclaw-skills)

ClawHub는 npm보다 **우선 검색**됩니다.

---

## 개발자용: 상위 6개 인기 도구 (2026)

1. **OpenClaw Code Interpreter** — 코드 실행 및 Jupyter 노트북 통합
2. **OpenClaw Calendar Sync** — Google Calendar / Outlook 연동
3. **OpenClaw GitHub Tool** — PR, 이슈, 코드 리뷰 자동화
4. **OpenClaw Notion** — Notion DB 읽기/쓰기
5. **OpenClaw Email** — Gmail / Outlook 이메일 처리
6. **OpenClaw Docker** — 컨테이너 관리 자동화

---

## 커스텀 도구 만들기

### 도구 템플릿

```typescript
// my-tool.ts
import { Tool, ToolResult } from '@openclaw/sdk';

export const myCustomTool: Tool = {
  name: 'my_custom_tool',
  description: 'What this tool does (LLM이 이 설명으로 도구를 선택)',
  parameters: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: 'Input parameter',
      },
    },
    required: ['query'],
  },
  async execute({ query }): Promise<ToolResult> {
    // 도구 로직 구현
    const result = await doSomething(query);
    return {
      content: result,
      type: 'text',
    };
  },
};
```

### skill.yaml 등록

```yaml
name: my-awesome-skill
version: 1.0.0
description: My custom tool for OpenClaw
capabilities:
  tools:
    - name: my_custom_tool
      entry: ./my-tool.js
```

---

## 2026년 3월 주요 업데이트

| 기능 | 설명 |
|------|------|
| **PDF Tool** | 내장 PDF 분석 도구 추가 (Anthropic/Google 네이티브 지원) |
| **Telegram 스트리밍** | 기본값이 `partial` 스트리밍으로 변경 — 실시간 타이핑 효과 |
| **Secrets Management** | 민감한 값을 암호화하여 안전하게 저장 |
| **SSH Sandboxing** | SSH 원격 실행을 위한 시크릿 기반 샌드박스 환경 |
| **GPT-5.40 기본값** | 기본 OpenAI 모델이 GPT-5.40으로 업그레이드 |
| **MiniMax M2.70 지원** | 새 LLM 프로바이더 추가 |
| **GLM-5.00 지원** | 새 LLM 프로바이더 추가 |
| **Anthropic Vertex AI** | GCP 기반 Claude 모델 지원 |

---

## 참고 링크

- [공식 도구 문서](https://docs.openclaw.ai/tools)
- [플러그인 문서](https://openclaws.io/docs/tools/plugin)
- [awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills)
- [2026년 3월 업데이트 블로그](https://www.getopenclaw.ai/blog/openclaw-march-2026-update)
- [Indie Hackers - 개발자가 쓰는 상위 6개 도구](https://www.indiehackers.com/post/top-6-openclaw-tools-developers-are-using-in-2026-f25e9a48ae)
