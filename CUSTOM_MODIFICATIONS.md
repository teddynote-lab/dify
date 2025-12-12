# 커스텀 수정 파일 목록

baseline-v1.9.0-fix에서 baseline-v1.11.0으로 마이그레이션할 때 적용해야 할 커스텀 수정사항입니다.

## 1. 외부 초대 API (External Invitation)

**새로 생성된 파일들:**
- `api/configs/extra/__init__.py`
- `api/configs/extra/external_invitation_config.py`
- `api/controllers/external/__init__.py`
- `api/controllers/external/invitation.py`
- `api/controllers/external/wraps.py`

**수정된 파일들:**
- `api/.env.example` - 외부 초대 관련 환경변수 추가
- `api/extensions/ext_blueprints.py` - 외부 API 블루프린트 등록

---

## 2. 비밀번호 강제 리셋 기능

**새로 생성된 파일들:**
- `api/tasks/mail_force_password_reset_task.py`
- `api/templates/force_password_reset_member_mail_template_en-US.html`
- `api/templates/force_password_reset_member_mail_template_zh-CN.html`

**수정된 파일들:**
- `api/controllers/console/workspace/members.py` - 비밀번호 리셋 API 추가
- `api/extensions/ext_import_modules.py` - task 모듈 임포트 추가
- `api/libs/email_i18n.py` - 이메일 템플릿 i18n 지원

**프론트엔드:**
- `web/app/components/header/account-setting/members-page/operation/index.tsx`
- `web/i18n/en-US/common.ts`
- `web/i18n/ko-KR/common.ts`
- `web/service/common.ts`

---

## 3. Tool 사용 권한 기능 (Plugin Permission)

**수정된 파일들:**
- `api/controllers/console/workspace/__init__.py`
- `api/controllers/console/workspace/tool_providers.py`

**새로 생성된 파일들:**
- `web/app/components/plugins/marketplace/permission-denied-modal.tsx`

**수정된 파일들:**
- `web/app/components/plugins/install-plugin/install-from-marketplace/steps/install.tsx`
- `web/app/components/plugins/marketplace/list/card-wrapper.tsx`
- `web/app/components/plugins/plugin-page/index.tsx`
- `web/app/components/plugins/provider-card.tsx`
- `web/i18n/en-US/plugin.ts`
- `web/i18n/ko-KR/plugin.ts`
- `web/service/use-plugins.ts`

---

## 4. 브랜딩 & UI 커스터마이징

**수정된 파일들:**
- `web/app/components/header/index.tsx` - DashFlow 탭/네비게이션 수정
- `web/app/components/header/dashflow-nav/index.tsx`
- `web/app/components/header/nav/nav-selector/index.tsx`
- `web/app/components/header/account-dropdown/workplace-selector/index.tsx`
- `web/app/components/explore/sidebar/index.tsx`
- `web/app/components/apps/list.tsx`
- `web/app/components/base/avatar/index.tsx`
- `web/app/components/datasets/create/website/base/checkbox-with-label.tsx`

**브랜딩 이미지:**
- `web/public/branding/profile.png`
- `web/public/branding/profile.svg`
- `docker/volumes/branding/profile.png`
- `docker/volumes/branding/profile.svg`

**i18n:**
- `web/context/i18n.ts`
- `web/i18n-config/index.ts`

---

## 5. 이메일 초대 템플릿 커스터마이징

**수정된 파일들:**
- `api/templates/invite_member_mail_template_en-US.html`
- `api/templates/invite_member_mail_template_zh-CN.html`

---

## 6. Docker & 개발환경 설정

**새로 생성된 파일들:**
- `Makefile`
- `docker/Makefile`
- `docker/docker-compose.override.yaml.template`
- `docker/nginx/conf.d/default-local-dev.conf`
- `docker/README-BRANDING.md`
- `scripts/update-branding.sh`
- `scripts/azure-storage-setup.sh`

**수정된 파일들:**
- `docker/.env.example` - 브랜딩 환경변수 추가
- `docker/docker-compose.yaml` - 브랜딩 볼륨 마운트
- `docker/docker-compose.override.yaml`
- `web/.env.example`
- `web/Dockerfile`

