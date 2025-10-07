#!/bin/bash
# Flow-Space Backend Server Startup Script
# This script starts the server and keeps it running

echo "🚀 Starting Flow-Space Backend Server..."
echo "📅 Started at: $(date)"
echo ""

# Change to script directory
cd "$(dirname "$0")"

# Function to start server
start_server() {
    echo "🔄 Starting server..."
    node server-fixed.js
    
    # If server stops, restart it
    echo ""
    echo "⚠️  Server stopped. Restarting in 5 seconds..."
    sleep 5
    start_server
}

# Start the server with auto-restart
start_server
