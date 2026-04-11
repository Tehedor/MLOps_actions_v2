#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTTP_FILE_DEFAULT="${SCRIPT_DIR}/60_deploy-api.http"
HTTP_FILE="${HTTP_FILE:-${1:-$HTTP_FILE_DEFAULT}}"

if [[ ! -f "$HTTP_FILE" ]]; then
	echo "[ERROR] No existe el archivo HTTP: $HTTP_FILE" >&2
	exit 1
fi

declare -A PHASE_WAIT_MINUTES=(
	[1]=3
	[2]=3
	[3]=2
	[4]=2
	[5]=7
	[6]=7
	[7]=40
	[8]=40
)

TOKEN=""
TOKEN_ENV="${GITHUB_TOKEN:-}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

dispatch_request() {
	local phase_num="$1"
	local request_url="$2"
	local body_file="$3"

	local phase_wait_min="${PHASE_WAIT_MINUTES[$phase_num]:-0}"
	local response_file="${TMP_DIR}/response_${phase_num}.txt"
	local normalized_body_file="${TMP_DIR}/normalized_body_${phase_num}.json"
	local http_code=""
	local auth_token="${TOKEN_ENV:-$TOKEN}"

	if [[ -z "$auth_token" ]]; then
		echo "[ERROR] No se encontró TOKEN_FINE_GRAINED_AQUI en el archivo ni GITHUB_TOKEN en el entorno." >&2
		return 1
	fi

	python3 - "$body_file" "$normalized_body_file" <<'PY'
from pathlib import Path
import re
import sys

source = Path(sys.argv[1]).read_text(encoding='utf-8')
source = re.sub(r',([\s]*[}\]])', r'\1', source)
Path(sys.argv[2]).write_text(source, encoding='utf-8')
PY

	echo "[INFO] Ejecutando Fase ${phase_num}"
	http_code="$(curl -sS --fail-with-body \
		-o "$response_file" \
		-w '%{http_code}' \
		-X POST "$request_url" \
		-H 'Accept: application/vnd.github.v3+json' \
		-H "Authorization: Bearer ${auth_token}" \
		-H 'X-GitHub-Api-Version: 2022-11-28' \
		-H 'Content-Type: application/json' \
		--data-binary "@$normalized_body_file" \
		|| true)"

	if [[ ! "$http_code" =~ ^2[0-9][0-9]$ ]]; then
		echo "[ERROR] Fase ${phase_num} falló con HTTP ${http_code:-sin_codigo}" >&2
		if [[ -s "$response_file" ]]; then
			cat "$response_file" >&2
		fi
		return 1
	fi

	echo "[OK] Fase ${phase_num} respondio HTTP ${http_code}"
	return 0
}

phase_num=""
request_url=""
body_file=""
reading_body=0
body_depth=0
sleep_before_next=0

while IFS= read -r line || [[ -n "$line" ]]; do
	if [[ "$line" =~ ^@TOKEN_FINE_GRAINED_AQUI[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		TOKEN="${BASH_REMATCH[1]}"
		continue
	fi

	if [[ "$line" =~ ^###[[:space:]]*Fase[[:space:]]+([0-9]+) ]]; then
		if (( sleep_before_next > 0 )); then
			echo "[INFO] Esperando ${sleep_before_next} minutos antes de la siguiente fase..."
			sleep "$((sleep_before_next * 60))"
			sleep_before_next=0
		fi

		phase_num="${BASH_REMATCH[1]}"
		request_url=""
		body_file=""
		reading_body=0
		body_depth=0
		continue
	fi

	if [[ "$line" =~ ^POST[[:space:]]+(https?://[^[:space:]]+) ]]; then
		request_url="${BASH_REMATCH[1]}"
		body_file="${TMP_DIR}/body_${phase_num}.json"
		: > "$body_file"
		reading_body=0
		body_depth=0
		continue
	fi

	if [[ -z "$request_url" ]]; then
		continue
	fi

	if [[ "$line" =~ ^\{ ]]; then
		reading_body=1
	fi

	if (( reading_body == 1 )); then
		printf '%s\n' "$line" >> "$body_file"
		open_count="$(printf '%s' "$line" | tr -cd '{' | wc -c | tr -d ' ')"
		close_count="$(printf '%s' "$line" | tr -cd '}' | wc -c | tr -d ' ')"
		body_depth=$((body_depth + open_count - close_count))

		if (( body_depth == 0 )); then
			if [[ -v PHASE_WAIT_MINUTES[$phase_num] ]]; then
				dispatch_request "$phase_num" "$request_url" "$body_file"
				sleep_before_next="${PHASE_WAIT_MINUTES[$phase_num]}"
			else
				echo "[INFO] Fase ${phase_num} desactivada (sin timer en PHASE_WAIT_MINUTES), se omite."
				sleep_before_next=0
			fi
			request_url=""
			body_file=""
			reading_body=0
			body_depth=0
		fi
	fi
done < "$HTTP_FILE"

echo "[OK] Proceso completado"
