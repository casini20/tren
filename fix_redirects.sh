#!/bin/bash

echo "🔍 Finding and removing homepage redirects..."

find . -type f -name "*.html" ! -path "./.git/*" ! -path "./node_modules/*" | while read file; do
    
    # Check if file has redirect to homepage
    if grep -q 'url=https://trenai.vercel.app/' "$file" 2>/dev/null || \
       grep -q 'window.location.replace.*trenai.vercel.app' "$file" 2>/dev/null || \
       grep -q 'window.location.href.*trenai.vercel.app' "$file" 2>/dev/null; then
        
        echo "❌ Found redirect in: $file"
        
        # Remove meta refresh redirect
        sed -i 's|<meta http-equiv="refresh" content="0; url=https://trenai.vercel.app/">||g' "$file"
        
        # Remove JS redirect
        sed -i 's|<script>window.location.replace("https://trenai.vercel.app/");</script>||g' "$file"
        sed -i 's|window.location.replace("https://trenai.vercel.app/");||g' "$file"
        
        # Remove "page moved" banner
        sed -i '/This page has moved to/d' "$file"
        sed -i '/Redirecting now/d' "$file"
        
        echo "✅ Fixed: $file"
    fi
done

echo ""
echo "✅ Done! All homepage redirects removed."
