# 🔍 Codex Reviewer Plugin

Claude Code에서 파일을 수정할 때 **OpenAI Codex**가 자동으로 코드 리뷰를 해주는 플러그인입니다.

## ✨ 기능

- **자동 코드 리뷰**: Write/Edit 도구 사용 후 자동으로 Codex가 코드 리뷰
- **스마트 필터링**: 주요 프로그래밍 언어 파일만 리뷰 (ts, tsx, js, jsx, py, go, rs, java, kt, swift 등)
- **간결한 피드백**: 심각한 버그, 보안 이슈, 성능 문제만 보고
- **LGTM 자동 통과**: 문제없는 코드는 조용히 통과
- **대화형 설정**: OAuth 로그인 또는 API 키 설정을 대화형으로 지원

## 📦 설치

### 1. 마켓플레이스 추가

Claude Code에서:

```
/plugin marketplace add nathankim0/codex-reviewer
```

### 2. 플러그인 설치

```
/plugin install codex-reviewer@codex-reviewer-marketplace
```

### 3. 초기 설정

```bash
claude --init
```

또는 Claude Code 내에서:

```
/codex-setup
```

## 🔧 수동 설정

초기 설정 없이 수동으로 설정하려면:

```bash
# Codex CLI 설치
npm install -g @openai/codex

# Codex 로그인 (OAuth)
codex login

# 또는 API 키로 로그인
codex login --api-key YOUR_API_KEY
```

## 📋 요구사항

- **Node.js** 18+
- **jq** (JSON 파싱용)
- **OpenAI 계정** (Codex API 사용)

## 🎯 작동 방식

```
Claude Code에서 파일 수정 (Write/Edit)
         ↓
    PostToolUse Hook 실행
         ↓
    codex exec로 코드 리뷰
         ↓
  ┌──────┴──────┐
  │             │
LGTM        이슈 발견
  │             │
  ↓             ↓
조용히 통과   Claude에게 피드백
              (자동 수정 제안)
```

## ⚙️ 설정 커스터마이징

### 리뷰할 파일 확장자 변경

`scripts/codex-review.sh`의 `REVIEW_EXTENSIONS` 변수 수정:

```bash
REVIEW_EXTENSIONS="ts|tsx|js|jsx|py"  # 원하는 확장자만
```

### 리뷰 프롬프트 변경

`scripts/codex-review.sh`의 codex exec 프롬프트 수정

## 🤝 기여

이슈나 PR 환영합니다!

## 📄 라이선스

MIT License
