# ragdoll-meta/justfile

import "~/.justfile"

meta := justfile_directory()

# Default recipe
default: list

# git commit
commit:
    aigcm -s ~/CONVENTIONAL_COMMITS.md

whereami:
    echo "{{ meta }}/coss.toml"

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
@update-versions: sm-update
    #!/bin/bash
    set -euo pipefail

    meta="{{ meta }}"
    echo "DEBUG meta = $meta"

    # Read version from .version file
    VERSION=$(cat .version | tr -d '[:space:]')

    echo "Updating all version.rb files to version: $VERSION"

    for file in "ragdoll/lib/ragdoll/core/version.rb" "ragdoll-cli/lib/ragdoll/cli/version.rb" "ragdoll-rails/lib/ragdoll/rails/version.rb"; do
        echo "DEBUG file = $file"

        if [ -f "$file" ]; then
            repo=$(echo "$file" | cut -d '/' -f 1)
            echo "DEBUG repo = $repo"
            sed -i '' "s/VERSION = \"[^\"]*\"/VERSION = \"$VERSION\"/" "$file"
            git add "$file"
            #
            pushd "$repo"
            coss="coss.toml"
            sed -i '' "s/version = \"[^\"]*\"/version = \"$VERSION\"/" "$coss"
            git add "$coss"
            #
            # git commit -m "Update version to $VERSION"
            # git push
            popd
            echo "✓ Updated $file"
        fi
    done

    echo "Version update complete!"
