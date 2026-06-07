#!/bin/bash

echo "🔍 Removing redirect banners..."

find . -type f -name "*.html" ! -path "./.git/*" ! -path "./node_modules/*" | while read file; do
    
    # Remove the fixed banner div
    sed -i '/position:fixed;top:0;left:0;right:0;z-index:9999;background:var(--bg3)/,/Redirecting now\.\.\./d' "$file"
    
    # Remove the spacer div
    sed -i '/<<div style="height:60px;"><\/div>/d' "$file"
    
    # Also remove any remaining "page has moved" text
    sed -i '/This page has moved to/d' "$file"
    sed -i '/Redirecting now/d' "$file"
    
    echo "✅ Cleaned: $file"
done

echo ""
echo "✅ All banners removed!"
