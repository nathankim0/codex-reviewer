# Codex Reviewer

Claude Code에서 코드를 수정하면 **OpenAI Codex**가 자동으로 리뷰해주는 플러그인입니다.

## 특징

- **배치 리뷰**: 매 수정마다 호출하지 않고 N개 변경을 모아서 한번에 리뷰 (기본 5건)
- **변경분만 리뷰**: 전체 파일이 아닌 실제 변경된 코드(diff)만 전달하여 정확한 피드백
- **맥락 인식**: 누적된 변경들을 함께 보내 작업 흐름을 이해한 리뷰
- **스마트 필터링**: 주요 언어 파일만 리뷰 (ts, js, py, go, rs, java, kt, swift 등 16종)
- **LGTM 자동 통과**: 문제없으면 조용히 통과, 이슈 발견 시에만 피드백

## 설치

```bash
# 1. 마켓플레이스 추가
claude plugin marketplace add nathankim0/codex-reviewer

# 2. 플러그인 설치
claude plugin install codex-reviewer@codex-reviewer-marketplace --scope user

# 3. 초기 설정 (Codex CLI 설치 + 인증)
/codex-setup
```

## 요구사항

- **Node.js** 18+
- **jq**
- **OpenAI 계정** (Codex CLI 인증용)

## 작동 방식

```
Write/Edit 1~4  →  조용히 변경사항 누적
                        ↓
Write/Edit 5    →  🔍 Codex에 5건 일괄 리뷰 요청
                        ↓
                  ┌─────┴─────┐
                  │           │
                LGTM      이슈 발견
                  │           │
                  ↓           ↓
              조용히 통과   사용자 + Claude에게
                            피드백 전달
```

리뷰 대상:
- 치명적 버그
- 보안 취약점
- 변경 간 논리적 불일치

## 설정

### 배치 사이즈 변경

```bash
# 기본값: 5 (환경변수로 조절)
export CODEX_REVIEW_BATCH_SIZE=3
```

### 리뷰 대상 확장자

`scripts/codex-review.sh`의 `REVIEW_EXTENSIONS` 수정:

```bash
REVIEW_EXTENSIONS="ts|tsx|js|jsx|py"  # 원하는 확장자만
```

## 라이선스

MIT
