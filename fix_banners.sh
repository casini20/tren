#!/bin/bash

echo "🔍 Fixing redirect banners safely..."

find . -type f -name "*.html" ! -path "./.git/*" ! -path "./node_modules/*" | while read file; do
    
    # Check if file has the banner
    if grep -q "This page has moved to" "$file" 2>/dev/null; then
        echo "Found banner in: $file"
        
        # Create temp file
        temp="${file}.tmp"
        
        # Read file and remove only the banner lines
        awk '
        /position:fixed;top:0;left:0;right:0;z-index:9999;background:var\(--bg3\)/ { skip=1; next }
        skip && /Redirecting now\.\.\./ { skip=0; next }
        skip { next }
        /<<div style="height:60px;"><\/div>/ { next }
        { print }
        ' "$file" > "$temp"
        
        # Replace original
        mv "$temp" "$file"
        echo "✅ Fixed: $file"
    fi
done

echo ""
echo "✅ Done! Check your files in browser to verify."
