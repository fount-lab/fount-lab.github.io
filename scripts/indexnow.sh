#!/bin/bash
# 바뀐 주소를 IndexNow에 알린다. 빙·네이버·얀덱스가 함께 받는다(구글은 미참여).
#
#   ./scripts/indexnow.sh                    사이트맵의 전 주소를 알림
#   ./scripts/indexnow.sh /balpum/ /itne/    특정 주소만
#
# 키는 https://fountlab.co.kr/91a0b87616eb9610ec601a592571d1fe.txt 로 서비스되어야 한다.
# 그 파일이 404면 IndexNow는 요청을 통째로 무시한다.

set -euo pipefail
HOST="fountlab.co.kr"
KEY="91a0b87616eb9610ec601a592571d1fe"

if [ $# -gt 0 ]; then
    URLS=()
    for p in "$@"; do URLS+=("https://$HOST${p}"); done
else
    URLS=("https://fountlab.co.kr/"
        "https://fountlab.co.kr/balpum/"
        "https://fountlab.co.kr/balpum/en/"
        "https://fountlab.co.kr/balpum/privacy/"
        "https://fountlab.co.kr/balpum/privacy/en/"
        "https://fountlab.co.kr/itne/"
        "https://fountlab.co.kr/itne/en/"
        "https://fountlab.co.kr/itne/privacy/")
fi

LIST=$(printf '%s\n' "${URLS[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))")
BODY=$(printf '{"host":"%s","key":"%s","keyLocation":"https://%s/%s.txt","urlList":%s}' \
       "$HOST" "$KEY" "$HOST" "$KEY" "$LIST")

CODE=$(curl -s -o /tmp/indexnow.out -w "%{http_code}" \
       -H "Content-Type: application/json; charset=utf-8" \
       -d "$BODY" https://api.indexnow.org/IndexNow)

case "$CODE" in
    200|202) echo "알렸다 ($CODE) — ${#URLS[@]}개 주소" ;;
    403) echo "키 파일을 못 찾았다. https://$HOST/$KEY.txt 가 열리는지 확인." >&2; exit 1 ;;
    *)   echo "실패 ($CODE)" >&2; cat /tmp/indexnow.out >&2; echo >&2; exit 1 ;;
esac
