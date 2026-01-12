"use strict";
/**
 * Shared types and utilities for Cloud Functions
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAuth = requireAuth;
exports.getUserRole = getUserRole;
exports.requireRole = requireRole;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = __importDefault(require("./firebase"));
/**
 * Validate that user is authenticated
 */
function requireAuth(auth) {
    if (!auth) {
        throw new https_1.HttpsError('unauthenticated', 'You must be logged in to perform this action');
    }
    return auth.uid;
}
/**
 * Get user role from Firestore
 */
async function getUserRole(uid) {
    const db = firebase_1.default.firestore();
    const userDoc = await db.collection('users').doc(uid).get();
    return userDoc.exists ? userDoc.data()?.role || null : null;
}
/**
 * Require specific role(s)
 */
async function requireRole(uid, allowedRoles) {
    const role = await getUserRole(uid);
    if (!role || !allowedRoles.includes(role)) {
        throw new https_1.HttpsError('permission-denied', `This action requires one of these roles: ${allowedRoles.join(', ')}`);
    }
    return role;
}
//# sourceMappingURL=shared.js.map