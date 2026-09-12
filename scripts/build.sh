#!/usr/bin/env bash
set -euo pipefail

task_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$task_root"

test_flags=()
output="bin/SensorViewer.prg"
case "${1:-}" in
    --test) test_flags=(-t); output="bin/SensorViewer-tests.prg" ;;
    "") ;;
    *) echo 'Uso: bash scripts/build.sh [--test]' >&2; exit 2 ;;
esac

compiler="${CONNECTIQ_SDK:+${CONNECTIQ_SDK}/bin/}monkeyc"
if ! command -v "$compiler" >/dev/null 2>&1; then
    echo 'No se encuentra monkeyc. Configura CONNECTIQ_SDK o añade el SDK al PATH.' >&2
    exit 1
fi
if [[ -z "${DEVELOPER_KEY:-}" || ! -f "$DEVELOPER_KEY" ]]; then
    echo 'Configura DEVELOPER_KEY con la ruta a tu clave de desarrollo DER.' >&2
    exit 1
fi

mkdir -p bin
"$compiler" -f monkey.jungle -d fenix7x -o "$output" -y "$DEVELOPER_KEY" -l 3 -w "${test_flags[@]}"
