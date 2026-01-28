#!/bin/bash

# stdin에서 JSON 입력 읽기
input=$(cat)

# 파일 경로 추출
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# 파일이 없으면 종료
if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    exit 0
fi

# 리뷰할 파일 확장자 필터링
REVIEW_EXTENSIONS="ts|tsx|js|jsx|py|go|rs|java|kt|swift|rb|php|c|cpp|h|hpp|cs"

if [[ ! "$file_path" =~ \.($REVIEW_EXTENSIONS)$ ]]; then
    exit 0
fi

# codex 명령어 존재 확인
if ! command -v codex &> /dev/null; then
    exit 0
fi

# 파일 내용 읽기 (최대 300줄 - 토큰 절약)
file_content=$(head -n 300 "$file_path")

# 파일이 너무 짧으면 스킵 (10줄 미만)
line_count=$(echo "$file_content" | wc -l)
if [ "$line_count" -lt 10 ]; then
    exit 0
fi

# codex exec로 코드 리뷰 실행
review_result=$(codex exec --full-auto \
"Review this code briefly. Only report:
- Critical bugs
- Security vulnerabilities
- Performance issues

If no issues, just say 'LGTM'.

File: $file_path

\`\`\`
$file_content
\`\`\`" 2>/dev/null)

# 타임아웃이나 에러 시 종료
if [ $? -ne 0 ]; then
    exit 0
fi

# 결과가 없거나 LGTM이면 통과
if [ -z "$review_result" ] || [[ "$review_result" =~ ^[[:space:]]*LGTM[[:space:]]*$ ]] || [[ "$review_result" == *"LGTM"* && ${#review_result} -lt 50 ]]; then
    exit 0
fi

# JSON 특수문자 이스케이프
escaped_result=$(echo "$review_result" | jq -Rs . | sed 's/^"//;s/"$//')

# 리뷰 결과를 Claude에게 피드백
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "🔍 Codex Code Review:\n\n${escaped_result}\n\n위 피드백을 참고해서 필요하면 코드를 수정해주세요."
  }
}
EOF

exit 0
