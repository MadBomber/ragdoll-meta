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
    cd "{{ meta }}/ragdoll-demo" && bundle install

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
    cd "{{ meta }}/ragdoll-demo" && rails server

# Build all gems and start Rails console in ragdoll-demo
console: build
    cd "{{ meta }}/ragdoll-demo" && rails console

# Start ragdoll-demo with all processes (foreman-based)
demo-start: demo-stop
    #!/bin/bash
    echo "🚀 Starting ragdoll-demo with all processes..."
    echo "🔄 Checking Redis server..."
    if ! pgrep -f "redis-server" > /dev/null; then
        echo "❌ Redis server is not running!"
        echo "💡 Please start Redis server first:"
        echo "   - Install: brew install redis"
        echo "   - Start:   brew services start redis"
        echo "   - Or run:  redis-server"
        exit 1
    else
        echo "✅ Redis server is running"
    fi
    echo "📦 Ensuring dependencies are up to date..."
    cd "{{ meta }}/ragdoll-demo" && bundle install
    echo "🚀 Starting all processes..."
    cd "{{ meta }}/ragdoll-demo" && ./bin/dev

# Stop ragdoll-demo and all its processes
demo-stop:
    echo "🛑 Stopping ragdoll-demo and all processes..."
    cd "{{ meta }}/ragdoll-demo" && ./bin/stop
    echo "ℹ️  Redis server is still running (managed separately)"
    echo "💡 To stop Redis: brew services stop redis"

# Emergency cleanup - kill all ragdoll processes forcefully
demo-cleanup:
    echo "🧹 Emergency cleanup of all ragdoll processes..."
    -pkill -f "foreman.*Procfile.dev" || true
    -lsof -ti:3000 | xargs kill -9 2>/dev/null || true  
    -pkill -f "solid-queue" || true
    -pkill -f "jobs.*start" || true
    sleep 2
    echo "✅ All processes forcefully cleaned up"

# Restart ragdoll-demo (stop then start)
demo-restart: demo-stop demo-start

# Show status of ragdoll-demo processes
demo-status:
    #!/bin/bash
    echo "📊 Ragdoll Demo Process Status:"
    echo ""
    
    # Check Redis server
    if pgrep -f "redis-server" > /dev/null 2>&1; then
        echo "✅ Redis Server: Running"
        pgrep -f "redis-server" | head -1 | while read pid; do
            echo "   PID: $pid"
        done
    else
        echo "❌ Redis Server: Not running (required for ActionCable)"
    fi
    
    # Check for foreman processes
    if pgrep -f "foreman.*Procfile.dev" > /dev/null 2>&1; then
        echo "✅ Foreman: Running"
        pgrep -f "foreman.*Procfile.dev" | head -5 | while read pid; do
            echo "   PID: $pid"
        done
    else
        echo "❌ Foreman: Not running"
    fi
    
    # Check Rails server on port 3000
    if lsof -ti:3000 > /dev/null 2>&1; then
        echo "✅ Rails Server: Running on port 3000"
        lsof -ti:3000 | while read pid; do
            echo "   PID: $pid"
        done
    else
        echo "❌ Rails Server: Not running on port 3000"
    fi
    
    # Check SolidQueue workers
    if pgrep -f "jobs.*ragdoll-demo" > /dev/null 2>&1; then
        echo "✅ SolidQueue Workers: Running"
        pgrep -f "jobs.*ragdoll-demo" | head -5 | while read pid; do
            echo "   PID: $pid"
        done
    else
        echo "❌ SolidQueue Workers: Not running"
    fi
    
    echo ""
    echo "🌐 URLs:"
    echo "  - Application: http://localhost:3000"
    echo "  - Jobs Dashboard: http://localhost:3000/mission_control/jobs"

# Open ragdoll-demo in browser
demo-open:
    echo "🌐 Opening ragdoll-demo in browser..."
    open http://localhost:3000

# Open job dashboard in browser
demo-jobs:
    echo "💼 Opening job dashboard in browser..."
    open http://localhost:3000/mission_control/jobs

# View ragdoll-demo logs
demo-logs:
    echo "📋 Viewing ragdoll-demo logs (press Ctrl+C to exit)..."
    cd "{{ meta }}/ragdoll-demo" && tail -f log/development.log

# Run database migrations for ragdoll-demo
demo-migrate:
    echo "🗄️ Running database migrations for ragdoll-demo..."
    cd "{{ meta }}/ragdoll-demo" && rails db:migrate

# Reset ragdoll-demo database
demo-db-reset:
    echo "🔄 Resetting ragdoll-demo database..."
    cd "{{ meta }}/ragdoll-demo" && rails db:reset

# Setup ragdoll-demo database
demo-db-setup:
    echo "🗄️ Setting up ragdoll-demo database..."
    cd "{{ meta }}/ragdoll-demo" && rails db:setup

# Update ragdoll-demo gem dependencies
demo-bundle:
    echo "💎 Updating ragdoll-demo gem dependencies..."
    cd "{{ meta }}/ragdoll-demo" && bundle install

# Clean and update ragdoll-demo dependencies
demo-bundle-clean:
    echo "💎 Cleaning and updating ragdoll-demo dependencies..."
    cd "{{ meta }}/ragdoll-demo" && rm -f Gemfile.lock && bundle install

# Initialize ragdoll-demo with required setup
init:
    echo "Initializing ragdoll-demo application..."
    echo "Cleaning and installing bundle dependencies..."
    cd "{{ meta }}/ragdoll-demo" && bundle install
    echo "Ragdoll configuration initializer already created manually"
    echo "Copying ragdoll migrations..."
    cp -n "{{ meta }}/ragdoll/db/migrate/*.rb" "{{ meta }}/ragdoll-demo/db/migrate/" || true
    echo "Running database migrations..."
    cd "{{ meta }}/ragdoll-demo" && rails db:migrate
    echo "Ragdoll-demo initialized successfully!"
    echo "Note: Ensure PostgreSQL has vector extension: CREATE EXTENSION IF NOT EXISTS vector;"

# Aliases
alias r := run
alias c := console
alias bi := build-install
alias start := demo-start
alias stop := demo-stop
alias restart := demo-restart
alias status := demo-status
alias logs := demo-logs
alias cleanup := demo-cleanup

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
