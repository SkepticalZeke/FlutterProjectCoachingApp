"use strict";
/**
 * Express Application Configuration
 * Main Express app wrapped for Firebase Functions
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
// Import service routers
const athletes_1 = __importDefault(require("./services/athletes"));
const coaches_1 = __importDefault(require("./services/coaches"));
const drills_1 = __importDefault(require("./services/drills"));
const notifications_1 = __importDefault(require("./services/notifications"));
// Create Express app
const app = (0, express_1.default)();
// =============================================================================
// Middleware Configuration
// =============================================================================
// CORS configuration - allow requests from any origin (adjust for production)
app.use((0, cors_1.default)({
    origin: true, // Allow all origins for development
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
}));
// Parse JSON bodies
app.use(express_1.default.json({ limit: '10mb' }));
// Parse URL-encoded bodies
app.use(express_1.default.urlencoded({ extended: true, limit: '10mb' }));
// Request logging middleware
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        console.log(`${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`);
    });
    next();
});
// =============================================================================
// Routes
// =============================================================================
// Health check endpoint (no auth required)
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        region: 'asia-southeast1'
    });
});
// API documentation endpoint
app.get('/', (req, res) => {
    res.json({
        name: 'Fitness Coaching API',
        version: '1.0.0',
        endpoints: {
            health: 'GET /health',
            athletes: '/athletes/*',
            coaches: '/coaches/*',
            drills: '/drills/*',
            notifications: '/notifications/*'
        },
        documentation: 'Contact the development team for full API documentation'
    });
});
// Mount service routers
app.use('/athletes', athletes_1.default);
app.use('/coaches', coaches_1.default);
app.use('/drills', drills_1.default);
app.use('/notifications', notifications_1.default);
// =============================================================================
// Error Handling
// =============================================================================
// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found',
        path: req.path,
        method: req.method
    });
});
// Global error handler
app.use((err, req, res, _next) => {
    console.error('Unhandled error:', err);
    // Don't expose internal error details in production
    const isDev = process.env.NODE_ENV !== 'production';
    res.status(500).json({
        success: false,
        error: isDev ? err.message : 'Internal server error',
        ...(isDev && { stack: err.stack })
    });
});
exports.default = app;
//# sourceMappingURL=app.js.map