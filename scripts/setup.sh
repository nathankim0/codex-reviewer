#!/bin/bash

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🔧 Codex Reviewer 플러그인 설정${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# jq 설치 확인 (JSON 파싱용)
check_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠️  jq가 설치되어 있지 않습니다.${NC}"
        echo ""

        # OS 감지
        if [[ "$OSTYPE" == "darwin"* ]]; then
            read -p "Homebrew로 jq를 설치하시겠습니까? (y/n): " install_jq
            if [[ "$install_jq" =~ ^[Yy]$ ]]; then
                echo "📦 jq 설치 중..."
                brew install jq
                echo -e "${GREEN}✅ jq 설치 완료${NC}"
            else
                echo -e "${RED}❌ jq 없이는 플러그인을 사용할 수 없습니다.${NC}"
                exit 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "다음 명령어로 jq를 설치하세요:"
            echo "  sudo apt-get install jq  (Debian/Ubuntu)"
            echo "  sudo yum install jq      (CentOS/RHEL)"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ jq 설치됨${NC}"
    fi
}

# Codex CLI 설치 확인
check_codex_installed() {
    if ! command -v codex &> /dev/null; then
        echo -e "${YELLOW}⚠️  Codex CLI가 설치되어 있지 않습니다.${NC}"
        echo ""
        read -p "Codex CLI를 설치하시겠습니까? (y/n): " install_codex
        if [[ "$install_codex" =~ ^[Yy]$ ]]; then
            echo "📦 Codex CLI 설치 중..."
            npm install -g @openai/codex
            echo -e "${GREEN}✅ Codex CLI 설치 완료${NC}"
        else
            echo -e "${RED}❌ Codex CLI 없이는 플러그인을 사용할 수 없습니다.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ Codex CLI 설치됨$(codex --version 2>/dev/null | head -1 || echo '')${NC}"
    fi
}

# Codex 로그인 확인
check_codex_auth() {
    echo ""
    echo "🔐 Codex 인증 상태 확인 중..."

    # OPENAI_API_KEY 환경변수 확인
    if [ -n "$OPENAI_API_KEY" ]; then
        echo -e "${GREEN}✅ OPENAI_API_KEY 환경변수 설정됨${NC}"
        return 0
    fi

    # codex auth 상태 확인
    if codex auth status &> /dev/null; then
        echo -e "${GREEN}✅ Codex 인증됨${NC}"
        return 0
    fi

    echo -e "${YELLOW}⚠️  Codex 인증이 필요합니다.${NC}"
    echo ""
    echo "인증 방법을 선택하세요:"
    echo "  1) OAuth 로그인 (브라우저)"
    echo "  2) API 키 직접 입력"
    echo "  3) 나중에 하기"
    echo ""
    read -p "선택 (1/2/3): " auth_choice

    case $auth_choice in
        1)
            echo ""
            echo "🌐 브라우저에서 OAuth 로그인을 진행합니다..."
            codex login
            echo -e "${GREEN}✅ Codex 로그인 완료${NC}"
            ;;
        2)
            echo ""
            read -sp "OpenAI API 키를 입력하세요: " api_key
            echo ""
            if [ -n "$api_key" ]; then
                codex login --api-key "$api_key"
                echo -e "${GREEN}✅ API 키 설정 완료${NC}"
            else
                echo -e "${YELLOW}⚠️  API 키가 입력되지 않았습니다.${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}⚠️  나중에 'codex login'으로 로그인하세요.${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️  잘못된 선택입니다. 나중에 'codex login'으로 로그인하세요.${NC}"
            ;;
    esac
}

# 메인 실행
check_jq_installed
check_codex_installed
check_codex_auth

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  🎉 설정 완료!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "이제 Claude Code에서 파일을 수정하면"
echo "Codex가 자동으로 코드 리뷰를 합니다."
echo ""

exit 0
