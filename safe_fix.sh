#!/bin/bash

echo "🔧 Removing redirect banners safely..."

find . -type f -name "*.html" ! -path "./.git/*" ! -path "./node_modules/*" | while read file; do
    
    # Check if file has the redirect banner
    if grep -q "This page has moved to" "$file" 2>/dev/null; then
        echo "Found in: $file"
        
        # Use Python for precise line-by-line removal
        python3 << 'PYEOF'
import sys
import re

filepath = "$file"
with open(filepath, 'r') as f:
    lines = f.readlines()

output = []
skip = False
for line in lines:
    if 'position:fixed;top:0;left:0;right:0;z-index:9999;background:var(--bg3)' in line:
        skip = True
        continue
    if skip and 'Redirecting now' in line:
        skip = False
        continue
    if skip:
        continue
    if '<div style="height:60px;"></div>' in line:
        continue
    output.append(line)

with open(filepath, 'w') as f:
    f.writelines(output)
PYEOF
        
        echo "✅ Fixed: $file"
    fi
done

echo ""
echo "✅ Done!"
