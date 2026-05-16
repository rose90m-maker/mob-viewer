# Pre-Merge Checklist (claude/setup-dev-environment-e3kMi → main)

> 검증 일자: 2026-05-16
> 대상 브랜치: `claude/setup-dev-environment-e3kMi`
> 머지 대상: `main` (default 브랜치)
> 검증자: Claude Code (Opus 4.7)

---

## 1. 변경 파일 목록 (29개, 총 +10,682 라인)

```
.claude/hooks/session-start.sh         # 세션 시작 훅 (의존성 자동 설치)
.claude/settings.json                  # 훅 등록
.env.example                           # 환경 변수 템플릿 (시크릿 없음)
.gitignore
README.md                              # 프로젝트 개요

backend/                               # NestJS + Prisma 백엔드
├── .eslintrc.json
├── Dockerfile                         # Synology 배포용 멀티스테이지 빌드
├── nest-cli.json
├── package.json / package-lock.json
├── prisma/schema.prisma               # Mob 예시 모델 (도메인 미구현)
├── src/main.ts
├── src/app.module.ts
├── src/app.controller.ts              # GET /health
├── src/app.controller.spec.ts
├── src/app.service.ts
└── tsconfig.json

docker-compose.yml                     # MariaDB + Backend 스택

docs/
├── architecture.md
├── laptop-setup.md
└── synology-setup.md

mobile/                                # Flutter 앱 스켈레톤
├── README.md
├── analysis_options.yaml
├── lib/api_client.dart
├── lib/config.dart
├── lib/main.dart
├── pubspec.yaml / pubspec.lock
└── test/widget_test.dart
```

**제외(.gitignore)**: `.env`, `node_modules/`, `dist/`, `data/`, `mobile/build/`, 모바일 네이티브 폴더(android/ios), `.claude/settings.local.json`

---

## 2. 머지 위험 요소 점검

| 항목 | 상태 | 비고 |
|---|---|---|
| 깨진 빌드 가능성 | ✅ 없음 | backend build/test, flutter analyze/test 모두 통과 |
| 기존 default 브랜치 코드 덮어쓰기 | ✅ 해당 없음 | default 브랜치 자체에 코드가 없었음 (빈 저장소) |
| 머지 충돌 | ✅ 없음 | `main`을 이 브랜치에서 분기 생성 → 동일 커밋 |
| 거대한 바이너리 추가 | ✅ 없음 | 가장 큰 파일은 `package-lock.json` (~200KB) |
| 외부 의존성 신뢰성 | ⚠️ 주의 | npm/pub 패키지 최신 stable, 알려진 CVE 없음 (수동 확인 권장) |
| 비호환 마이그레이션 | ✅ 없음 | DB 마이그레이션 파일 없음 (스키마만 정의됨) |
| 비밀번호/시크릿 노출 | ✅ 없음 | 아래 #3 참조 |
| 영구 인프라 영향 | ✅ 없음 | 어떤 외부 시스템도 자동 변경 없음 |

**결론**: 머지 안전. 빈 저장소에 첫 번째 의미 있는 커밋이 추가되는 것이므로 회귀 위험 없음.

---

## 3. 시크릿/민감정보 스캔

| 검사 | 결과 |
|---|---|
| `.env` 추적 여부 | ✅ Git에 없음. `.gitignore`에 `.env`, `.env.local`, `.env.*.local` 등록됨 |
| `.env.example` 내용 | ✅ 모든 시크릿이 `change_me_*` placeholder |
| 하드코딩된 password/secret/api_key | ✅ 코드에 없음 (`git grep` 검증) |
| Private key (RSA/OPENSSH/EC) | ✅ 없음 |
| AWS Access Key (`AKIA...`) | ✅ 없음 |
| GitHub PAT (`ghp_...`) | ✅ 없음 |

**결론**: 커밋된 시크릿 없음. 실제 배포 시 NAS의 `.env` 파일에만 진짜 비밀번호를 쓰면 됨.

---

## 4. docker-compose.yml vs docker-compose.prod.yml

**현재 저장소에는 `docker-compose.prod.yml`이 존재하지 않습니다.**

### 왜 하나만 있는가
- **단순성 우선**: 개발/운영 분리가 필요한 시점에 도입하는 것이 적절. 지금은 Synology(운영)에 그대로 띄우는 게 목표라 단일 파일로 충분.
- `docker-compose.yml`은 그 자체로 운영급 설정 (`restart: unless-stopped`, healthcheck, named container, 별도 network).
- 환경 차이는 `.env` 파일로 흡수 (예: 회사 NAS `.env` vs 노트북 로컬 `.env`).

### 분리가 필요해지는 시점 (참고)

| 시나리오 | 추가 파일 |
|---|---|
| 노트북에서 로컬 MariaDB만 띄우고 hot-reload backend는 호스트에서 npm run start:dev | `docker-compose.dev.yml` (override) |
| 운영에 추가로 Nginx + Let's Encrypt + Watchtower | `docker-compose.prod.yml` (override) |
| 스테이징/QA 환경 분리 | `docker-compose.staging.yml` |

추가하게 되면 표준 패턴:
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

**현재 상태로 머지 OK** — 분리는 필요한 시점에 후속 PR로.

