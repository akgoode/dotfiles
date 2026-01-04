#!/bin/bash
# Build the test container

set -e

cd "$(dirname "$0")"

echo "Building dotfiles test container..."
docker compose build

echo ""
echo "Build complete! Run with:"
echo "  cd test && docker compose up -d"
echo ""
echo "Then SSH in with:"
echo "  ssh testuser@localhost -p 2222"
echo "  Password: testpass"
echo ""
echo "Or run tests with:"
echo "  ./test/run-tests.sh"
