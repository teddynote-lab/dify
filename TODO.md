# Cherry-Pick 작업 TODO List

## 개요
upstream/main의 최신 코드에 teddylee777의 커스텀 개발 코드를 cherry-picking하여 baseline-v1.9.0 브랜치를 완성합니다.

## 브랜딩 설정 모듈화 (신규 요구사항)
### 환경변수 설정
- `NEXT_PUBLIC_BRAND_NAME`: 브랜드 이름 (기본값: DashFlow)
- `NEXT_PUBLIC_BRAND_URL`: 브랜드 링크 (기본값: https://dashflow.studio/)
- `NEXT_PUBLIC_LOGO_PATH`: 로고 파일 경로 (기본값: /logo/profile.png)

### 파일 구조
```
/public/
  /branding/       # 브랜딩 관련 파일 저장 위치
    logo.png       # 기본 로고
    profile.png    # 프로필 이미지
```

## Cherry-Pick 작업 순서

### Phase 1: Frontend UI 개선 (우선순위: 높음)
1. **[7f4df12f]** Frontend configuration 수정
   - ✅ 모듈화 필요: Avatar 컴포넌트 - 환경변수로 프로필 이미지 경로 설정
   - ✅ 모듈화 필요: DashFlow 네비게이션 - 환경변수로 이름과 링크 설정
   - Profile.png 파일 → /public/branding/profile.png로 이동
   - 테마 스위처, 앱 생성 모달 UI 개선
   - 체크박스 라벨, 초대 설정 페이지 스타일 개선

2. **[bcb470e0]** Explore 페이지 QuickFix
   - 앱 리스트와 앱 생성 다이얼로그 UI 개선

3. **[6107ea907]** Dropdown 메뉴 제거
   - nav-selector 컴포넌트 단순화

### Phase 2: 이메일 템플릿 (우선순위: 중간)
4. **[3fcd3278]** 이메일 초대 템플릿 개선
   - 영어/중국어 템플릿 스타일링 개선
   - ⚠️ 브랜딩 이름 하드코딩 확인 필요

### Phase 3: 개발 환경 설정 (우선순위: 높음)
5. **[31db213a]** Makefile 리팩토링
   - Docker 빌드 및 서비스 관리 개선
   - up/down 타겟 추가

6. **[1fc8f9e3]** 로컬 개발 스크립트
   - start-local-dev.sh 추가
   - 멤버 초대 모달 개선

7. **[6247fce9]** Docker 빌드/실행 스크립트
   - build-and-run.sh 추가
   - docker-compose.override.yaml 설정

### Phase 4: 기능 추가 (우선순위: 높음)
8. **[8648eadd]** Password Reset 기능
   - API: /api/console/workspaces/current/members/{member_id}/reset-password
   - Frontend: 멤버 관리 페이지에 비밀번호 재설정 모달
   - 이메일 템플릿 추가 (en-US, zh-CN)
   - 번역 추가 (en-US, ko-KR)

9. **[24c84b02]** Import 모듈 정리
   - ext_import_modules.py 리팩토링

10. **[73461cc17]** Tool 사용 권한 기능
    - API: tool_providers.py 권한 체크 로직 추가
    - Frontend: 권한 없음 모달 (PermissionDeniedModal)
    - 플러그인 설치/사용 권한 관리
    - 번역 추가 (en-US, ko-KR)

### Phase 5: 마이그레이션 스크립트 (제외 예정)
- ❌ **[54f978ba8]** Azure volume mount 스크립트 - 환경 특화적이므로 제외
- ❌ **[60f7acc9c, 9fd5589d7]** 스크립트 hotfix - 제외
- ❌ **[ec040ef6d]** Makefile 업데이트 - Phase 3에 포함됨

## 충돌 예상 지점
1. `api/extensions/ext_import_modules.py` - import 구조 변경
2. `web/app/components/header/` - 헤더 컴포넌트 구조 변경
3. `api/controllers/console/workspace/members.py` - 멤버 관리 API
4. 번역 파일들 - 키 추가 시 충돌 가능

## 테스트 항목
- [ ] Frontend 빌드 성공
- [ ] API 서버 정상 실행
- [ ] 로그인/로그아웃
- [ ] 멤버 비밀번호 재설정
- [ ] 플러그인 권한 체크
- [ ] 이메일 발송
- [ ] 브랜딩 커스터마이징 (로고, 이름, 링크)

## Makefile (make dev 명령)
```makefile
.PHONY: dev
dev:
	@echo "Starting Dify development environment..."
	@echo "1. Starting API server..."
	cd api && uv run --project . flask run --host 0.0.0.0 --port 5001 --debug &
	@echo "2. Starting worker..."
	cd api && uv run --project . celery -A app.celery worker -P gevent -Q default,critical,generation,tool,workflow,app_deletion,dataset,mail,ops_trace,retrieval,embedding -l INFO &
	@echo "3. Starting web dev server..."
	cd web && pnpm dev
```

## 환경변수 템플릿 (.env.example)
```bash
# Branding Configuration
NEXT_PUBLIC_BRAND_NAME=DashFlow
NEXT_PUBLIC_BRAND_URL=https://dashflow.studio/
NEXT_PUBLIC_LOGO_PATH=/branding/logo.png
NEXT_PUBLIC_PROFILE_PATH=/branding/profile.png
```

## 작업 완료 조건
1. 모든 커밋이 성공적으로 cherry-pick 완료
2. 충돌 해결 완료
3. 브랜딩 모듈화 구현 완료
4. 테스트 항목 모두 통과
5. make dev 명령으로 개발 환경 실행 가능