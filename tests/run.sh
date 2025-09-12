#!/usr/bin/env bash
set -euo pipefail

failures=0

run_test() {
  local name=$1
  shift
  echo "[TEST] ${name}"
  if "$@"; then
    echo "[PASS] ${name}"
  else
    echo "[FAIL] ${name}"
    failures=$((failures+1))
  fi
}

mktemp_dir() {
  mktemp -d 2>/dev/null || mktemp -d -t 'tbapi-tests'
}

# Prepare a temp sandbox with a mock telegram-bot-api binary next to entrypoint
setup_sandbox() {
  local dir
  dir=$(mktemp_dir)
  mkdir -p "$dir"
  cp "$(pwd)/entrypoint.sh" "$dir/entrypoint.sh"
  chmod +x "$dir/entrypoint.sh"

  # Create mock binary that prints version and echoes args
  cat > "$dir/telegram-bot-api" <<'EOF'
#!/usr/bin/env sh
if [ "$1" = "--version" ]; then
  echo "Telegram Bot API Server mock 9.2"
  exit 0
fi
echo "MOCK telegram-bot-api invoked with args: $@"
exit 0
EOF
  chmod +x "$dir/telegram-bot-api"

  echo "$dir"
}

test_missing_api_id() {
  local dir
  dir=$(setup_sandbox)
  # No TELEGRAM_API_ID
  if output=$(cd "$dir" && env -u TELEGRAM_API_ID -u TELEGRAM_API_HASH ./entrypoint.sh 2>&1); then
    echo "Expected failure when TELEGRAM_API_ID is missing"
    echo "$output"
    return 1
  else
    echo "$output" | grep -q "Error: TELEGRAM_API_ID is not set"
  fi
}

test_missing_api_hash() {
  local dir
  dir=$(setup_sandbox)
  # TELEGRAM_API_ID set, TELEGRAM_API_HASH missing
  if output=$(cd "$dir" && env -u TELEGRAM_API_HASH TELEGRAM_API_ID=123 ./entrypoint.sh 2>&1); then
    echo "Expected failure when TELEGRAM_API_HASH is missing"
    echo "$output"
    return 1
  else
    echo "$output" | grep -q "Error: TELEGRAM_API_HASH is not set"
  fi
}

test_builds_expected_args_defaults() {
  local dir
  dir=$(setup_sandbox)
  # Provide required envs; expect default ports and dirs
  output=$(cd "$dir" && TELEGRAM_API_ID=1 TELEGRAM_API_HASH=abc ./entrypoint.sh 2>&1)
  echo "$output" | grep -F -q "Starting telegram-bot-api (Telegram Bot API Server mock 9.2) with args:  --http-port 8081 --http-stat-port 8082 --dir /data --temp-dir /tmp --log /data/logs/telegram-bot-api.log"
  echo "$output" | grep -F -q "MOCK telegram-bot-api invoked with args: --http-port 8081 --http-stat-port 8082 --dir /data --temp-dir /tmp --log /data/logs/telegram-bot-api.log"
}

test_custom_args_and_local() {
  local dir
  dir=$(setup_sandbox)
  output=$(cd "$dir" \
    && TELEGRAM_API_ID=1 TELEGRAM_API_HASH=abc \
       TELEGRAM_HTTP_PORT=9000 TELEGRAM_HTTP_STAT_PORT=9100 \
       TELEGRAM_DIR=/xdata TELEGRAM_TEMP_DIR=/xtmp \
       TELEGRAM_LOG_FILE=/xlogs/app.log TELEGRAM_LOCAL=true \
       ./entrypoint.sh 2>&1)
  echo "$output" | grep -F -q -- "--http-port 9000"
  echo "$output" | grep -F -q -- "--http-stat-port 9100"
  echo "$output" | grep -F -q -- "--dir /xdata"
  echo "$output" | grep -F -q -- "--temp-dir /xtmp"
  echo "$output" | grep -F -q -- "--log /xlogs/app.log"
  echo "$output" | grep -F -q -- " --local"
}

test_extra_args_passthrough() {
  local dir
  dir=$(setup_sandbox)
  output=$(cd "$dir" \
    && TELEGRAM_API_ID=1 TELEGRAM_API_HASH=abc \
       TELEGRAM_EXTRA_ARGS="--max-webhook-connections 50 --log-verbosity-level 3" \
       ./entrypoint.sh 2>&1)
  echo "$output" | grep -F -q -- "--max-webhook-connections 50"
  echo "$output" | grep -F -q -- "--log-verbosity-level 3"
}

test_exec_passthrough_when_args_present() {
  local dir
  dir=$(setup_sandbox)
  # When a positional arg is provided, script should exec it and not error on envs
  output=$(cd "$dir" && ./entrypoint.sh echo hello 2>&1)
  echo "$output" | grep -q "hello"
}

run_test "missing API ID" test_missing_api_id
run_test "missing API HASH" test_missing_api_hash
run_test "builds default args" test_builds_expected_args_defaults
run_test "custom args and --local" test_custom_args_and_local
run_test "extra args passthrough" test_extra_args_passthrough
run_test "exec passthrough" test_exec_passthrough_when_args_present

if [ "$failures" -ne 0 ]; then
  echo "Tests failed: $failures"
  exit 1
fi
echo "All tests passed."
