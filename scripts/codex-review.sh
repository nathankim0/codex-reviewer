#!/bin/bash

# ─── 설정 ───
BATCH_SIZE="${CODEX_REVIEW_BATCH_SIZE:-5}"        # N번 변경마다 리뷰 (기본: 5)
BATCH_DIR="/tmp/codex-reviewer"
CHANGES_FILE="$BATCH_DIR/pending-changes.txt"
COUNTER_FILE="$BATCH_DIR/change-count"
REVIEW_EXTENSIONS="ts|tsx|js|jsx|py|go|rs|java|kt|swift|rb|php|c|cpp|h|hpp|cs"

mkdir -p "$BATCH_DIR"

# ─── stdin에서 JSON 입력 읽기 ───
input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# 파일이 없으면 종료
if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    exit 0
fi

# 확장자 필터링
if [[ ! "$file_path" =~ \.($REVIEW_EXTENSIONS)$ ]]; then
    exit 0
fi

# codex 명령어 존재 확인
if ! command -v codex &> /dev/null; then
    exit 0
fi

# ─── 변경 내용 추출 ───
if [ "$tool_name" = "Edit" ]; then
    old_string=$(echo "$input" | jq -r '.tool_input.old_string // empty')
    new_string=$(echo "$input" | jq -r '.tool_input.new_string // empty')
    if [ -z "$old_string" ] && [ -z "$new_string" ]; then
        exit 0
    fi
    change_entry="[Edit] $file_path
--- before
$old_string
--- after
$new_string"

elif [ "$tool_name" = "Write" ]; then
    content=$(echo "$input" | jq -r '.tool_input.content // empty')
    MAX_WRITE_LINES=200
    content=$(echo "$content" | head -n "$MAX_WRITE_LINES")
    line_count=$(echo "$content" | wc -l | tr -d ' ')
    if [ "$line_count" -lt 10 ]; then
        exit 0
    fi
    change_entry="[Write] $file_path (new file)
$content"
else
    exit 0
fi

# ─── 변경사항 누적 ───
echo "========================================" >> "$CHANGES_FILE"
echo "$change_entry" >> "$CHANGES_FILE"
echo "" >> "$CHANGES_FILE"

# 카운터 증가
count=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
count=$((count + 1))
echo "$count" > "$COUNTER_FILE"

# 배치 사이즈 미달이면 누적만 하고 종료
if [ "$count" -lt "$BATCH_SIZE" ]; then
    echo "  ℹ️ Codex Review: 변경 누적 중 ($count/$BATCH_SIZE)" >&2
    exit 0
fi

# ─── 배치 리뷰 실행 ───
all_changes=$(cat "$CHANGES_FILE")

# 리셋
echo "0" > "$COUNTER_FILE"
> "$CHANGES_FILE"

# 변경된 파일 목록 추출
changed_files=$(echo "$all_changes" | grep -E '^\[(Edit|Write)\]' | sed 's/^\[.*\] //' | sed 's/ (new file)//' | sort -u)

echo "  🔍 Codex Review 진행 중... ($BATCH_SIZE개 변경사항)" >&2

review_result=$(codex exec --full-auto \
"You are reviewing a batch of code changes made during a single coding session.
These changes are all part of the same task, so consider them together as a whole.

Review ONLY these changes. Focus on:
- Critical bugs introduced by these changes
- Security vulnerabilities in the changed code
- Logic errors across the changes (e.g., inconsistent naming, missing references)

Do NOT:
- Comment on pre-existing code style or structure
- Suggest improvements unrelated to the changes
- Repeat the code back

If no issues found, just say 'LGTM'.

Changes:
$all_changes" 2>/dev/null)

# 타임아웃이나 에러 시 종료
if [ $? -ne 0 ]; then
    exit 0
fi

# 결과가 없거나 LGTM이면 통과
if [ -z "$review_result" ] || [[ "$review_result" =~ ^[[:space:]]*LGTM[[:space:]]*$ ]] || [[ "$review_result" == *"LGTM"* && ${#review_result} -lt 50 ]]; then
    echo "  ✅ Codex Review: LGTM" >&2
    exit 0
fi

# ─── 사용자에게 리뷰 결과 표시 ───
echo "" >&2
echo "┌─ 🔍 Codex Review ($BATCH_SIZE changes)" >&2
echo "│  Files: $changed_files" >&2
echo "│" >&2
echo "$review_result" | sed 's/^/│  /' >&2
echo "│" >&2
echo "└─────────────────────────────" >&2

# ─── JSON 특수문자 이스케이프 ───
escaped_result=$(echo "$review_result" | jq -Rs . | sed 's/^"//;s/"$//')

# ─── Claude에게 피드백 ───
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "🔍 Codex Review (${BATCH_SIZE}개 변경사항 일괄 리뷰):\n${escaped_result}\n\n위 피드백은 최근 ${BATCH_SIZE}개 코드 변경에 대한 일괄 리뷰입니다. 현재 진행 중인 작업 목표와 직접 관련된 버그/이슈만 반영하세요. 기존 코드의 구조적 문제나 작업 범위 밖의 제안은 무시하세요."
  }
}
EOF

exit 0
