# 07. 고급 기능

## 스케줄링 (Cron & Wakeup)

OpenClaw에는 내장 스케줄러가 있어 **반복 작업을 자동화**할 수 있습니다.

### 채팅에서 등록

```
매일 오전 9시에 오늘의 뉴스 요약해줘
매주 월요일 오전 8시에 이번 주 일정 알려줘
30분마다 내 GitHub 이슈 확인해줘
```

### config.yaml로 등록

```yaml
scheduler:
  enabled: true
  timezone: Asia/Seoul
  jobs:
    - name: morning_brief
      cron: "0 9 * * *"          # 매일 오전 9시
      channel: telegram
      prompt: "오늘의 날씨와 주요 뉴스를 요약해줘"

    - name: weekly_report
      cron: "0 8 * * MON"        # 매주 월요일 오전 8시
      channel: slack
      prompt: "이번 주 GitHub PR 상태를 요약해줘"
```

### Cron 표현식 참조

```
┌─── 분 (0-59)
│ ┌── 시 (0-23)
│ │ ┌─ 일 (1-31)
│ │ │ ┌ 월 (1-12)
│ │ │ │ ┌ 요일 (0-7, 0/7=일)
│ │ │ │ │
* * * * *

0 9 * * *      → 매일 오전 9시
0 9 * * MON    → 매주 월요일 오전 9시
*/30 * * * *   → 30분마다
0 0 1 * *      → 매월 1일 자정
```

---

## 메모리 & 세션 관리

### 세션 컨텍스트

OpenClaw는 대화 기록을 `~/.openclaw/sessions/`에 저장합니다.

```yaml
session:
  max_history: 50        # 컨텍스트에 유지할 최대 메시지 수
  persist: true          # 재시작 후에도 기억 유지
  summary_threshold: 30  # 이 수를 넘으면 요약 압축
```

### 명시적 메모리 명령

채팅에서 직접 지시:
```
이건 기억해줘: 나는 Python 개발자이고 주로 FastAPI를 사용해
오늘 회의 내용을 기억해줘
지난번에 말했던 프로젝트 계획 기억나?
```

### 세션 초기화

```
/clear          # 현재 세션 기록 초기화
/reset          # 설정 유지, 메모리만 초기화
```

---

## SSH 샌드박스 실행 (2026 신기능)

원격 서버에서 명령을 안전하게 실행하는 기능입니다.

```yaml
tools:
  ssh_exec:
    enabled: true
    hosts:
      production:
        host: prod.example.com
        user: deploy
        key_secret: SSH_PROD_KEY    # Secrets에 저장된 키 참조
      staging:
        host: staging.example.com
        user: ubuntu
        key_secret: SSH_STAGING_KEY
```

```bash
# Secrets에 SSH 키 등록
openclaw secret set SSH_PROD_KEY "$(cat ~/.ssh/id_rsa)"
```

사용 예:
```
production 서버에서 nginx 상태 확인해줘
staging 서버에 최신 코드 배포해줘
```

---

## Secrets 관리

민감한 정보를 암호화하여 안전하게 저장합니다.

```bash
# 시크릿 등록
openclaw secret set MY_API_KEY "sk-..."
openclaw secret set DB_PASSWORD "super-secret"

# 시크릿 목록
openclaw secret list

# 시크릿 삭제
openclaw secret delete MY_API_KEY
```

config.yaml에서 참조:
```yaml
models:
  custom:
    api_key: secret:MY_API_KEY   # ${} 대신 secret: 접두사 사용
```

---

## 멀티 프로파일

서로 다른 용도로 OpenClaw를 독립 실행합니다.

```bash
# 개인용 (기본)
openclaw start

# 업무용
openclaw start --profile work

# 프로젝트별
openclaw start --profile project-alpha
```

각 프로파일은 독립적인:
- `config.yaml`
- 세션 기록
- API 키
- 시스템 프롬프트

---

## 시스템 프롬프트 고급 설정

```yaml
system_prompt: |
  당신은 나의 개인 AI 어시스턴트입니다.
  
  ## 나에 대한 정보
  - 이름: 이름
  - 직업: Python/FastAPI 백엔드 개발자
  - 주로 사용하는 도구: Git, Docker, PostgreSQL
  - 선호 언어: 한국어로 답변
  
  ## 행동 원칙
  - 코드는 항상 타입 힌트를 포함하여 작성
  - 핵심만 간결하게 답변
  - 불확실하면 확인 요청
```

---

## Canvas 웹 인터페이스

브라우저에서 OpenClaw를 시각적으로 조작할 수 있는 UI입니다.

```
http://127.0.0.1:18790   (보안 설정 후)
```

기능:
- 대화 기록 조회
- 설정 시각적 편집
- 스킬/도구 관리
- 스케줄러 모니터링

보안 설정 필수:
```yaml
canvas:
  host: 127.0.0.1   # 반드시 localhost로 변경
  port: 18790
```

---

## API 직접 호출

OpenClaw Gateway는 REST API를 노출합니다 (포트 18789).

```bash
# 메시지 전송 (API를 통해)
curl -X POST http://localhost:18789/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "오늘 날씨 어때?", "channel": "api"}'

# 상태 확인
curl http://localhost:18789/api/status

# 크론 목록
curl http://localhost:18789/api/cron
```

---

## 모델 실시간 전환

재시작 없이 대화 중에 모델을 변경할 수 있습니다:

```
/model openai gpt-4o
/model anthropic claude-opus-4-6
/model ollama llama3
/model openrouter anthropic/claude-3.5-sonnet
```

---

## 디버그 모드

```bash
# 상세 로그 출력
OPENCLAW_LOG_LEVEL=debug openclaw start

# 도구 호출 추적
openclaw start --trace-tools

# 특정 채널만 디버그
openclaw start --debug-channel telegram
```

---

## 권한 & 보안 모델

| 계층 | 제어 방법 |
|------|----------|
| 도구 접근 | `tools.allow` / `tools.deny` (config.yaml) |
| 채널 접근 | `allowed_users`, `allowed_groups` (채널별 설정) |
| API 접근 | Gateway API 키 설정 |
| 파일 접근 | 샌드박스 경로 제한 (선택) |
| 외부 실행 | SSH 샌드박스로 격리 |

---

## 참고 링크

- [릴리즈 노트 (2026년 4월)](https://releasebot.io/updates/openclaw)
- [2026년 3월 업데이트](https://www.getopenclaw.ai/blog/openclaw-march-2026-update)
- [CLI & 설정 전체 가이드](https://lumadock.com/tutorials/openclaw-cli-config-reference)
- [Skywork 종합 가이드](https://skywork.ai/skypage/en/openclaw-latest-updates-2026/2037437426655117312)
