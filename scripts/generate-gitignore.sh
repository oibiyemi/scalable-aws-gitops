#!/bin/bash
TOOLS=("Python" "Terraform" "Docker" "Go")
GIT_IGNORE=".gitignore"

# Empty/initialize file
> "$GIT_IGNORE"

for tool in "${TOOLS[@]}"; do
    echo "Fetching $tool.gitignore..."
    OUTPUT=$(gh api "repos/github/gitignore/contents/${tool}.gitignore" | jq -r '.content' | base64 --decode)

    if [[ -z "$OUTPUT" ]]; then
        echo "Failed to fetch $tool template. Skipping."
        continue
    fi

    {
      echo ""
      echo "# --- ${tool} .gitignore ---"
      echo "$OUTPUT"
    } >> "$GIT_IGNORE"
done

echo "✅ Combined .gitignore created at $GIT_IGNORE"
