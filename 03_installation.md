# 03. OpenClaw 설치 가이드

## 사전 요구 사항

| 항목 | 요구 사항 |
|------|----------|
| Node.js | **22 이상** |
| OS | macOS, Linux, Windows (WSL2) |
| LLM API 키 | OpenAI, Anthropic, 또는 로컬 모델 중 하나 |
| 설치 시간 | 약 **15분** |

> **주의:** 네이티브 Windows (WSL2 없이)는 지원하지 않습니다.

---

## 설치 방법 1: npm (권장 — 가장 빠름)

```bash
# 1. 전역 설치
npm install -g openclaw

# 2. 초기화 (설정 마법사 실행)
openclaw init

# 3. 실행
openclaw start
```

또는 `pnpm` 사용 시:
```bash
pnpm add -g openclaw
```

---

## 설치 방법 2: 원라이너 (Node.js 자동 설치 포함)

Node.js가 없는 경우에도 의존성을 자동 설치합니다:

```bash
curl -fsSL https://openclaw.ai/install.sh | sh
```

---

## 설치 방법 3: Docker

```bash
# 이미지 pull
docker pull openclaw/openclaw:latest

# 실행 (기본 설정)
docker run -d \
  --name openclaw \
  -p 18789:18789 \
  -v ~/.openclaw:/root/.openclaw \
  -e OPENAI_API_KEY=sk-proj-... \
  openclaw/openclaw:latest
```

**Docker Compose 예시:**
```yaml
version: "3.9"
services:
  openclaw:
    image: openclaw/openclaw:latest
    ports:
      - "18789:18789"
    volumes:
      - ~/.openclaw:/root/.openclaw
    env_file:
      - .env
    restart: unless-stopped
```

---

## 설치 방법 4: 소스에서 빌드

```bash
# 1. 저장소 클론
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# 2. 의존성 설치
npm install

# 3. 빌드
npm run build

# 4. 실행
npm start
```

---

## 초기 설정 (openclaw init)

`openclaw init` 실행 시 대화형 마법사가 시작됩니다:

```
? Which AI provider would you like to use?
  ❯ OpenAI
    Anthropic
    Ollama (local)
    OpenRouter
    Other

? Enter your API key: sk-proj-...

? Which messaging channel would you like to connect first?
  ❯ Telegram
    Discord
    Slack
    WhatsApp
    Skip for now

? Enter your Telegram bot token: ...
```

설정 파일은 `~/.openclaw/config.yaml`에 저장됩니다.

---

## 설치 후 디렉토리 구조

```
~/.openclaw/
├── config.yaml        # 메인 설정 파일
├── .env               # API 키 등 환경변수 (선택)
├── credentials/       # 암호화된 채널 자격증명
│   ├── telegram.enc
│   └── discord.enc
└── sessions/          # 대화 기록
    └── *.jsonl
```

---

## 실행 및 상태 확인

```bash
# 실행
openclaw start

# 백그라운드 실행
openclaw start --daemon

# 상태 확인
openclaw status

# 로그 보기
openclaw logs

# 중지
openclaw stop
```

---

## macOS 전용 — 시스템 시작 시 자동 실행

```bash
# launchd 서비스 등록
openclaw service install

# 서비스 시작
openclaw service start
```

---

## Linux — systemd 서비스

```bash
# 서비스 파일 생성
openclaw service install --systemd

# 활성화 및 시작
sudo systemctl enable openclaw
sudo systemctl start openclaw

# 상태 확인
sudo systemctl status openclaw
```

---

## Windows (WSL2)

```bash
# WSL2 Ubuntu 기준
sudo apt update && sudo apt install -y nodejs npm

# Node.js 22 설치 (nvm 사용 권장)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 22
nvm use 22

# OpenClaw 설치
npm install -g openclaw
openclaw init
openclaw start
```

---

## Canvas 보안 설정 (중요)

기본적으로 Canvas는 `0.0.0.0`에 바인딩되어 로컬 네트워크 전체에서 접근 가능합니다.  
**반드시 localhost로 변경하세요:**

```yaml
# ~/.openclaw/config.yaml
canvas:
  host: 127.0.0.1   # 0.0.0.0 → 127.0.0.1 로 변경
  port: 18790
```

---

## 업그레이드

```bash
# npm 전역 패키지 업그레이드
npm update -g openclaw

# 현재 버전 확인
openclaw --version
```

---

## 일반적인 문제 해결

| 문제 | 해결 방법 |
|------|----------|
| `EACCES` 권한 오류 | `sudo npm install -g openclaw` 또는 nvm 사용 |
| 포트 18789 충돌 | `config.yaml`에서 `server.api_port` 변경 |
| Node.js 버전 오류 | `nvm install 22 && nvm use 22` |
| API 키 오류 | `.env` 파일 확인, 공백/줄바꿈 제거 |
| Docker 볼륨 권한 | `chmod 700 ~/.openclaw` |

---

## 참고 링크

- [공식 설치 문서](https://docs.openclaw.ai/install)
- [DigitalOcean 배포 튜토리얼](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)
- [Windows 설치 가이드](https://blink.new/blog/openclaw-windows-setup-guide-2026)
- [Thunderbit 설치 가이드](https://thunderbit.com/blog/openclaw-installation-guide)
