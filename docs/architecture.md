# 아키텍처 설명

## 전체 그림

```
┌─────────────────────────┐
│ 집/회사 노트북             │
│ ──────────────          │
│ • Git                   │
│ • Claude Code           │
│ • SSH (+ Tailscale)     │
│ (그 외 아무것도 영구 저장 X) │
└────────────┬────────────┘
             │
             │ git push/pull, ssh
             ▼
┌─────────────────────────────────────────────┐
│ 회사 Synology NAS                              │
│ ───────────────────                          │
│                                              │
│  ┌──────────────┐    ┌──────────────────┐   │
│  │  MariaDB     │◀───│  Backend         │   │
│  │  (Docker)    │    │  (NestJS+Prisma) │   │
│  │  port 3306   │    │  port 3000       │   │
│  └──────────────┘    └────────▲─────────┘   │
│                                │             │
│  소스코드: /volume1/docker/mob-viewer         │
│  DB 파일: /volume1/docker/mob-viewer/data/db │
└────────────────────────────────┼────────────┘
                                 │
                                 │ HTTPS / Tailscale
                                 ▼
                    ┌────────────────────────┐
                    │  Android/iOS 앱         │
                    │  (Flutter)             │
                    └────────────────────────┘
```

## 데이터 흐름

1. **개발자가 코드 수정** (노트북 Claude Code)
2. **Git push** → GitHub 또는 Synology Git Server
3. **NAS에서 Git pull + Docker rebuild** (수동 or 자동화)
4. **Backend 컨테이너 재시작** → 새 코드로 API 서비스 재개
5. **앱이 API 호출** → Backend → MariaDB → 응답

## 왜 이 구성?

### 노트북을 "Thin Client"로
- 노트북 분실/교체 시 영향 최소
- 집/회사 어디서 작업해도 똑같은 상태 (코드는 항상 NAS)
- 보안: 회사 코드/DB가 노트북에 잔존하지 않음

### Synology를 중앙 허브로
- 이미 24/7 켜져 있고 백업 정책 있는 머신
- DSM이 모니터링/스냅샷/스케줄링 다 제공
- Docker로 격리된 환경 — 다른 NAS 서비스에 영향 없음

### Docker로 백엔드 패키징
- "내 컴퓨터에선 되는데" 문제 제거
- MariaDB와 Backend를 같은 docker network에 두면 호스트명으로 통신 (`mariadb:3306`)
- 롤백 쉬움 (`docker compose down && git checkout <old> && docker compose up -d`)

## 보안 체크리스트

- [ ] `.env`는 절대 Git에 커밋 안 함 (`.gitignore`에 등록됨)
- [ ] MariaDB 포트(3306)는 외부에 노출하지 않음 — Docker 내부망에서만 접근
- [ ] Backend 외부 노출 시 HTTPS 필수 (DSM Let's Encrypt)
- [ ] SSH는 키 인증 사용, 비밀번호 로그인 비활성화 권장
- [ ] DSM 관리자 계정 2FA 활성화
- [ ] 정기 백업: DB dump + 코드 리포지토리

## 확장 시나리오

### 사용자 증가하면
- Backend 컨테이너 여러 개 + 앞에 Nginx 로드밸런서
- MariaDB → MariaDB Galera Cluster (or 외부 RDS로 마이그레이션)

### iOS 빌드 필요해지면
- 별도 Mac mini → Codemagic / Bitrise 등 CI 도입
- App Store Connect 자동 업로드

### 외부 협업자 추가되면
- GitHub 미러 (private) + 협업자에게는 Tailscale 액세스만 제공