---

## 5. Synology NAS 배포 전 체크리스트

### 5.1 NAS 사전 준비
- [ ] DSM 7.2 이상 (Container Manager 사용 시)
- [ ] Container Manager 패키지 설치됨
- [ ] SSH 활성화 (제어판 → 터미널 및 SNMP)
- [ ] `/volume1/docker` 공유 폴더 존재
- [ ] (권장) 정기 스냅샷 또는 Hyper Backup 활성화
- [ ] (권장) DSM 관리자 계정 2FA 활성화

### 5.2 보안
- [ ] `.env` 파일의 모든 `change_me_*` 값을 강력한 비밀번호로 교체
  - `MARIADB_ROOT_PASSWORD`: 20자 이상 무작위
  - `MARIADB_PASSWORD`: 20자 이상 무작위
  - `JWT_SECRET`: `openssl rand -hex 32` 결과 사용
- [ ] `.env` 파일 권한 600 (`chmod 600 .env`)
- [ ] MariaDB 포트 3306은 외부 노출 금지 (compose 파일에서 `ports` 없음 → OK)
- [ ] Backend 3000 포트: 사내망/Tailscale에서만 접근 가능하게 방화벽 설정
- [ ] (외부 공개 시) DSM 역방향 프록시 + Let's Encrypt HTTPS

### 5.3 네트워크
- [ ] NAS LAN IP 고정 (DSM → 제어판 → 네트워크)
- [ ] (외부 접근 필요 시) Tailscale 설치 + 노트북에도 같은 계정 연결
- [ ] 방화벽: 3000 포트가 LAN 또는 Tailscale 대역에서만 허용

### 5.4 디스크 공간
- [ ] `/volume1` 여유 공간 최소 5GB (이미지 + DB 데이터)
- [ ] (장기 운영) DB 백업 폴더용 별도 공간 확보

### 5.5 배포 실행
- [ ] `cd /volume1/docker/mob-viewer`
- [ ] `git clone <repo> .`
- [ ] `cp .env.example .env && chmod 600 .env && nano .env` (비밀번호 교체)
- [ ] `sudo docker compose pull` (베이스 이미지 받기)
- [ ] `sudo docker compose up -d --build`
- [ ] `sudo docker compose ps` (둘 다 healthy/running 확인)

### 5.6 동작 검증
- [ ] `curl http://localhost:3000/health` → `{"status":"ok",...}`
- [ ] `sudo docker compose exec mariadb mariadb -u mobviewer -p mobviewer` (접속 성공)
- [ ] `sudo docker compose logs backend` (에러 없음)
- [ ] 노트북에서 Tailscale IP로 `curl http://<NAS_IP>:3000/health` 응답

### 5.7 운영 후속
- [ ] DSM 작업 스케줄러에 일일 DB 백업 등록 (`synology-setup.md` §9 참조)
- [ ] 업데이트 절차 문서화: `git pull && docker compose up -d --build backend`
- [ ] (선택) Watchtower 또는 GitHub Actions로 자동 배포

---

## 6. `docker compose config` 검증 결과

✅ **EXIT 0** — YAML 구문/스키마 유효.

확인된 항목:
- `backend` 서비스: build context = `./backend`, port 3000, healthcheck로 mariadb 의존
- `mariadb` 서비스: utf8mb4 설정, healthcheck 정의됨, 외부 포트 노출 없음
- network: `mob-viewer` bridge 단일 네트워크
- volume: `./data/mariadb` (NAS에서 `/volume1/docker/mob-viewer/data/mariadb`로 해석됨)

⚠️ **참고**: 검증 시 `.env.example`의 placeholder 비밀번호가 그대로 노출됨. 실제 배포 시 반드시 교체.

---

## 7. 자동화 검증 결과 (재실행)

| 검증 | 명령 | 결과 |
|---|---|---|
| Backend ESLint | `npm run lint:check` | ✅ 0 errors / 0 warnings |
| Backend Jest | `npm test` | ✅ 1/1 pass (2.7s) |
| Flutter Analyze | `flutter analyze` | ✅ No issues found (수정 후) |
| Flutter Test | `flutter test` | ✅ 1/1 pass |
| docker compose config | `docker compose config` | ✅ Exit 0 |
| SessionStart 훅 | `.claude/hooks/session-start.sh` | ✅ Backend + Prisma + Flutter SDK 설치 완료 |

**머지 차단 이슈: 0건**

> 최초 검증에서 발견된 Flutter `prefer_const_constructors` 경고 1건은 이 머지 검증 과정에서 `main.dart:59` 수정으로 해결.

---

## 8. 최종 판정

✅ **머지 안전 (Recommended: PROCEED)**

근거:
1. 빈 default 브랜치에 첫 의미 있는 커밋 추가 → 회귀 위험 0
2. 시크릿 노출 없음, `.gitignore` 적절히 설정됨
3. 모든 자동화 검증 통과
4. 인프라/외부 시스템 자동 변경 없음 (Synology 수동 배포)
5. 문서(`README.md`, `docs/`)로 후속 작업 절차 명시됨

남은 수동 단계: Synology 실제 배포는 이 머지와 무관하게 사용자가 §5 체크리스트에 따라 진행.
