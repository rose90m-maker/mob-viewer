# 노트북 개발 환경 셋업

집/회사 노트북 모두 동일한 절차로 셋업. **노트북에는 코드를 영구 저장하지 않습니다** — 작업물은 항상 Git을 통해 Synology(또는 GitHub)로 동기화.

---

## 0. 필요한 것 (최소 구성)

| 도구 | 용도 | 설치 |
|---|---|---|
| Git | 코드 동기화 | [git-scm.com](https://git-scm.com) |
| Claude Code | 개발 도구 | [claude.ai/code](https://claude.ai/code) 또는 CLI |
| SSH 클라이언트 | NAS 접속 | Windows: 기본 OpenSSH / Mac/Linux: 기본 |
| (선택) Tailscale | 외부에서 NAS 접근 | [tailscale.com](https://tailscale.com) |

> **이게 다입니다.** 노트북에 Node.js / Flutter / MariaDB 깔 필요 없음 — 모두 NAS 또는 Claude Code 환경에 있음.

---

## 1. 사용 시나리오 (3가지 중 선택)

### 시나리오 A: Claude Code on the web (가장 가벼움)
1. 브라우저에서 [claude.ai/code](https://claude.ai/code) 접속
2. `rose90m-maker/mob-viewer` 리포지토리 연결
3. 세션 시작 → `.claude/hooks/session-start.sh`가 자동으로 의존성 설치
4. 코드 수정 후 commit & push → GitHub로 반영
5. NAS에서 `git pull && docker compose up -d --build backend` (또는 자동화)

**장점**: 노트북에 진짜로 Git만 있으면 됨. 백업/이력 모두 클라우드.
**단점**: 안드로이드 실기기 빌드는 별도 Mac/PC 필요 (또는 Codemagic CI).

### 시나리오 B: 로컬 Claude Code CLI + NAS Git remote
회사 보안상 GitHub에 코드를 못 올린다면:

```bash
# 최초 1회
git clone <admin>@<NAS_IP>:/volume1/git/mob-viewer.git
cd mob-viewer
claude  # Claude Code CLI 실행
```

작업 후:
```bash
git push  # NAS로 직접 푸시
```

NAS에서 webhook이나 cron으로 자동 배포 가능.

### 시나리오 C: NAS에서 직접 Claude Code 실행 (가장 중앙집중적)
Synology에 SSH로 들어가서 거기서 Claude Code CLI를 실행.

```bash
ssh <admin>@<NAS_IP>
tmux new -s dev          # tmux 세션 시작 (껐다 켜도 유지)
cd /volume1/docker/mob-viewer
claude
```

집에서 접속해도 `tmux attach -t dev`로 똑같은 세션에 이어 작업.

**제약**: Synology DSM의 sudo 권한 / 패키지 설치 제약 때문에 Node.js, Flutter 등을 NAS에 직접 설치하기 까다로움. **Docker 안의 dev container**를 따로 만들어 거기서 Claude Code 실행하는 변형도 가능 (고급).

---

## 2. Android 빌드는 어디서?

| 방법 | 장단점 |
|---|---|
| 노트북에서 Flutter 설치하여 빌드 | 가장 빠른 개발 사이클. 노트북 한 대 추가 셋업 비용 |
| Claude Code on the web에서 APK 빌드 | Hook이 Flutter SDK 자동 설치. 다운로드해서 폰에 설치 |
| GitHub Actions / Codemagic | push할 때마다 자동 빌드. 무료 한도 있음 |

**개발 초기 추천**: 노트북 1대 (예: 회사 PC)에만 Flutter 설치하고 거기서 실기기 디버깅, 그 외 코드 수정/리뷰는 어디서든.

---

## 3. Flutter 설치 (선택, Android 빌드용)

회사 PC에만 설치 권장:

### Windows
```powershell
# 1. Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable C:\flutter
# 환경변수 PATH에 C:\flutter\bin 추가

# 2. Android Studio 설치 → SDK Manager에서 Android SDK 다운로드

# 3. 검증
flutter doctor
```

### Mac / Linux
```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
flutter doctor
```

---

## 4. 일상 워크플로

### 시나리오 A (Claude Code on the web) 기준

1. **시작**: claude.ai/code 접속 → 세션 시작
2. **개발**: Claude Code와 대화하며 코드 작성
3. **빌드/테스트**: 세션 안에서 `cd backend && npm test` 등
4. **푸시**: `git add . && git commit -m "..." && git push`
5. **배포** (NAS에서):
   ```bash
   ssh <admin>@<NAS_IP>
   cd /volume1/docker/mob-viewer
   git pull && sudo docker compose up -d --build backend
   ```
6. **앱 테스트**: Android 폰에서 API URL을 `http://<tailscale_NAS_IP>:3000`으로 설정

---

## 5. Backend가 어디 있는지 앱이 알게 하기

`mobile/lib/config.dart` 같은 곳에 환경별 API URL을 둠:

```dart
class ApiConfig {
  // 회사 LAN에 있을 때
  static const String lan = 'http://192.168.x.x:3000';
  // Tailscale로 어디서든
  static const String tailscale = 'http://100.x.x.x:3000';
  // 외부 공개 도메인 (역방향 프록시 설정 후)
  static const String public = 'https://api.example.com';

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: tailscale,
  );
}
```

빌드 시 `flutter build apk --dart-define=API_URL=https://api.example.com`로 주입.

---

## FAQ

**Q. 노트북 잃어버리면 어쩌죠?**
A. 코드는 NAS와 GitHub에 있으니 새 노트북에 Git만 깔면 끝. 진짜로 노트북엔 아무것도 없습니다.

**Q. 인터넷 안 되는 곳에서 작업하려면?**
A. 가능은 하지만 이 구성과는 맞지 않습니다. 오프라인 시 노트북 로컬에 Flutter + Node.js 풀세팅이 필요.

**Q. 두 명 이상이 동시에 작업하면?**
A. Git 브랜치 분기 → PR/MR → 머지. 표준 Git 흐름.
