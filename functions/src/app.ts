/**
 * Express Application Configuration
 * Main Express app wrapped for Firebase Functions
 */

import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';

// Import service routers
import athletesRouter from './services/athletes';
import coachesRouter from './services/coaches';
import drillsRouter from './services/drills';
import notificationsRouter from './services/notifications';

// Create Express app
const app = express();

// =============================================================================
// Middleware Configuration
// =============================================================================

// CORS configuration - allow requests from any origin (adjust for production)
app.use(cors({
    origin: true, // Allow all origins for development
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
}));

// Parse JSON bodies
app.use(express.json({ limit: '10mb' }));

// Parse URL-encoded bodies
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req: Request, res: Response, next: NextFunction) => {
    const start = Date.now();

    res.on('finish', () => {
        const duration = Date.now() - start;
        console.log(
            `${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`
        );
    });

    next();
});

// =============================================================================
// Routes
// =============================================================================

// Health check endpoint (no auth required)
app.get('/health', (req: Request, res: Response) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        region: 'asia-southeast1'
    });
});

// API documentation endpoint
app.get('/', (req: Request, res: Response) => {
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
app.use('/athletes', athletesRouter);
app.use('/coaches', coachesRouter);
app.use('/drills', drillsRouter);
app.use('/notifications', notificationsRouter);

// =============================================================================
// Error Handling
// =============================================================================

// 404 handler
app.use((req: Request, res: Response) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found',
        path: req.path,
        method: req.method
    });
});

// Global error handler
app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
    console.error('Unhandled error:', err);

    // Don't expose internal error details in production
    const isDev = process.env.NODE_ENV !== 'production';

    res.status(500).json({
        success: false,
        error: isDev ? err.message : 'Internal server error',
        ...(isDev && { stack: err.stack })
    });
});

export default app;
