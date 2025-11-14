const { Client } = require('pg');
const EventEmitter = require('events');
const { loggingService, LogLevel, LogCategory } = require('./loggingService');

class DatabaseNotificationService extends EventEmitter {
    constructor() {
        super();
        this.client = null;
        this.isConnected = false;
        this.listeners = new Map();
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 10;
        this.reconnectDelay = 5000; // 5 seconds
        this.socketService = null;
        
        // Set up global event emitter for model hooks
        this.setupGlobalEventEmitter();
    }

    /**
     * Initialize the database notification service
     * @param {string} connectionString - PostgreSQL connection string
     */
    async initialize(connectionString) {
        try {
            this.client = new Client({
                connectionString,
                connectionTimeoutMillis: 10000,
                keepAlive: true
            });

            // Set up event handlers
            this.client.on('notification', this.handleNotification.bind(this));
            this.client.on('error', this.handleError.bind(this));
            this.client.on('end', this.handleDisconnect.bind(this));

            await this.client.connect();
            this.isConnected = true;
            this.reconnectAttempts = 0;

            // Listen to all relevant channels
            await this.listenToChannels([
                'table_changes',
                'role_changes', 
                'user_presence'
            ]);

            loggingService.log(LogLevel.INFO, LogCategory.DATABASE, 
                'Database notification service initialized and connected',
                null,
                { channels: ['table_changes', 'role_changes', 'user_presence'] }
            );

            return true;
        } catch (error) {
            loggingService.log(LogLevel.ERROR, LogCategory.DATABASE,
                'Failed to initialize database notification service',
                error,
                { connectionString: this.maskConnectionString(connectionString) }
            );
            
            await this.attemptReconnect(connectionString);
            return false;
        }
    }

    /**
     * Listen to specific PostgreSQL channels
     * @param {string[]} channels - Array of channel names to listen to
     */
    async listenToChannels(channels) {
        if (!this.isConnected || !this.client) {
            throw new Error('Database notification service not connected');
        }

        for (const channel of channels) {
            try {
                await this.client.query(`LISTEN ${channel}`);
                loggingService.log(LogLevel.INFO, LogCategory.DATABASE,
                    `Listening to database channel: ${channel}`
                );
            } catch (error) {
                loggingService.log(LogLevel.ERROR, LogCategory.DATABASE,
                    `Failed to listen to channel: ${channel}`,
                    error
                );
            }
        }
    }

    /**
     * Handle incoming database notifications
     * @param {Object} msg - PostgreSQL notification message
     */
    handleNotification(msg) {
        try {
            const { channel, payload } = msg;
            const data = JSON.parse(payload);

            loggingService.log(LogLevel.DEBUG, LogCategory.DATABASE,
                `Received database notification from channel: ${channel}`,
                null,
                { channel, data }
            );

            // Notify all listeners for this channel
            if (this.listeners.has(channel)) {
                const channelListeners = this.listeners.get(channel);
                for (const listener of channelListeners) {
                    try {
                        listener(data, channel);
                    } catch (error) {
                        loggingService.log(LogLevel.ERROR, LogCategory.DATABASE,
                            'Error in notification listener',
                            error,
                            { channel, listener: listener.toString() }
                        );
                    }
                }
            }

            // Also notify wildcard listeners
            if (this.listeners.has('*')) {
                const wildcardListeners = this.listeners.get('*');
                for (const listener of wildcardListeners) {
                    try {
                        listener(data, channel);
                    } catch (error) {
                        loggingService.log(LogLevel.ERROR, LogCategory.DATABASE,
                            'Error in wildcard notification listener',
                            error,
                            { channel, listener: listener.toString() }
                        );
                    }
                }
            }

        } catch (error) {
            loggingService.log(LogLevel.ERROR, LogCategory.DATABASE,
                'Error processing database notification',
                error,
                { message: msg }
            );
        }
    }

    /**
     * Add a listener for specific channel or all channels
     * @param {string} channel - Channel name or '*' for all channels
     * @param {Function} listener - Callback function
     */
    addListener(channel, listener) {
        if (!this.listeners.has(channel)) {
            this.listeners.set(channel, []);
        }
        this.listeners.get(channel).push(listener);

        loggingService.log(LogLevel.INFO, LogCategory.DATABASE,
            `Added listener for channel: ${channel}`,
            null,
            { listenerCount: this.listeners.get(channel).length }
        );
    }

