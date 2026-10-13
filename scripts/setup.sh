#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Inspect before changing anything. Existing working runtimes are reused.
command -v python3 >/dev/null || { echo 'Python 3 is required by this environment.' >&2; exit 1; }
python3 --version
if command -v node >/dev/null; then node --version; fi
python3 scripts/validate_bundle.py

if [[ ! -x .venv/bin/python ]]; then python3 -m venv .venv; fi
if ! .venv/bin/python -c 'import yaml' >/dev/null 2>&1; then
  .venv/bin/python -m pip install 'PyYAML>=6,<7'
fi
.venv/bin/python scripts/validate_bundle.py --yaml

for option in "$@"; do
  case "$option" in
    --documents)
      if ! .venv/bin/python -c 'import pypdf, docx, pptx, openpyxl, PIL, pandas, matplotlib' >/dev/null 2>&1; then
        .venv/bin/python -m pip install -r environment/requirements-documents.txt
      fi
      .venv/bin/python -c 'import pypdf, docx, pptx, openpyxl, PIL, pandas, matplotlib; print("Document libraries ready")'
      ;;
    --lark)
      command -v npm >/dev/null || { echo 'Node.js/npm is required for lark-cli.' >&2; exit 1; }
      if [[ ! -x tools/lark/node_modules/.bin/lark-cli ]]; then
        npm install --prefix tools/lark --no-audit --no-fund '@larksuite/cli@1.0.60'
      fi
      tools/lark/node_modules/.bin/lark-cli --version
      echo 'CLI installed. Account authorization is separate; use auth status --verify before access.'
      ;;
    *) echo "Unknown option: $option" >&2; exit 2 ;;
  esac
done
echo 'Setup verified. Python tools: .venv/bin/python. User profile: memory/PROFILE.md.'
