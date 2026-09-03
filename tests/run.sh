#!/usr/bin/env bash
set -euo pipefail

failures=0
cleanup_dirs=()
trap 'rm -rf "${cleanup_dirs[@]+"${cleanup_dirs[@]}"}"' EXIT

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
  cleanup_dirs+=("$dir")
  mkdir -p "$dir"
  cp "$(pwd)/entrypoint.sh" "$dir/entrypoint.sh"
  chmod +x "$dir/entrypoint.sh"

  # Create mock binary that prints version and echoes args
  cat > "$dir/telegram-bot-api" <<'EOF'
#!/usr/bin/env sh
if [ "$1" = "--version" ]; then
  echo "Telegram Bot API Server mock 10.3.0"
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
  echo "$output" | grep -F -q "Starting telegram-bot-api (Telegram Bot API Server mock 10.3.0) with args:  --http-port 8081 --http-stat-port 8082 --dir /data --temp-dir /tmp --log /data/logs/telegram-bot-api.log"
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

test_local_with_numeric_flag() {
  local dir
  dir=$(setup_sandbox)
  output=$(cd "$dir" \
    && TELEGRAM_API_ID=1 TELEGRAM_API_HASH=abc \
       TELEGRAM_LOCAL=1 \
       ./entrypoint.sh 2>&1)
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

test_release_builds_each_architecture_once() {
  local workflow=.github/workflows/docker-release.yml

  grep -F -q "platform: linux/amd64" "$workflow" || return 1
  grep -F -q "platform: linux/arm64" "$workflow" || return 1
  grep -F -q "runner: ubuntu-24.04-arm" "$workflow" || return 1
  [ "$(grep -F -c "uses: docker/build-push-action@v7" "$workflow")" -eq 1 ] || return 1
  grep -F -q "push-by-digest=true" "$workflow" || return 1
  grep -F -q "Validate digest" "$workflow" || return 1
  grep -F -q "Smoke test published digest" "$workflow" || return 1
  grep -F -q "docker buildx imagetools create" "$workflow" || return 1
  grep -F -q "Verify manifest" "$workflow" || return 1
  grep -F -q "dockerhub-description:" "$workflow" || return 1
  grep -F -q "needs: merge" "$workflow" || return 1
  grep -F -q "concurrency:" "$workflow" || return 1
  ! grep -F -q "smoke-test:" "$workflow" || return 1
  ! grep -F -q "docker/setup-qemu-action" "$workflow" || return 1
}

test_build_uses_parallel_compilation() {
  grep -F -q "cmake --build . --target install --parallel \"\$(nproc)\"" Dockerfile
}

run_test "missing API ID" test_missing_api_id
run_test "missing API HASH" test_missing_api_hash
run_test "builds default args" test_builds_expected_args_defaults
run_test "custom args and --local" test_custom_args_and_local
run_test "--local with TELEGRAM_LOCAL=1" test_local_with_numeric_flag
run_test "extra args passthrough" test_extra_args_passthrough
run_test "exec passthrough" test_exec_passthrough_when_args_present
run_test "release builds each architecture once" test_release_builds_each_architecture_once
run_test "build uses parallel compilation" test_build_uses_parallel_compilation

if [ "$failures" -ne 0 ]; then
  echo "Tests failed: $failures"
  exit 1
fi
echo "All tests passed."
