# Codex Reviewer Plugin - 개발 규칙

## 프로젝트 개요

- Claude Code용 플러그인: OpenAI Codex로 자동 코드 리뷰
- 저장소: https://github.com/nathankim0/codex-reviewer

## 배포 워크플로우

코드 수정 후 반드시 아래 순서를 실행한다:

```bash
# 1. 버전 bump (patch)
./scripts/bump-version.sh

# 2. 커밋 & 푸시 (= 마켓플레이스 배포)
git add -A && git commit -m "커밋메시지" && git push origin main

# 3. GitHub 태그 & 릴리스 (plugin.json 버전과 일치)
git tag v$(jq -r '.version' .claude-plugin/plugin.json)
git push origin v$(jq -r '.version' .claude-plugin/plugin.json)
gh release create v$(jq -r '.version' .claude-plugin/plugin.json) --title "v$(jq -r '.version' .claude-plugin/plugin.json)" --notes "변경사항 요약" --latest

# 4. 플러그인 업데이트 (user scope)
claude plugin marketplace update codex-reviewer-marketplace
claude plugin uninstall codex-reviewer@codex-reviewer-marketplace --scope user && claude plugin install codex-reviewer@codex-reviewer-marketplace --scope user
```

매 수정마다 이 4단계를 빠짐없이 수행할 것.
- plugin.json 버전 = marketplace.json 버전 = git tag = GitHub release 모두 일치시킨다.

## 프로젝트 구조

```
scripts/codex-review.sh    # 핵심 리뷰 로직 (PostToolUse Hook)
scripts/bump-version.sh    # 버전 자동 bump (patch)
scripts/setup.sh           # 초기 설정 스크립트
hooks/hooks.json           # Hook 설정
.claude-plugin/plugin.json      # 플러그인 메타데이터 (버전 관리)
.claude-plugin/marketplace.json # 마켓플레이스 설정 (버전 동기화)
commands/codex-setup.md    # setup 커맨드 설명
```

## 코딩 규칙

- 쉘 스크립트는 POSIX 호환 + bash 확장 사용
- 설정값은 상단에 상수로 선언 (매직넘버 금지)
- 에러 시 조용히 종료 (exit 0) - 사용자 작업 흐름을 방해하지 않음
- 리뷰 결과는 stderr로 사용자에게 표시, stdout JSON으로 Claude에게 전달
