# Synology NAS Docker 셋업 가이드

회사 Synology NAS에 Backend API를 띄우는 단계별 가이드.
**DB는 DSM `MariaDB 10` 패키지를 그대로 사용**하고, Backend 컨테이너에서 호스트 MariaDB로 연결합니다.

> 기준: DSM 7.2 이상, Container Manager + MariaDB 10 + phpMyAdmin 패키지.

---

## 1. 사전 준비

### 1.1 SSH 활성화
1. DSM → **제어판** → **터미널 및 SNMP** → **SSH 서비스 활성화** 체크
2. 포트 22 (또는 변경한 포트)로 SSH 접속이 되는지 확인:
   ```bash
   ssh <admin>@<NAS_IP>
   ```

### 1.2 Container Manager 설치
1. DSM → **패키지 센터** → "Container Manager" 검색 → 설치
   - DSM 7.1 이하: "Docker" 패키지

### 1.3 MariaDB 10 + phpMyAdmin 설치/설정
1. DSM → **패키지 센터** → "MariaDB 10" 설치
2. MariaDB 10 패키지 → **TCP/IP 연결 활성화** 체크 + 포트 확인 (기본 3307 또는 3306)
3. 루트 비밀번호 설정
4. DSM → **패키지 센터** → "phpMyAdmin" 설치 (DB GUI용)

### 1.4 작업 폴더 생성
1. DSM → **File Station** → `docker` 공유 폴더가 없으면 생성 (Container Manager 설치 시 자동 생성됨)
2. SSH로 접속해서 프로젝트 폴더 생성:
   ```bash
   sudo mkdir -p /volume1/docker/mob-viewer
   sudo chown -R $(whoami):users /volume1/docker/mob-viewer
   cd /volume1/docker/mob-viewer
   ```

---

## 2. 소스코드 배치

### 옵션 A: GitHub에서 clone (추천)
```bash
cd /volume1/docker/mob-viewer
git clone https://github.com/<your-org>/mob-viewer.git .
```

### 옵션 B: Synology Git Server 사용
1. 패키지 센터에서 **Git Server** 설치
2. 사용자 권한 부여 후 노트북에서:
   ```bash
   ssh <admin>@<NAS_IP> "git init --bare /volume1/git/mob-viewer.git"
   git remote add nas <admin>@<NAS_IP>:/volume1/git/mob-viewer.git
   git push nas main
   ```

---

## 3. mob-viewer DB / 사용자 생성 (phpMyAdmin)

DSM → **phpMyAdmin** 접속 → root 로그인 → 상단 **SQL** 탭 → 아래 붙여넣고 실행:

```sql
CREATE DATABASE mobviewer
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER 'mobviewer'@'%' IDENTIFIED BY '<강력한_앱_비밀번호>';
GRANT ALL PRIVILEGES ON mobviewer.* TO 'mobviewer'@'%';
FLUSH PRIVILEGES;
```

`<강력한_앱_비밀번호>`는 `openssl rand -base64 24` 등으로 생성. 다음 단계 `.env`의 `DATABASE_URL`과 반드시 동일하게 사용.

> 호스트가 `%`인 이유: Backend 컨테이너에서 Docker 내부망 IP로 접속하므로 `localhost`만 허용하면 거부됨.

---

## 4. 환경 변수 설정

```bash
cd /volume1/docker/mob-viewer
cp .env.example .env
chmod 600 .env
nano .env
```

`.env` 작성 예시:
```env
NODE_ENV=production
BACKEND_PORT=3000

# host.docker.internal = NAS 호스트 (Backend 컨테이너 → DSM MariaDB)
# 포트는 DSM MariaDB 10 설정에서 확인 (기본 3307, 사용 NAS에 따라 3306일 수 있음)
DATABASE_URL=mysql://mobviewer:<강력한_앱_비밀번호>@host.docker.internal:3306/mobviewer

JWT_SECRET=<openssl rand -hex 32 결과>
```

**`.env` 파일은 절대 Git에 커밋하지 마세요.** (`.gitignore`에 이미 포함됨)

---

## 4. Docker Compose 실행

### 방법 A: SSH로 (가장 단순)
```bash
cd /volume1/docker/mob-viewer
sudo docker compose up -d
sudo docker compose ps
sudo docker compose logs -f backend
```