    /**
     * Remove a listener
     * @param {string} channel - Channel name
     * @param {Function} listener - Callback function to remove
     */
    removeListener(channel, listener) {
        if (this.listeners.has(channel)) {
            const listeners = this.listeners.get(channel);
            const index = listeners.indexOf(listener);
            if (index > -1) {
                listeners.splice(index, 1);
            }
        }
    }

    /**
     * Handle database connection errors
     * @param {Error} error - Connection error
     */
    handleError(error) {
        loggingService.log(LogLevel.ERROR, LogCategory.DATABASE,
            'Database notification service connection error',
            error
        );

        this.isConnected = false;
        this.cleanup();
    }

    /**
     * Handle database disconnection
     */
    handleDisconnect() {
        loggingService.log(LogLevel.WARN, LogCategory.DATABASE,
            'Database notification service disconnected'
        );

        this.isConnected = false;
        this.cleanup();
    }

    /**
     * Attempt to reconnect to the database
     * @param {string} connectionString - PostgreSQL connection string
     */
    async attemptReconnect(connectionString) {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            loggingService.log(LogLevel.ERROR, LogCategory.DATABASE,
                'Max reconnection attempts reached. Giving up.'
            );
            return;
        }

        this.reconnectAttempts++;
        const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

        loggingService.log(LogLevel.INFO, LogCategory.DATABASE,
            `Attempting to reconnect in ${delay}ms (attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts})`
        );

        setTimeout(async () => {
            try {
                await this.initialize(connectionString);
            } catch (error) {
                await this.attemptReconnect(connectionString);
            }
        }, delay);
    }

    /**
     * Clean up resources
     */
    cleanup() {
        if (this.client) {
            this.client.removeAllListeners();
            this.client.end().catch(() => {});
            this.client = null;
        }
    }

    /**
     * Get service status
     */
    getStatus() {
        return {
            isConnected: this.isConnected,
            reconnectAttempts: this.reconnectAttempts,
            listenerCount: this.listeners.size,
            channels: Array.from(this.listeners.keys())
        };
    }

    /**
     * Set up global event emitter for model hooks
     */
    setupGlobalEventEmitter() {
        // Create global event emitter if it doesn't exist
        if (!global.realtimeEvents) {
            const EventEmitter = require('events');
            global.realtimeEvents = new EventEmitter();
            
            // Set up listeners for model events
            this.setupModelEventListeners();
        }
    }

    /**
     * Set up listeners for model events and forward to socket service
     */
    setupModelEventListeners() {
        if (!global.realtimeEvents) return;

        // Listen for all model events and forward to socket service
        const eventsToListen = [
            'deliverable_created', 'deliverable_updated', 'deliverable_deleted',
            'sprint_created', 'sprint_updated', 'sprint_deleted',
            'project_created', 'project_updated', 'project_deleted',
            'user_created', 'user_updated', 'user_deleted', 'user_role_changed'
        ];

        eventsToListen.forEach(event => {
            global.realtimeEvents.on(event, (data) => {
                if (this.socketService) {
                    // Forward the event to all connected clients
                    this.socketService.broadcastToAll(event, data);
                    
                    loggingService.log(LogLevel.DEBUG, LogCategory.WEBSOCKET,
                        `Forwarded ${event} to socket service`,
                        null,
                        { data }
                    );
                }
            });
        });
    }

    /**
     * Set the socket service for event forwarding
     * @param {Object} socketService - Socket service instance
     */
    setSocketService(socketService) {
        this.socketService = socketService;
        
        // Re-setup model event listeners to ensure they use the new socket service
        if (global.realtimeEvents) {
            this.setupModelEventListeners();
        }
        
        loggingService.log(LogLevel.INFO, LogCategory.WEBSOCKET,
            'Socket service integrated with database notification service'
        );
    }

    /**
     * Mask sensitive information in connection string
     * @param {string} connectionString - Original connection string
     */
    maskConnectionString(connectionString) {
        return connectionString.replace(/:[^:@]*@/, ':****@');
    }

    /**
     * Shutdown the service gracefully
     */
    async shutdown() {
        loggingService.log(LogLevel.INFO, LogCategory.DATABASE,
            'Shutting down database notification service'
        );

        this.cleanup();
        this.listeners.clear();
        this.isConnected = false;
    }
}

// Global instance
const databaseNotificationService = new DatabaseNotificationService();

module.exports = {
    DatabaseNotificationService,
    databaseNotificationService
};