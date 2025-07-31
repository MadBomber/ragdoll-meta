# ragdoll-meta/justfile

import "~/.justfile"

# Default recipe
default: list

# Update the submodules
sm-update:
    git submodule update --remote --merge

# Recipe to initialize and update git submodules
sm-init:
    git submodule update --init --recursive

# Recipe to add a new submodule
sm-add url path:
    git submodule add {{ url }} {{ path }}
    git submodule update --init --recursive

# Recipe to remove a submodule
sm-remove name:
    git submodule deinit -f {{ name }}
    git rm -f {{ name }}
    rm -rf .git/modules/{{ name }}

# Recipe to list all submodules
sm-list:
    git submodule

# Update VERSION constant in all submodule version.rb files
update-versions: sm-update
    #!/bin/bash
    set -euo pipefail

    # Read version from .version file
    VERSION=$(cat .version | tr -d '[:space:]')

    echo "Updating all version.rb files to version: $VERSION"

    for file in "ragdoll/lib/ragdoll/core/version.rb" "ragdoll-cli/lib/ragdoll/cli/version.rb" "ragdoll-rails/lib/ragdoll/rails/version.rb"; do
        if [ -f "$file" ]; then
            sed -i '' "s/VERSION = \"[^\"]*\"/VERSION = \"$VERSION\"/" "$file"
            pushd $(dirname "$file")
            echo $(pwd)
            git add "$file"
            git commit -m "Update version to $VERSION"
            git push
            popd
            echo "✓ Updated $file"
        fi
    done

    echo "Version update complete!"
