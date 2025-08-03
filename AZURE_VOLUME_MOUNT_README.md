# Azure VM Dify Storage Mount Script

## 개요
이 스크립트는 Azure VM에서 추가 디스크를 자동으로 마운트하고 Dify Docker 볼륨을 마이그레이션합니다.

## 파일 설명
- `azure_volume_mount_final.sh` - 최종 검증된 버전 (권장)
- `azure_volume_mount.sh` - 초기 대화형 버전
- `azure_volume_mount_auto.sh` - 자동화 버전 (구버전)

## 사용 방법

### 1. 기본 실행 (대화형)
```bash
sudo ./azure_volume_mount_final.sh
```

### 2. 자동 실행 (확인 없이)
```bash
sudo ./azure_volume_mount_final.sh --yes
```

## 스크립트 동작 과정

1. **디스크 자동 감지**
   - 1TB 크기의 마운트되지 않은 디스크를 자동으로 찾습니다
   - Azure에서 추가한 1TB 디스크가 /dev/sda로 인식됩니다

2. **디스크 준비**
   - GPT 파티션 테이블 생성
   - 전체 디스크를 하나의 파티션으로 생성
   - ext4 파일시스템으로 포맷

3. **마운트**
   - /mnt/dify-storage에 마운트
   - /etc/fstab에 영구 마운트 설정 추가

4. **Docker 서비스 중지**
   - docker compose down 실행

5. **볼륨 백업**
   - 기존 볼륨을 /tmp/dify-backup-YYYYMMDD-HHMMSS에 백업

6. **볼륨 마이그레이션**
   - 볼륨을 새 디스크로 복사
   - 기존 디렉토리를 .old로 이름 변경
   - 심볼릭 링크 생성

7. **서비스 재시작**
   - docker compose up -d 실행
   - 서비스 상태 확인

## 검증 방법

### 1. 디스크 공간 확인
```bash
df -h /mnt/dify-storage
```

### 2. 심볼릭 링크 확인
```bash
ls -la /home/azureuser/dify/docker/volumes
```

### 3. Docker 서비스 상태 확인
```bash
docker ps
```

### 4. 파일 업로드 테스트
Dify 웹 인터페이스에서 파일을 업로드하고 다음 경로에서 확인:
```bash
ls -la /mnt/dify-storage/docker-volumes/app/storage/upload_files/
```

## 백업 정리

모든 것이 정상 작동하는 것을 확인한 후:

```bash
# 백업 삭제
sudo rm -rf /tmp/dify-backup-*

# 이전 볼륨 디렉토리 삭제
sudo rm -rf /home/azureuser/dify/docker/volumes.old
```

## 롤백 방법

문제가 발생한 경우 스크립트가 자동으로 롤백을 시도합니다.
수동 롤백이 필요한 경우:

```bash
# 심볼릭 링크 제거
sudo rm /home/azureuser/dify/docker/volumes

# 이전 디렉토리 복원
sudo mv /home/azureuser/dify/docker/volumes.old /home/azureuser/dify/docker/volumes

# Docker 서비스 재시작
cd /home/azureuser/dify/docker
sudo docker compose up -d
```

## 다른 VM에서 사용하기

1. 스크립트를 새 VM에 복사
2. Dify가 /home/azureuser/dify에 설치되어 있는지 확인
3. 1TB 추가 디스크가 연결되어 있는지 확인
4. 스크립트 실행

## 주의사항

- 스크립트 실행 중 Dify 서비스가 약 2-5분간 중단됩니다
- 백업이 자동 생성되므로 디스크 공간이 충분한지 확인하세요
- root 권한(sudo)이 필요합니다

## 문제 해결

### 디스크를 찾을 수 없는 경우
```bash
# 사용 가능한 디스크 확인
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
```

### Docker 서비스가 시작되지 않는 경우
```bash
# 로그 확인
docker compose logs

# 개별 서비스 상태 확인
docker ps -a
```

## 테스트 환경
- Azure Ubuntu 22.04 VM
- Dify 1.7.1
- Docker Compose v2