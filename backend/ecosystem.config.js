module.exports = {
  apps: [{
    name: 'flow-space-backend',
    script: 'server-fixed.js',
    cwd: '.',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'development',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    // Auto-restart settings
    min_uptime: '10s',
    max_restarts: 10,
    // Health monitoring
    health_check_grace_period: 3000,
    // Kill timeout
    kill_timeout: 5000
  }]
};