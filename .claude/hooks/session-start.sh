#!/bin/bash
# Claude Code on the web 세션이 시작될 때 의존성을 설치합니다.
# 로컬 머신에서는 실행되지 않도록 가드합니다.

set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  echo "Local environment detected — skipping remote setup."
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

echo "==> mob-viewer session setup"
echo "    Project: $PROJECT_DIR"

# --- Backend (Node.js / NestJS / Prisma) ---
if [ -f "$PROJECT_DIR/backend/package.json" ]; then
  echo "==> Installing backend dependencies (npm install)..."
  (cd "$PROJECT_DIR/backend" && npm install --no-audit --no-fund)

  if [ -f "$PROJECT_DIR/backend/prisma/schema.prisma" ]; then
    echo "==> Generating Prisma client..."
    (cd "$PROJECT_DIR/backend" && npx prisma generate) || \
      echo "    (prisma generate failed — will retry when DATABASE_URL is set)"
  fi
fi

# --- Flutter SDK (Android 빌드 / Dart 분석용) ---
FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "==> Installing Flutter SDK (stable) — first run only, ~5min..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR" \
    > /dev/null 2>&1 || echo "    (Flutter clone failed — skipping)"
fi

if [ -d "$FLUTTER_DIR" ]; then
  echo "export PATH=\"\$PATH:$FLUTTER_DIR/bin\"" >> "$CLAUDE_ENV_FILE"
  export PATH="$PATH:$FLUTTER_DIR/bin"

  if [ -f "$PROJECT_DIR/mobile/pubspec.yaml" ]; then
    echo "==> Running flutter pub get..."
    (cd "$PROJECT_DIR/mobile" && flutter --suppress-analytics pub get) || \
      echo "    (flutter pub get failed — Flutter may need more setup)"
  fi
fi

echo "==> Session setup complete."
