#!/bin/bash
# Собирает config/index.json — отсортированный список файлов процессов.
# Запускается фазой сборки до копирования ресурсов; в репо индекс не коммитится,
# источник истины — содержимое папки.
set -euo pipefail

# SRCROOT задаёт Xcode; при ручном запуске — папка проекта, где лежит скрипт
CONFIG_DIR="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}/../config"

python3 - "$CONFIG_DIR" << 'PYEOF'
import json, os, sys

directory = sys.argv[1]
names = sorted(f for f in os.listdir(directory) if f.endswith(".json") and f != "index.json")
with open(os.path.join(directory, "index.json"), "w") as out:
    json.dump(names, out, indent=2)
    out.write("\n")
PYEOF
