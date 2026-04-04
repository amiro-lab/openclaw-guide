# 01. OpenClaw 개요

## OpenClaw란?

OpenClaw는 **자신의 기기에서 직접 실행하는 오픈소스 자율 AI 에이전트**입니다.  
단순한 챗봇이 아니라 파일 관리, 이메일 전송, API 호출, 웹 검색 등 **실제 작업을 자동으로 수행**합니다.

특징적인 점은 인터페이스가 별도 앱이 아닌 **이미 사용 중인 메시징 플랫폼**(WhatsApp, Telegram, Slack 등)이라는 것입니다.

---

## 역사 & 이름 변경

| 시기 | 이름 | 사유 |
|------|------|------|
| 2025년 11월 | **Clawdbot** | Peter Steinberger가 최초 공개 |
| 2026년 1월 27일 | **Moltbot** | Anthropic 상표권 이슈로 변경 |
| 2026년 1월 30일 | **OpenClaw** | 현재 이름 확정 |
| 2026년 2월 14일 | (OpenAI 이관) | Steinberger가 OpenAI 합류, 독립 재단으로 프로젝트 이관 |

---

## 폭발적 성장

- GitHub 스타 **247,000+** (약 60일 만에 달성)
- React가 같은 수의 스타를 모으는 데 **10년**이 걸린 것과 비교
- GitHub 역사상 **가장 빠르게 성장한 오픈소스 프로젝트**
- 2026년 2월 기준 **15,000+ 개인 AI 어시스턴트** 구동 중
- 버그 수정 속도가 경쟁 프로젝트 대비 **3배 빠름**

---

## 핵심 철학

### 1. Self-Hosted (자체 호스팅)
모든 오케스트레이션이 내 하드웨어에서 실행됩니다. AI 모델 API만 외부 호출이며, 나머지 데이터는 내 기기에 저장됩니다.

### 2. Any Platform (어느 플랫폼이든)
이미 쓰고 있는 앱을 인터페이스로 사용합니다. 새로운 앱을 배울 필요가 없습니다.

### 3. Model-Agnostic (모델 독립)
OpenAI, Anthropic, 로컬 모델(Ollama) 등 어떤 LLM이든 설정 하나로 교체 가능합니다.

### 4. Tool-First (도구 중심)
텍스트 생성을 넘어 실제 작업을 수행하는 도구 시스템이 핵심입니다.

---

## 지원 메시징 플랫폼 (25개+)

| 카테고리 | 플랫폼 |
|----------|--------|
| 주요 메신저 | WhatsApp, Telegram, Signal, iMessage, WeChat, LINE |
| 업무용 | Slack, Discord, Microsoft Teams, Google Chat, Feishu |
| 개발자/커뮤니티 | IRC, Matrix, Nostr, Twitch, Mattermost |
| 기타 | BlueBubbles, Nextcloud Talk, Synology Chat, Tlon, Zalo, WebChat |

---

## 주요 사용 사례

- **워크플로우 자동화**: 반복적인 작업을 AI가 대신 처리
- **파일 관리**: 문서 정리, 검색, 변환
- **이메일/메시지 처리**: 답장 초안 작성, 요약
- **API 연동**: 외부 서비스와 연동하여 데이터 조회/처리
- **웹 리서치**: 정보 수집 및 요약
- **코드 실행 & 디버깅**: 코드 작성 및 실행

---

## 라이선스 & 거버넌스

- 라이선스: **MIT**
- 언어: **TypeScript** (346,977 lines)
- 거버넌스: **독립 재단** (커뮤니티 주도)
- 공식 스킬 레지스트리 **ClawHub**: 13,729개 커뮤니티 스킬 (2026년 2월 기준)

---

## 참고 링크

- [GitHub 공식 저장소](https://github.com/openclaw/openclaw)
- [공식 사이트](https://openclaw.ai/)
- [KDnuggets - OpenClaw 해설](https://www.kdnuggets.com/openclaw-explained-the-free-ai-agent-tool-going-viral-already-in-2026)
- [DigitalOcean - OpenClaw 소개](https://www.digitalocean.com/resources/articles/what-is-openclaw)
