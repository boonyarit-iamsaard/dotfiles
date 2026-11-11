# Shared maintenance Steps, Step groups, and Preconditions (source from zsh).
# Steps stream command output; Preconditions run directly so interactive prompts
# such as sudo authentication remain attached to the terminal. Groups do not nest.
# Call steps_finish with an optional final message, then exit with its status.
zmodload zsh/datetime

typeset -gi _steps_passed=0 _steps_failed=0 _steps_errors=0 _steps_warnings=0 _steps_skipped=0
typeset -ga _steps_failed_names=()
typeset -g _steps_group=''
typeset -gi _steps_group_failed=0 _steps_plain=0
[[ -n ${NO_COLOR+x} || ! -t 1 ]] && _steps_plain=1

_steps_log() {
    local level=$1 message=$2 timestamp colour='' icon='' reset=''
    strftime -s timestamp '%Y-%m-%d %H:%M:%S' "$EPOCHSECONDS"
    if (( ! _steps_plain )); then
        reset=$'\033[0m'
        case $level in
            INFO) colour=$'\033[0;34m'; icon=$'\U2139\UFE0F' ;;
            SUCCESS) colour=$'\033[0;32m'; icon=$'\U2705' ;;
            FINISHED) colour=$'\033[0;32m'; icon=$'\U1F389' ;;
            WARN) colour=$'\033[1;33m'; icon=$'\U26A0\UFE0F' ;;
            ERROR) colour=$'\033[0;31m'; icon=$'\U274C' ;;
            OUTPUT) colour=$'\033[0;36m'; icon=$'\U1F539' ;;
            BAD_OUTPUT) colour=$'\033[0;31m'; icon=$'\U1F534' ;;
        esac
        printf '%s[%s] %s  %s%s\n' "$colour" "$timestamp" "$icon" "$message" "$reset"
    else
        printf '[%s] [%s] %s\n' "$timestamp" "$level" "$message"
    fi
}

log_info() { _steps_log INFO "$1"; }
log_success() { _steps_log SUCCESS "$1"; }
log_warn() { _steps_log WARN "$1"; }
log_error() { _steps_log ERROR "$1"; }

_steps_execute() {
    setopt local_options pipefail
    local line
    "$@" 2>&1 | while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -z "${line// /}" ]]; then
            _steps_log OUTPUT '---'
        elif [[ "$line" == *Error* || "$line" == *Err* ]]; then
            _steps_log BAD_OUTPUT "$line"
        else
            _steps_log OUTPUT "$line"
        fi
    done
    # Nothing may run between the pipeline and this return: it resets pipestatus.
    return $pipestatus[1]
}

step_skip() {
    (( _steps_skipped += 1 ))
    log_warn "${2:-Step skipped: $1}"
}

group_begin() {
    _steps_group=$1
    _steps_group_failed=0
}

group_end() {
    _steps_group=''
    _steps_group_failed=0
}

_steps_run() {
    local severity=$1 name=$2 streamed=$3 result
    shift 3
    if (( _steps_group_failed )); then
        step_skip "$name" "Step skipped: $name (Step group: $_steps_group)."
        return 0
    fi

    log_info "Step: $name"
    if (( streamed )); then
        _steps_execute "$@"
        result=$?
    else
        "$@"
        result=$?
    fi
    if (( result == 0 )); then
        (( _steps_passed += 1 ))
        log_success "Step succeeded: $name"
    else
        (( _steps_failed += 1 ))
        _steps_failed_names+=("$name [$severity]")
        if [[ "$severity" == error ]]; then
            (( _steps_errors += 1 ))
            log_error "Step failed: $name (exit $result)."
        else
            (( _steps_warnings += 1 ))
            log_warn "Step failed: $name (exit $result)."
        fi
        [[ -n "$_steps_group" ]] && _steps_group_failed=1
    fi
    return $result
}

step() {
    local severity=$1 name=$2
    shift 2
    _steps_run "$severity" "$name" 1 "$@"
}

precondition() {
    local name=$1 result
    shift
    _steps_run error "$name" 0 "$@"
    result=$?
    if (( result != 0 )) && [[ -z "$_steps_group" ]]; then
        steps_finish
        exit 1
    fi
    return $result
}

steps_finish() {
    log_info "Step summary: $_steps_passed succeeded, $_steps_failed failed ($_steps_errors errors, $_steps_warnings warnings), $_steps_skipped skipped."
    if (( _steps_failed )); then
        log_info "Failed steps: ${(j:, :)_steps_failed_names}"
    fi
    if (( _steps_errors )); then
        [[ -n ${1:-} ]] && log_info "$1"
        return 1
    fi
    [[ -n ${1:-} ]] && _steps_log FINISHED "$1"
    return 0
}
