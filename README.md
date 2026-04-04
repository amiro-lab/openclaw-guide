# OpenClaw 완전 가이드북

> 자율 AI 에이전트 OpenClaw — 설치부터 고급 활용까지

---

## 목차

| 번호 | 문서 | 설명 |
|------|------|------|
| 01 | [OpenClaw 개요](./01_overview.md) | OpenClaw란 무엇인가, 역사, 철학 |
| 02 | [아키텍처 분석](./02_architecture.md) | 소스코드 구조, 핵심 컴포넌트, 동작 원리 |
| 03 | [설치 가이드](./03_installation.md) | macOS / Linux / Windows(WSL2) 설치 방법 |
| 04 | [설정 참조](./04_configuration.md) | config.yaml, 환경변수, LLM 프로바이더 연결 |
| 05 | [플랫폼 통합](./05_platforms.md) | Telegram, Discord, WhatsApp, Slack 등 채널 설정 |
| 06 | [도구 & 플러그인](./06_tools_plugins.md) | 내장 도구, 플러그인 시스템, ClawHub |
| 07 | [고급 기능](./07_advanced_features.md) | 스킬, 스케줄링, 메모리, 보안, SSH 샌드박스 |
| 08 | [비교 분석](./08_comparison.md) | AutoGPT, CrewAI, LangGraph 등과 비교 |

---

## 빠른 시작

```bash
# Node.js 22+ 필요
npm install -g openclaw
openclaw init
openclaw start
```

---

## 참고 자료

- 공식 GitHub: https://github.com/openclaw/openclaw
- 공식 문서: https://docs.openclaw.ai
- 커뮤니티 스킬 허브: https://openclaw.ai (ClawHub)

---

*마지막 업데이트: 2026-04-04*
