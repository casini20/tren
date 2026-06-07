#!/bin/bash

# Pages that KEEP auth (dashboard pages)
DASHBOARD_PAGES="dashboard live-signals signals journal settings upgrade trenbot autosignals indicator"

# Function to check if a file is a dashboard page
is_dashboard() {
    local file="$1"
    for page in $DASHBOARD_PAGES; do
        if [[ "$file" == *"/$page"* ]] || [[ "$file" == *"/${page}.html"* ]]; then
            return 0
        fi
    done
    return 1
}

echo "🔍 Scanning all HTML files..."

find . -type f -name "*.html" ! -path "./.git/*" ! -path "./node_modules/*" | while read file; do
    
    if is_dashboard "$file"; then
        echo "⏭️  SKIPPED (dashboard): $file"
        continue
    fi
    
    # Check if file has auth redirect
    if grep -q "if(!(_session&&_session.access_token)){window.location.href=" "$file" 2>/dev/null; then
        # Remove the auth check line
        sed -i 's/if(!(_session&&_session.access_token)){window.location.href=[^;]*;}//g' "$file"
        echo "✅ Auth removed: $file"
    elif grep -q "_session.*access_token.*location.href" "$file" 2>/dev/null; then
        # Remove any variation of session auth redirect
        sed -i '/.*_session.*access_token.*location.href.*/d' "$file"
        echo "✅ Auth removed: $file"
    else
        echo "⏭️  No auth found: $file"
    fi
done

echo ""
echo "✅ Done! Dashboard pages keep auth. All other pages are now public."
