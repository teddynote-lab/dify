# Dify 개발 매뉴얼

## 📋 목차
- [빠른 시작](#빠른-시작)
- [Makefile 명령어](#makefile-명령어)
- [브랜딩 설정](#브랜딩-설정)
- [개발 환경 설정](#개발-환경-설정)
- [Docker 환경](#docker-환경)
- [Azure VM 배포](#azure-vm-배포)
- [문제 해결](#문제-해결)
- [외부 초대 API](#외부-초대-api)

## 빠른 시작

### 1. 프로젝트 클론
```bash
git clone https://github.com/your-org/dify.git
cd dify
```

### 2. 환경 설정
```bash
# Docker 환경 파일 복사
cp docker/.env.example docker/.env

# Web 환경 파일 복사
cp web/.env.example web/.env

# API 환경 파일 복사
cp api/.env.example api/.env
```

### 3. 서비스 실행
```bash
# 모든 서비스를 Docker로 실행
make up

# 또는 프론트엔드만 로컬에서 개발 (추천)
make dev
```

## Makefile 명령어

### 핵심 명령어

| 명령어 | 설명 |
|--------|------|
| `make down` | 모든 Docker 컨테이너 중지 |
| `make build` | 모든 Docker 이미지를 클린 빌드 |
| `make up` | 모든 서비스를 Docker로 실행 |
| `make dev` | Docker 서비스 실행 + 프론트엔드만 로컬 실행 (개발 추천) |

### 코드 품질 명령어

| 명령어 | 설명 |
|--------|------|
| `make lint` | 백엔드와 프론트엔드 린터 실행 |
| `make type-check` | 타입 체크 실행 |
| `make format` | 코드 포맷팅 |

### 사용 예시
```bash
# 개발 시작
make dev

# 개발 종료
make down

# 전체 재빌드가 필요한 경우
make down
make build
make up
```

## 브랜딩 설정

### 1. 브랜드 이미지 준비

#### 자동 업데이트 (권장)
브랜딩 업데이트 스크립트를 사용하면 이미지 복사와 컨테이너 재시작을 자동으로 처리합니다:
```bash
# 브랜딩 이미지와 함께 실행 (권장)
./scripts/update-branding.sh your-logo.svg

# 또는 수동으로 파일을 복사한 후 실행
./scripts/update-branding.sh
```

#### 수동 설정
직접 설정하려면 다음 단계를 따르세요:
```bash
# 디렉토리 생성
mkdir -p docker/volumes/branding

# 브랜드 이미지 파일 복사 (SVG 권장)
cp your-logo.svg docker/volumes/branding/profile.svg

# 웹 컨테이너 재시작 (필수)
docker restart docker-web-1
```

### 2. 환경 변수 설정

#### docker/.env 파일
```env
# 브랜딩 설정
NEXT_PUBLIC_BRAND_NAME=mySUNI
NEXT_PUBLIC_BRAND_URL=https://connect.mysuni.com
```

#### web/.env 파일
```env
# 브랜딩 설정
NEXT_PUBLIC_BRAND_NAME=mySUNI
NEXT_PUBLIC_BRAND_URL=https://connect.mysuni.com
```

### 3. 브랜딩 적용 확인
- 브랜드 이미지: `/branding/profile.svg` 파일이 모든 프로필 이미지로 사용됨
- 브랜드 이름: 애플리케이션 전체에서 `NEXT_PUBLIC_BRAND_NAME` 사용
- 브랜드 URL: 로고 클릭 시 `NEXT_PUBLIC_BRAND_URL`로 이동

**참고**:
- 이미지 파일은 `/branding/profile.svg`로 고정되어 있으며, 별도의 환경변수 설정이 필요하지 않습니다.
- 브랜딩 이미지 변경 후에는 웹 컨테이너를 재시작해야 합니다: `docker restart docker-web-1`

## 개발 환경 설정

### 필수 요구사항
- Docker & Docker Compose
- Node.js 18+ & pnpm
- Python 3.12+
- UV (Python 패키지 관리자)

### 프론트엔드 개발

#### 패키지 설치
```bash
cd web
pnpm install
```

#### 개발 서버 실행
```bash
# Docker 서비스와 함께 실행 (추천)
make dev

# 또는 프론트엔드만 단독 실행
cd web
pnpm dev
```

#### 빌드
```bash
cd web
pnpm build
```

### 백엔드 개발

#### 패키지 설치
```bash
cd api
uv sync --dev
```

#### 데이터베이스 마이그레이션
```bash
cd api
uv run flask db upgrade
```

#### API 서버 실행 (로컬)
```bash
cd api
uv run flask run --host 0.0.0.0 --port 5001
```

## Docker 환경

### Docker Compose 구성
- **api**: Flask API 서버
- **worker**: Celery 워커
- **worker_beat**: Celery 스케줄러
- **web**: Next.js 프론트엔드
- **nginx**: 리버스 프록시
- **db**: PostgreSQL 데이터베이스
- **redis**: 캐시 & 큐
- **weaviate**: 벡터 데이터베이스
- **sandbox**: 코드 실행 샌드박스
- **ssrf_proxy**: SSRF 보호 프록시

### 볼륨 구조
```
docker/volumes/
├── branding/        # 브랜딩 이미지
├── db/              # PostgreSQL 데이터
├── redis/           # Redis 데이터
├── weaviate/        # Weaviate 데이터
└── plugin_daemon/   # 플러그인 데이터
```

### Docker 명령어

```bash
# 특정 서비스 로그 확인
docker logs docker-api-1 -f

# 컨테이너 접속
docker exec -it docker-api-1 bash

# 볼륨 초기화
docker compose -f docker/docker-compose.yaml down -v
```

## 문제 해결

### 포트 충돌
다음 포트가 사용 가능한지 확인하세요:
- 80: Nginx
- 3000: 프론트엔드 (개발)
- 5001: API
- 5432: PostgreSQL
- 6379: Redis
- 8080: Weaviate

### 권한 문제
```bash
# Docker 소켓 권한
sudo chmod 666 /var/run/docker.sock

# 볼륨 권한
sudo chown -R $USER:$USER docker/volumes
```

### 캐시 초기화
```bash
# Docker 캐시 초기화
docker system prune -a

# 프론트엔드 캐시
cd web
rm -rf .next node_modules
pnpm install

# 백엔드 캐시
cd api
rm -rf .venv
uv sync --dev
```

### 데이터베이스 리셋
```bash
# 데이터베이스 컨테이너 재생성
docker compose -f docker/docker-compose.yaml down db
docker compose -f docker/docker-compose.yaml up -d db

# 마이그레이션 재실행
cd api
uv run flask db upgrade
```

## 기본 언어 설정

기본 인터페이스 언어는 한국어(`ko-KR`)로 설정되어 있습니다.

변경하려면 다음 파일을 수정하세요:
- `web/i18n-config/index.ts`: `defaultLocale` 값 변경
- `web/context/i18n.ts`: `I18NContext` 기본값 변경

## 유용한 팁

### 개발 워크플로우
1. `make dev`로 개발 환경 시작
2. 프론트엔드 코드 수정 시 자동 리로드
3. 백엔드 코드 수정 시 API 컨테이너 재시작: `docker restart docker-api-1`
4. 작업 완료 후 `make down`

### 로그 모니터링
```bash
# 모든 서비스 로그
docker compose -f docker/docker-compose.yaml logs -f

# API 로그만
docker logs docker-api-1 -f

# Worker 로그
docker logs docker-worker-1 -f
```

### 성능 최적화
- 개발 시 프론트엔드는 로컬 실행 추천 (`make dev`)
- 불필요한 컨테이너는 중지: `docker stop docker-web-1`
- 정기적인 Docker 정리: `docker system prune`

## Azure VM 배포

### 개요

Azure VM에서 Dify를 배포할 때 외부 저장소를 설정하고 Docker 볼륨을 마이그레이션하는 자동화 스크립트를 제공합니다.

### 전제 조건

#### 1. Azure VM 요구사항
- **OS**: Ubuntu 20.04 LTS 이상
- **VM 크기**: Standard_D4s_v3 이상 권장
- **네트워크**: HTTP(80), HTTPS(443), SSH(22) 포트 개방
- **관리 ID**: 시스템 할당 관리 ID 활성화 (권장)

#### 2. 추가 디스크 연결
```bash
# Azure CLI로 1TB 디스크 생성 및 연결
az disk create \
  --resource-group myResourceGroup \
  --name dify-storage-disk \
  --size-gb 1024 \
  --sku Premium_LRS

az vm disk attach \
  --resource-group myResourceGroup \
  --vm-name myVM \
  --name dify-storage-disk
```

#### 3. 필수 패키지 설치
```bash
# 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Azure CLI 설치 (선택사항, 권장)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 기타 필수 패키지
sudo apt install -y git curl wget unzip
```

### Azure 저장소 설정 스크립트

#### 1. 스크립트 다운로드 및 실행권한 부여
```bash
# Dify 프로젝트 클론
git clone https://github.com/your-org/dify.git
cd dify

# 스크립트 실행권한 부여
chmod +x scripts/azure-storage-setup.sh
```

#### 2. 기본 설정으로 실행
```bash
# 기본 설정으로 Azure 저장소 설정
sudo ./scripts/azure-storage-setup.sh
```

#### 3. 고급 옵션
```bash
# 사용법 확인
sudo ./scripts/azure-storage-setup.sh --help

# 커스텀 설정으로 실행
sudo ./scripts/azure-storage-setup.sh \
  --disk-size 2T \
  --mount-point /mnt/dify \
  --backup-dir /opt/backups

# 드라이런 모드 (실제 변경 없이 테스트)
sudo ./scripts/azure-storage-setup.sh --dry-run

# 백업 없이 실행 (권장하지 않음)
sudo ./scripts/azure-storage-setup.sh --skip-backup
```

### 스크립트 기능

#### 자동화된 기능
- ✅ Azure VM 환경 자동 감지
- ✅ 1TB 디스크 자동 탐지 및 파티셔닝
- ✅ GPT 파티션 테이블 생성
- ✅ ext4 파일시스템 포맷
- ✅ 자동 마운트 및 fstab 설정
- ✅ Docker 볼륨 백업 및 마이그레이션
- ✅ 심볼릭 링크를 통한 볼륨 경로 리디렉션

#### Azure 특화 기능
- 🔷 Azure CLI 통합 및 관리 ID 인증
- 🔷 Azure 디스크 자동 태깅
- 🔷 Azure Backup 볼트 설정
- 🔷 Azure Monitor 메트릭 알림
- 🔷 VM 메타데이터 서비스 활용

#### 모니터링 및 안전성
- 📊 15분마다 저장소 사용량 모니터링
- 📊 85% 사용량 초과 시 자동 알림
- 🔄 자동 롤백 스크립트 생성
- 📝 상세한 로그 기록 (`/var/log/dify-azure/`)

### 배포 과정

#### 1. 저장소 설정
```bash
# Azure 저장소 설정 실행
sudo ./scripts/azure-storage-setup.sh

# 실행 결과 확인
df -h /opt/dify-data
ls -la /opt/dify-data/volumes/
```

#### 2. Dify 서비스 배포
```bash
# 환경 파일 설정
cp docker/.env.example docker/.env
cp web/.env.example web/.env

# 브랜딩 설정 (mySUNI)
echo "NEXT_PUBLIC_BRAND_NAME=mySUNI" >> docker/.env
echo "NEXT_PUBLIC_BRAND_URL=https://connect.mysuni.com" >> docker/.env

# 브랜딩 이미지 준비
mkdir -p docker/volumes/branding
cp your-logo.svg docker/volumes/branding/profile.svg

# 웹 컨테이너 재시작 (브랜딩 파일 반영)
docker restart docker-web-1

# 서비스 빌드 및 실행
make build
make up
```

#### 3. 서비스 확인
```bash
# 컨테이너 상태 확인
docker ps

# 서비스 접속 테스트
curl -f http://localhost/
curl -f http://localhost/api/v1/health

# 로그 확인
docker logs docker-api-1 -f
```

### 모니터링 및 관리

#### 저장소 모니터링
```bash
# 실시간 저장소 사용량
watch -n 5 df -h /opt/dify-data

# 모니터링 로그 확인
tail -f /var/log/dify-azure/storage-monitor.log

# 수동 상태 확인
sudo /usr/local/bin/dify-storage-monitor.sh
```

#### Azure 리소스 관리
```bash
# Azure CLI로 디스크 상태 확인
az disk list --resource-group myResourceGroup --output table

# 백업 상태 확인
az backup job list --resource-group myResourceGroup --vault-name dify-backup-vault

# VM 메트릭 확인
az monitor metrics list --resource myVM --metric "Percentage CPU"
```

#### 백업 관리
```bash
# 백업 디렉토리 확인
ls -la /opt/dify-backups/

# 수동 백업 생성
sudo tar -czf /opt/dify-backups/manual-backup-$(date +%Y%m%d).tar.gz \
  -C /opt/dify-data volumes/

# 백업 복원 (필요시)
sudo tar -xzf /opt/dify-backups/dify-backup-YYYYMMDD-HHMMSS.tar.gz \
  -C /opt/dify-data/
```

### 트러블슈팅

#### 일반적인 문제

**1. 디스크가 감지되지 않는 경우**
```bash
# 연결된 디스크 확인
lsblk
sudo fdisk -l

# Azure CLI로 디스크 상태 확인
az vm show --resource-group myResourceGroup --name myVM \
  --query "storageProfile.dataDisks"
```

**2. 마운트 실패**
```bash
# 파일시스템 체크
sudo fsck -f /dev/sdc1

# 수동 마운트 시도
sudo mount -t ext4 /dev/sdc1 /opt/dify-data

# fstab 구문 검사
sudo mount -a
```

**3. Docker 볼륨 문제**
```bash
# 볼륨 심볼릭 링크 확인
ls -la /var/lib/docker/volumes/

# 권한 문제 해결
sudo chown -R 1001:0 /opt/dify-data/volumes/
sudo chmod -R g+rwX /opt/dify-data/volumes/
```

**4. Azure CLI 인증 문제**
```bash
# 관리 ID로 로그인
az login --identity

# 수동 로그인
az login

# 계정 상태 확인
az account show
```

#### 롤백 절차

문제 발생 시 자동 생성된 롤백 스크립트를 사용할 수 있습니다:

```bash
# 롤백 스크립트 실행
sudo /usr/local/bin/dify-storage-rollback.sh

# 또는 스크립트 옵션으로 롤백
sudo ./scripts/azure-storage-setup.sh --rollback
```

#### 완전 재설정

```bash
# 1. 서비스 중지
make down

# 2. 롤백 실행
sudo /usr/local/bin/dify-storage-rollback.sh

# 3. 마운트 포인트 정리
sudo umount /opt/dify-data || true
sudo rm -rf /opt/dify-data

# 4. fstab 정리
sudo sed -i '/dify-data/d' /etc/fstab

# 5. 처음부터 재시작
sudo ./scripts/azure-storage-setup.sh
```

### 성능 최적화

#### Azure VM 최적화
```bash
# VM 크기 업그레이드 (필요시)
az vm resize --resource-group myResourceGroup --name myVM --size Standard_D8s_v3

# Premium SSD 사용 권장
az disk update --resource-group myResourceGroup --name dify-storage-disk --sku Premium_LRS

# 가속화된 네트워킹 활성화
az vm update --resource-group myResourceGroup --name myVM --set networkProfile.networkInterfaces[0].enableAcceleratedNetworking=true
```

#### 저장소 최적화
```bash
# I/O 스케줄러 최적화
echo noop | sudo tee /sys/block/sdc/queue/scheduler

# 파일시스템 최적화
sudo tune2fs -o journal_data_writeback /dev/sdc1
```

### 비용 최적화

#### Azure 리소스 관리
- **예약 인스턴스**: 장기 사용 시 예약 인스턴스 구매 고려
- **자동 종료**: 개발 환경에서는 자동 종료 스케줄 설정
- **스토리지 계층**: 콜드 데이터는 Cool/Archive 스토리지로 이동
- **모니터링**: Azure Cost Management로 비용 추적

```bash
# VM 자동 종료 설정
az vm auto-shutdown --resource-group myResourceGroup --name myVM --time 1900

# 비용 알림 설정
az monitor action-group create --resource-group myResourceGroup --name cost-alerts
```

## 외부 초대 API

### 개요

외부 시스템에서 편집자(Editor) 권한으로 사용자를 초대할 수 있는 RESTful API입니다.
Single tenant 환경에서 사용하도록 설계되었으며, API 키 인증을 통해 보안을 제공합니다.

### 설정 방법

#### 1. 환경 변수 설정

`.env` 파일에 다음 환경 변수를 설정하세요:

```bash
# 외부 초대 API 활성화
EXTERNAL_INVITATION_ENABLED=true

# API 인증 키 설정 (안전한 랜덤 문자열 사용)
# 생성 방법: openssl rand -hex 32
EXTERNAL_INVITATION_API_KEY=your-secure-api-key-here
```

#### 2. 서비스 재시작

환경 변수 설정 후 서비스를 재시작합니다:

```bash
# Docker 사용 시
make down
make up

# 또는 개별 컨테이너만 재시작
docker restart docker-api-1
```

### API 사용법

#### 엔드포인트

```
POST /api/v1/external/invite-editor
```

#### 요청 헤더

| 헤더 | 설명 | 필수 |
|------|------|------|
| `X-API-Key` | 환경 변수에 설정한 API 키 | ✅ |
| `Content-Type` | `application/json` | ✅ |

#### 요청 본문

```json
{
  "emails": ["user1@example.com", "user2@example.com"],
  "language": "ko-KR"  // 선택사항, 기본값: "en-US"
}
```

#### 응답 예시

**성공 시:**
```json
{
  "success": true,
  "invitation_results": [
    {
      "email": "user1@example.com",
      "status": "success",
      "invitation_url": "https://your-domain/activate?email=user1@example.com&token=..."
    },
    {
      "email": "user2@example.com",
      "status": "already_member",
      "message": "User is already a workspace member"
    }
  ]
}
```

**실패 시:**
```json
{
  "success": false,
  "error": "Invalid API key"
}
```

### 사용 예시

#### cURL

```bash
curl -X POST https://your-domain/api/v1/external/invite-editor \
  -H "X-API-Key: your-secure-api-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "emails": ["newuser@example.com"],
    "language": "ko-KR"
  }'
```

#### Python

```python
import requests

url = "https://your-domain/api/v1/external/invite-editor"
headers = {
    "X-API-Key": "your-secure-api-key-here",
    "Content-Type": "application/json"
}
data = {
    "emails": ["newuser@example.com"],
    "language": "ko-KR"
}

response = requests.post(url, json=data, headers=headers)
print(response.json())
```

#### Node.js

```javascript
const axios = require('axios');

const url = 'https://your-domain/api/v1/external/invite-editor';
const headers = {
  'X-API-Key': 'your-secure-api-key-here',
  'Content-Type': 'application/json'
};
const data = {
  emails: ['newuser@example.com'],
  language: 'ko-KR'
};

axios.post(url, data, { headers })
  .then(response => console.log(response.data))
  .catch(error => console.error(error));
```

### 주의사항

1. **API 키 보안**: API 키는 안전하게 보관하고 절대 공개 저장소에 커밋하지 마세요.
2. **Single Tenant**: 이 API는 single tenant 환경용으로 설계되어 첫 번째 워크스페이스에 자동으로 사용자를 초대합니다.
3. **권한**: 초대된 사용자는 항상 편집자(Editor) 권한을 받습니다.
4. **이메일 전송**: 초대 이메일이 정상적으로 발송되려면 이메일 설정이 올바르게 구성되어야 합니다.

### 문제 해결

#### API가 응답하지 않는 경우
1. `EXTERNAL_INVITATION_ENABLED=true` 설정 확인
2. 서비스 재시작 여부 확인
3. API 컨테이너 로그 확인: `docker logs docker-api-1`

#### 인증 실패
1. `X-API-Key` 헤더 존재 확인
2. API 키가 환경 변수의 값과 일치하는지 확인
3. 환경 변수가 올바르게 로드되었는지 확인

#### 이메일이 발송되지 않는 경우
1. SMTP 설정 확인 (`.env` 파일의 `MAIL_` 관련 설정)
2. Worker 컨테이너 상태 확인: `docker ps | grep worker`
3. Worker 로그 확인: `docker logs docker-worker-1`

## 지원

문제 발생 시:
1. [GitHub Issues](https://github.com/your-org/dify/issues) 확인
2. `docker logs` 명령으로 로그 확인
3. 커뮤니티 포럼 참고