### 방법 B: Container Manager GUI로 (DSM 7.2+)
1. Container Manager → **프로젝트** → **생성**
2. 프로젝트명: `mob-viewer`
3. 경로: `/volume1/docker/mob-viewer`
4. 소스: "docker-compose.yml 사용" 선택
5. 다음 → 다음 → **완료** (자동 빌드 및 시작)

---

## 5. 동작 확인

### 5.1 컨테이너 상태
```bash
sudo docker compose ps
```
`mariadb`, `backend` 두 컨테이너가 모두 `running` 상태여야 합니다.

### 5.2 Backend Health Check
```bash
curl http://localhost:3000/health
# {"status":"ok","db":"up"}  <- 이런 응답이 나와야 정상
```

### 5.3 MariaDB 접속 확인
```bash
sudo docker compose exec mariadb mariadb -u mobviewer -p mobviewer
# 비밀번호 입력 후 SQL prompt 진입되면 OK
```

---

## 6. 외부 접근 설정

### 6.1 (개발 단계) 사내망 IP로 접근
- 같은 LAN에 있을 때:
  - Backend: `http://<NAS_IP>:3000`
  - DSM 제어판에서 방화벽이 3000 포트를 차단하지 않는지 확인

### 6.2 (집에서 접근) Tailscale 추천
Synology에 Tailscale 설치하면 어디서든 사설 IP로 접근 가능 (포트포워딩 불필요):

1. 패키지 센터 → **Tailscale** 설치 (DSM 7.2+ 공식 지원)
2. DSM에서 Tailscale 앱 열고 로그인 → 사용자 계정으로 연결
3. 노트북에도 Tailscale 설치 후 같은 계정으로 로그인
4. 어디서든 `http://<tailscale_NAS_IP>:3000`으로 접근 가능

### 6.3 (외부 공개) Reverse Proxy + HTTPS
모바일 앱을 외부에서도 써야 한다면:
1. DSM → **제어판** → **로그인 포털** → **고급** → **역방향 프록시** → **생성**
2. 소스: `https://api.<your-domain>.com:443`
3. 대상: `http://localhost:3000`
4. **Let's Encrypt** 인증서 발급 (제어판 → 보안 → 인증서)

---

## 7. 자동 시작 / 재시작 정책

`docker-compose.yml`의 `restart: unless-stopped` 덕에 NAS 재부팅 후에도 자동 시작됩니다.

확인:
```bash
sudo docker inspect mob-viewer-backend | grep -i restart
```

---

## 8. 업데이트 워크플로

노트북에서 코드 수정 → push 한 뒤 NAS에서:

```bash
cd /volume1/docker/mob-viewer
git pull
sudo docker compose up -d --build backend
sudo docker compose logs -f backend
```

> 자동화하려면 GitHub Actions에서 SSH로 위 명령 실행하거나 [Watchtower](https://containrrr.dev/watchtower/) 컨테이너 추가 고려.

---

## 9. 백업

### MariaDB 백업 (DSM 작업 스케줄러로 매일 자동화)
```bash
#!/bin/bash
BACKUP_DIR=/volume1/docker/mob-viewer/backups
mkdir -p $BACKUP_DIR
sudo docker compose -f /volume1/docker/mob-viewer/docker-compose.yml \
  exec -T mariadb mariadb-dump -u root -p${MARIADB_ROOT_PASSWORD} mobviewer \
  | gzip > $BACKUP_DIR/mobviewer-$(date +%Y%m%d).sql.gz
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete
```

DSM → **제어판** → **작업 스케줄러** → 사용자 정의 스크립트로 등록.

---

## 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| `docker: command not found` | Container Manager가 설치 안 됐거나 `sudo` 필요 |
| `port already allocated` | 3000 또는 3306 포트가 다른 컨테이너에서 사용 중. `docker-compose.yml`의 `ports` 수정 |
| Backend 컨테이너가 계속 재시작 | `docker compose logs backend`로 로그 확인. 대부분 `DATABASE_URL` 오타 |
| MariaDB 한글 깨짐 | `docker-compose.yml`에서 `--character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci` 옵션 확인 |
| `git pull` 권한 거부 | `git config --global --add safe.directory /volume1/docker/mob-viewer` |
