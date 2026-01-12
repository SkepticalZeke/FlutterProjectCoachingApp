"use strict";
/**
 * Firebase Authentication Middleware
 * Validates Firebase ID tokens from the Authorization header
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = authMiddleware;
exports.optionalAuthMiddleware = optionalAuthMiddleware;
exports.requireRole = requireRole;
const admin = __importStar(require("firebase-admin"));
/**
 * Middleware to validate Firebase ID token
 * Extracts user information from the token and attaches to req.user
 *
 * Usage:
 *   router.get('/protected', authMiddleware, handler);
 */
async function authMiddleware(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        res.status(401).json({
            success: false,
            error: 'Authorization header is required',
            code: 'AUTH_MISSING_HEADER'
        });
        return;
    }
    // Check for Bearer token format
    if (!authHeader.startsWith('Bearer ')) {
        res.status(401).json({
            success: false,
            error: 'Authorization header must use Bearer scheme',
            code: 'AUTH_INVALID_SCHEME'
        });
        return;
    }
    const idToken = authHeader.split('Bearer ')[1];
    if (!idToken) {
        res.status(401).json({
            success: false,
            error: 'Token is required',
            code: 'AUTH_MISSING_TOKEN'
        });
        return;
    }
    try {
        // Verify the ID token with Firebase Admin
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        // Get additional user info if needed
        let role;
        try {
            const userDoc = await admin.firestore()
                .collection('users')
                .doc(decodedToken.uid)
                .get();
            if (userDoc.exists) {
                role = userDoc.data()?.role;
            }
        }
        catch (error) {
            // Log but don't fail if we can't get user role
            console.warn('Could not fetch user role:', error);
        }
        // Attach user info to request
        req.user = {
            uid: decodedToken.uid,
            email: decodedToken.email,
            emailVerified: decodedToken.email_verified,
            displayName: decodedToken.name,
            photoURL: decodedToken.picture,
            role
        };
        next();
    }
    catch (error) {
        console.error('Token verification failed:', error);
        // Determine error type
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        if (errorMessage.includes('expired')) {
            res.status(401).json({
                success: false,
                error: 'Token has expired',
                code: 'AUTH_TOKEN_EXPIRED'
            });
        }
        else if (errorMessage.includes('revoked')) {
            res.status(401).json({
                success: false,
                error: 'Token has been revoked',
                code: 'AUTH_TOKEN_REVOKED'
            });
        }
        else {
            res.status(401).json({
                success: false,
                error: 'Invalid token',
                code: 'AUTH_INVALID_TOKEN'
            });
        }
    }
}
/**
 * Optional authentication middleware
 * Attaches user info if token is present, but doesn't require it
 */
async function optionalAuthMiddleware(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        // No auth header, continue without user
        next();
        return;
    }
    const idToken = authHeader.split('Bearer ')[1];
    if (!idToken) {
        next();
        return;
    }
    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        req.user = {
            uid: decodedToken.uid,
            email: decodedToken.email,
            emailVerified: decodedToken.email_verified,
            displayName: decodedToken.name,
            photoURL: decodedToken.picture
        };
    }
    catch (error) {
        // Token invalid, but that's okay for optional auth
        console.warn('Optional auth token validation failed:', error);
    }
    next();
}
/**
 * Role-based authorization middleware factory
 * Use after authMiddleware to restrict access to specific roles
 *
 * Usage:
 *   router.get('/admin', authMiddleware, requireRole('admin'), handler);
 */
function requireRole(...allowedRoles) {
    return (req, res, next) => {
        if (!req.user) {
            res.status(401).json({
                success: false,
                error: 'Authentication required',
                code: 'AUTH_REQUIRED'
            });
            return;
        }
        if (!req.user.role || !allowedRoles.includes(req.user.role)) {
            res.status(403).json({
                success: false,
                error: 'Insufficient permissions',
                code: 'AUTH_FORBIDDEN',
                requiredRoles: allowedRoles
            });
            return;
        }
        next();
    };
}
//# sourceMappingURL=auth.js.map