# mob-viewer

Android/iOS mob-viewer 앱 + NestJS Backend + MariaDB.
회사 Synology NAS의 Docker에서 모든 백엔드를 실행하고, 집/회사 노트북에서는 Claude Code만으로 개발하는 구성.

## 아키텍처

```
┌─────────────────────────────┐         ┌──────────────────────────────────┐
│  집/회사 노트북               │   SSH    │  회사 Synology NAS (Docker)        │
│  ──────────────              │ ───────→ │  ──────────────────────           │
│  Claude Code (CLI 또는 web)  │   Git    │  ├─ MariaDB 컨테이너               │
│  SSH/Git 클라이언트만 필요    │ ←───────│  ├─ Backend (NestJS) 컨테이너      │
└─────────────────────────────┘          │  └─ (선택) Gitea 컨테이너          │
                                          │                                   │
                                          │  소스코드 / DB 모두 NAS에 저장      │
                                          └──────────────────────────────────┘
                                                       ↑
                                                       │ HTTPS API
                                                       │
                                          ┌────────────┴───────────┐
                                          │  Android/iOS 앱 (Flutter)│
                                          └────────────────────────┘
```

## 구성 요소

- **backend/** — NestJS + Prisma. MariaDB와 통신. Docker로 Synology에 배포.
- **mobile/** — Flutter 앱 (Android 우선, iOS는 나중).
- **docker-compose.yml** — Synology에 띄울 MariaDB + Backend 스택.
- **docs/** — Synology 설정, 노트북 설정, 아키텍처 문서.

## 빠른 시작

1. **Synology 셋업**: [`docs/synology-setup.md`](docs/synology-setup.md)
2. **노트북 개발 환경**: [`docs/laptop-setup.md`](docs/laptop-setup.md)
3. **아키텍처 상세**: [`docs/architecture.md`](docs/architecture.md)

## 폴더 구조

```
mob-viewer/
├── README.md
├── docker-compose.yml          # Synology 배포용
├── .env.example                # 환경 변수 템플릿
├── docs/
│   ├── synology-setup.md
│   ├── laptop-setup.md
│   └── architecture.md
├── backend/
│   ├── package.json
│   ├── Dockerfile
│   ├── prisma/schema.prisma
│   └── src/                    # NestJS 소스
├── mobile/
│   ├── pubspec.yaml
│   └── lib/main.dart           # Flutter 소스
└── .claude/                    # Claude Code on the web 훅
    ├── settings.json
    └── hooks/session-start.sh
```