**Docker volumes 설정파일들:**
- `docker/volumes/branding/*`
- `docker/volumes/myscale/config/users.d/custom_users_config.xml`
- `docker/volumes/oceanbase/init.d/vec_memory.sql`
- `docker/volumes/opensearch/opensearch_dashboards.yml`
- `docker/volumes/sandbox/conf/config.yaml`
- `docker/volumes/sandbox/dependencies/python-requirements.txt`

---

## 7. 기타 수정

**API 수정:**
- `api/controllers/console/app/app.py` - 앱 관련 수정
- `api/core/tools/utils/dataset_retriever/dataset_multi_retriever_tool.py`

**프로젝트 설정:**
- `.gitignore`
- `api/pytest.ini`
- `MANUAL.md`

---

## 마이그레이션 체크리스트

### 1단계: 새 브랜치 생성
```bash
git checkout origin/baseline-v1.11.0
git checkout -b baseline-v1.11.0-custom
```

### 2단계: 새로 생성된 파일 복사 (충돌 없음)
```bash
# External invitation
git checkout baseline-v1.9.0-fix -- api/configs/extra/
git checkout baseline-v1.9.0-fix -- api/controllers/external/

# Password reset
git checkout baseline-v1.9.0-fix -- api/tasks/mail_force_password_reset_task.py
git checkout baseline-v1.9.0-fix -- api/templates/force_password_reset_member_mail_template_en-US.html
git checkout baseline-v1.9.0-fix -- api/templates/force_password_reset_member_mail_template_zh-CN.html

# Plugin permission modal
git checkout baseline-v1.9.0-fix -- web/app/components/plugins/marketplace/permission-denied-modal.tsx

# Branding
git checkout baseline-v1.9.0-fix -- web/public/branding/
git checkout baseline-v1.9.0-fix -- docker/volumes/branding/

# Scripts & configs
git checkout baseline-v1.9.0-fix -- Makefile
git checkout baseline-v1.9.0-fix -- docker/Makefile
git checkout baseline-v1.9.0-fix -- docker/docker-compose.override.yaml.template
git checkout baseline-v1.9.0-fix -- docker/nginx/conf.d/default-local-dev.conf
git checkout baseline-v1.9.0-fix -- docker/README-BRANDING.md
git checkout baseline-v1.9.0-fix -- scripts/
```

### 3단계: 수정된 파일 (수동 머지 필요)

1.9.0 → 1.11.0 사이 변경량 기준 충돌 난이도:

| 파일 | 난이도 | 변경량 | 설명 |
|------|--------|--------|------|
| `api/controllers/console/workspace/members.py` | 🔴 높음 | 328줄 | Pydantic 모델 추가 등 대폭 리팩토링됨 |
| `api/extensions/ext_blueprints.py` | 🟡 중간 | 78줄 | CORS 헤더 상수화, trigger_bp 추가 |
| `web/app/components/header/index.tsx` | 🟡 중간 | 75줄 | 브랜딩 로직 리팩토링 |
| `web/app/components/plugins/plugin-page/index.tsx` | 🟢 낮음 | 42줄 | 소규모 변경 |

**수동 머지가 필요한 파일들:**

```bash
# 🔴 고난이도 - 꼼꼼히 확인 필요
api/controllers/console/workspace/members.py  # 비밀번호 리셋 API 추가

# 🟡 중간 난이도
api/extensions/ext_blueprints.py  # external_bp 등록 추가
web/app/components/header/index.tsx  # DashFlow 네비게이션

# 🟢 저난이도 - 추가만 하면 됨
api/extensions/ext_import_modules.py  # task 임포트 추가
api/controllers/console/workspace/__init__.py  # 라우트 추가
api/controllers/console/workspace/tool_providers.py  # 권한 체크 추가
api/libs/email_i18n.py  # 이메일 템플릿 타입 추가
api/.env.example  # 환경변수 추가

# 프론트엔드 (대부분 🟢 저난이도)
web/app/components/plugins/plugin-page/index.tsx
web/app/components/plugins/provider-card.tsx
web/i18n/en-US/plugin.ts
web/i18n/ko-KR/plugin.ts
web/service/use-plugins.ts
web/service/common.ts

# Docker
docker/.env.example
docker/docker-compose.yaml
```

### 4단계: 테스트
```bash
# 빌드 테스트
cd web && pnpm install && pnpm build

# API 테스트
uv run --project api pytest
```
