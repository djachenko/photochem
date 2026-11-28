#!/bin/bash
# Собирает Resources/Config/index.json — отсортированный список файлов процессов.
# Индекс нужен для remote-доставки; bundled-загрузка перечисляет JSON напрямую.
# В репо индекс не коммитится, источник истины — содержимое папки.
set -euo pipefail

# Путь определяется от скрипта одинаково при ручном запуске и из Xcode.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../Resources/Config"

python3 - "$CONFIG_DIR" << 'PYEOF'
import json, os, sys

directory = sys.argv[1]
names = sorted(f for f in os.listdir(directory) if f.endswith(".json") and f != "index.json")
with open(os.path.join(directory, "index.json"), "w") as out:
    json.dump(names, out, indent=2)
    out.write("\n")
PYEOF
