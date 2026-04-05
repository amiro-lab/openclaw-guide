#!/usr/bin/env bash
# OpenClaw macOS 원터치 설치 스크립트
# 사용법: bash install-mac.sh
set -euo pipefail

# ── 색상 ──────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}▶ $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $*${NC}"; }
error()   { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }
header()  { echo -e "\n${BOLD}$*${NC}"; }

# ── macOS 확인 ────────────────────────────────────────────────────────────────
[[ "$(uname)" == "Darwin" ]] || error "이 스크립트는 macOS 전용입니다."

header "=== OpenClaw macOS 설치 ==="

# ── 1. Homebrew ───────────────────────────────────────────────────────────────
header "[1/5] Homebrew 확인"
if command -v brew &>/dev/null; then
  success "Homebrew 이미 설치됨 ($(brew --version | head -1))"
else
  info "Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon PATH 설정
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    grep -qF 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile 2>/dev/null \
      || echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  fi
  success "Homebrew 설치 완료"
fi

# ── 2. Node.js 22 ─────────────────────────────────────────────────────────────
header "[2/5] Node.js 22 확인"
NEED_NODE=false
if command -v node &>/dev/null; then
  NODE_MAJOR=$(node -e "process.stdout.write(process.version.slice(1).split('.')[0])")
  if (( NODE_MAJOR >= 22 )); then
    success "Node.js $(node --version) 이미 설치됨"
  else
    warn "Node.js $(node --version) 감지 — v22 이상 필요"
    NEED_NODE=true
  fi
else
  NEED_NODE=true
fi

if $NEED_NODE; then
  # nvm이 있으면 nvm 사용, 없으면 Homebrew로 설치
  if command -v nvm &>/dev/null || [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    info "nvm으로 Node.js 22 설치 중..."
    # shellcheck source=/dev/null
    source "$HOME/.nvm/nvm.sh"
    nvm install 22
    nvm use 22
    nvm alias default 22
  else
    info "Homebrew로 Node.js 22 설치 중..."
    brew install node@22
    brew link --overwrite node@22
    # PATH에 추가
    NODE22_PREFIX="$(brew --prefix node@22)/bin"
    export PATH="$NODE22_PREFIX:$PATH"
    if [[ "$SHELL" == *zsh* ]]; then
      grep -qF "$NODE22_PREFIX" ~/.zprofile 2>/dev/null \
        || echo "export PATH=\"$NODE22_PREFIX:\$PATH\"" >> ~/.zprofile
    else
      grep -qF "$NODE22_PREFIX" ~/.bash_profile 2>/dev/null \
        || echo "export PATH=\"$NODE22_PREFIX:\$PATH\"" >> ~/.bash_profile
    fi
  fi
  success "Node.js $(node --version) 설치 완료"
fi

# ── 3. OpenClaw 설치 ──────────────────────────────────────────────────────────
header "[3/5] OpenClaw 설치"
if command -v openclaw &>/dev/null; then
  CURRENT_VER=$(openclaw --version 2>/dev/null || echo "unknown")
  info "최신 버전으로 업그레이드 중... (현재: $CURRENT_VER)"
  npm update -g openclaw
else
  info "OpenClaw 전역 설치 중..."
  npm install -g openclaw
fi
success "OpenClaw $(openclaw --version) 설치 완료"

# ── 4. 초기 설정 ──────────────────────────────────────────────────────────────
header "[4/5] 초기 설정"
OPENCLAW_DIR="$HOME/.openclaw"

if [[ -f "$OPENCLAW_DIR/openclaw.json" ]]; then
  success "기존 설정 파일 발견 ($OPENCLAW_DIR/openclaw.json) — 초기화 건너뜀"
else
  info "설정 디렉토리 생성: $OPENCLAW_DIR"
  mkdir -p "$OPENCLAW_DIR"
  chmod 700 "$OPENCLAW_DIR"

  # .env 템플릿 생성 (API 키 등)
  if [[ ! -f "$OPENCLAW_DIR/.env" ]]; then
    cat > "$OPENCLAW_DIR/.env" <<'ENVEOF'
# ─── LLM 프로바이더 API 키 (최소 하나 필수) ─────────────────────────
# OPENAI_API_KEY=sk-...
# ANTHROPIC_API_KEY=sk-ant-...

# ─── 채널 토큰 ────────────────────────────────────────────────────────
# TELEGRAM_BOT_TOKEN=123456:ABCDEF...
# DISCORD_BOT_TOKEN=...
# SLACK_BOT_TOKEN=xoxb-...
# SLACK_APP_TOKEN=xapp-...

# ─── Gateway 인증 (원격 접근 시 필수) ────────────────────────────────
# OPENCLAW_GATEWAY_TOKEN=change-me-to-a-long-random-token
# 생성: openssl rand -hex 32
ENVEOF
    chmod 600 "$OPENCLAW_DIR/.env"
    warn ".env 템플릿 생성됨 → API 키를 입력하세요: $OPENCLAW_DIR/.env"
  fi

  echo ""
  info "대화형 설정 마법사를 실행합니다 (Ctrl+C로 나중에 실행 가능)..."
  echo ""
  if openclaw init; then
    success "초기 설정 완료"
  else
    warn "초기화를 건너뛰었습니다. 나중에 'openclaw init'으로 실행하세요."
  fi
fi

# ── 5. Canvas 보안 설정 확인 ──────────────────────────────────────────────────
header "[5/5] 보안 설정"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"
if [[ -f "$CONFIG_FILE" ]]; then
  if grep -q '"bind".*"0.0.0.0"' "$CONFIG_FILE" 2>/dev/null; then
    warn "gateway.bind가 0.0.0.0으로 설정되어 있습니다."
    warn "보안을 위해 loopback으로 변경을 권장합니다:"
    warn "  openclaw config set gateway.bind loopback"
  else
    success "gateway 바인딩 설정 안전"
  fi
fi

# ── 완료 메시지 ───────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  OpenClaw 설치 완료!${NC}"
echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  다음 명령어로 시작하세요:"
echo ""
echo -e "  ${CYAN}openclaw start${NC}           # 포그라운드 실행"
echo -e "  ${CYAN}openclaw start --daemon${NC}  # 백그라운드 실행"
echo -e "  ${CYAN}openclaw status${NC}          # 상태 확인"
echo -e "  ${CYAN}openclaw logs${NC}            # 로그 보기"
echo ""
echo -e "  macOS 시작 시 자동 실행:"
echo -e "  ${CYAN}openclaw service install${NC}"
echo -e "  ${CYAN}openclaw service start${NC}"
echo ""
echo -e "  설정 파일: ${YELLOW}$OPENCLAW_DIR/openclaw.json${NC}"
echo -e "  API 키:    ${YELLOW}$OPENCLAW_DIR/.env${NC}"
echo ""
