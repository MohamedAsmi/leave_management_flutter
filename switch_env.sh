#!/bin/bash

# Flutter Environment Switcher Script

ENVIRONMENT_FILE="lib/core/config/environment.dart"

set_development() {
    echo "Setting environment to DEVELOPMENT..."
    sed -i.bak 's/Environment\.production/Environment.development/' "$ENVIRONMENT_FILE"
    echo "Environment set to development (localhost:8000)"
}

set_production() {
    echo "Setting environment to PRODUCTION..."
    sed -i.bak 's/Environment\.development/Environment.production/' "$ENVIRONMENT_FILE"
    echo "Environment set to production (31.97.71.5)"
}

show_current() {
    if grep -q "Environment\.development" "$ENVIRONMENT_FILE"; then
        echo "Current environment: DEVELOPMENT (localhost:8000)"
    else
        echo "Current environment: PRODUCTION (31.97.71.5)"
    fi
}

case "$1" in
    "dev"|"development")
        set_development
        ;;
    "prod"|"production")
        set_production
        ;;
    "status"|"current")
        show_current
        ;;
    *)
        echo "Usage: $0 {dev|prod|status}"
        echo "  dev/development  - Switch to development environment (localhost:8000)"
        echo "  prod/production  - Switch to production environment (31.97.71.5)"
        echo "  status/current   - Show current environment"
        ;;
esac