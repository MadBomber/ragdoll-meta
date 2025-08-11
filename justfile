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

# Build all gem submodules
build: build-ragdoll build-ragdoll-cli build-ragdoll-rails
    echo "All gems built successfully!"

# Build ragdoll gem
build-ragdoll:
    cd ragdoll && rake build

# Build ragdoll-cli gem
build-ragdoll-cli:
    cd ragdoll-cli && rake build

# Build ragdoll-rails gem
build-ragdoll-rails:
    cd ragdoll-rails && rake build

# Bundle install for all gem submodules
bundle: bundle-ragdoll bundle-ragdoll-cli bundle-ragdoll-rails bundle-ragdoll-demo
    echo "All gem dependencies bundled successfully!"

# Bundle install for ragdoll gem
bundle-ragdoll:
    cd ragdoll && bundle install

# Bundle install for ragdoll-cli gem
bundle-ragdoll-cli:
    cd ragdoll-cli && bundle install

# Bundle install for ragdoll-rails gem
bundle-ragdoll-rails:
    cd ragdoll-rails && bundle install

# Bundle install for ragdoll-demo
bundle-ragdoll-demo:
    cd ragdoll-demo && bundle install

# Install all gem submodules
install: install-ragdoll install-ragdoll-cli install-ragdoll-rails
    echo "All gems installed successfully!"

# Install ragdoll gem
install-ragdoll:
    cd ragdoll && rake install

# Install ragdoll-cli gem
install-ragdoll-cli:
    cd ragdoll-cli && rake install

# Install ragdoll-rails gem
install-ragdoll-rails:
    cd ragdoll-rails && rake install

# Bundle, build and install all gems
build-install: bundle build install
    echo "All gems bundled, built and installed!"

# Build all gems and start Rails server in ragdoll-demo
run: build
    cd ragdoll-demo && rails server

# Build all gems and start Rails console in ragdoll-demo
console: build
    cd ragdoll-demo && rails console

# Initialize ragdoll-demo with required setup
init:
    echo "Initializing ragdoll-demo application..."
    echo "Cleaning and installing bundle dependencies..."
    cd ragdoll-demo && bundle install
    echo "Ragdoll configuration initializer already created manually"
    echo "Copying ragdoll migrations..."
    cp -n ragdoll/db/migrate/*.rb ragdoll-demo/db/migrate/ || true
    echo "Running database migrations..."
    cd ragdoll-demo && rails db:migrate
    echo "Ragdoll-demo initialized successfully!"
    echo "Note: Ensure PostgreSQL has vector extension: CREATE EXTENSION IF NOT EXISTS vector;"

# Aliases
alias r := run
alias c := console
alias bi := build-install

# Update VERSION constant in all submodule version.rb files
update-versions: sm-update
    #!/bin/bash
    set -euo pipefail

    # Read version from .version file
    VERSION=$(cat .version | tr -d '[:space:]')

    echo "Updating all repositories to version: $VERSION"

    # Handle Ruby version files
    for file in "ragdoll/lib/ragdoll/core/version.rb" "ragdoll-cli/lib/ragdoll/cli/version.rb" "ragdoll-rails/lib/ragdoll/rails/version.rb" "ragdoll-demo/lib/version.rb"; do
        if [ -f "$file" ]; then
            repo=$(echo "$file" | cut -d '/' -f 1)
            relative_file=$(echo "$file" | cut -d '/' -f 2-)

            # Update the version file
            sed -i '' "s/VERSION = \"[^\"]*\"/VERSION = \"$VERSION\"/" "$file"

            # Navigate to submodule and commit changes there
            pushd "$repo" > /dev/null 2>&1
            git add "$relative_file" > /dev/null 2>&1


            # Update coss.toml in the submodule
            coss="coss.toml"
            if [ -f "$coss" ]; then
                sed -i '' "s/version = \"[^\"]*\"/version = \"$VERSION\"/" "$coss"
                git add "$coss" > /dev/null 2>&1
            fi

            # Commit changes in the submodule
            if git commit -m "Update version to $VERSION" > /dev/null 2>&1; then
                git push
                echo "✓ $repo updated"
            else
                echo "• $repo (no changes)"
            fi

            popd > /dev/null 2>&1
        fi
    done

    # Handle ragdoll-docs mkdocs.yml file
    docs_file="ragdoll-docs/mkdocs.yml"

    if [ -f "$docs_file" ]; then
        repo="ragdoll-docs"
        relative_file="mkdocs.yml"

        # Update the version in mkdocs.yml
        sed -i '' "s/version: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/version: $VERSION/" "$docs_file"

        # Navigate to submodule and commit changes there
        pushd "$repo" > /dev/null 2>&1
        git add "$relative_file" > /dev/null 2>&1

        # Update coss.toml in the submodule if it exists
        coss="coss.toml"
        if [ -f "$coss" ]; then
            sed -i '' "s/version = \"[^\"]*\"/version = \"$VERSION\"/" "$coss"
            git add "$coss" > /dev/null 2>&1
        fi

        # Commit changes in the submodule
        if git commit -m "Update version to $VERSION" > /dev/null 2>&1; then
            git push
            echo "✓ $repo updated"
        else
            echo "• $repo (no changes)"
        fi

        popd > /dev/null 2>&1
    fi


    echo "Done!"
