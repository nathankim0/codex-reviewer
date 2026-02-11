# Codex Reviewer Plugin - 개발 규칙

## 프로젝트 개요

- Claude Code용 플러그인: OpenAI Codex로 자동 코드 리뷰
- 저장소: https://github.com/nathankim0/codex-reviewer

## 배포 워크플로우

코드 수정 후 반드시 아래 순서를 실행한다:

1. **커밋**: conventional commit (한국어 메시지)
2. **푸시**: `git push origin main`
3. **마켓플레이스 업데이트**: `claude plugin marketplace update codex-reviewer-marketplace`
4. **플러그인 재설치**:
   ```bash
   cd /Users/nathan/algocare-home/mobile && claude plugin uninstall codex-reviewer@codex-reviewer-marketplace --scope local && claude plugin install codex-reviewer@codex-reviewer-marketplace --scope local
   ```

매 수정마다 이 4단계를 빠짐없이 수행할 것.

## 프로젝트 구조

```
scripts/codex-review.sh   # 핵심 리뷰 로직 (PostToolUse Hook)
scripts/setup.sh          # 초기 설정 스크립트
hooks/hooks.json          # Hook 설정
.claude-plugin/plugin.json      # 플러그인 메타데이터
.claude-plugin/marketplace.json # 마켓플레이스 설정
commands/codex-setup.md   # setup 커맨드 설명
```

## 코딩 규칙

- 쉘 스크립트는 POSIX 호환 + bash 확장 사용
- 설정값은 상단에 상수로 선언 (매직넘버 금지)
- 에러 시 조용히 종료 (exit 0) - 사용자 작업 흐름을 방해하지 않음
- 리뷰 결과는 stderr로 사용자에게 표시, stdout JSON으로 Claude에게 전달
