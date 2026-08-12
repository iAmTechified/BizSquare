"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const pool_1 = require("../db/pool");
class AuthService {
    static async registerUser(phoneNumber, fullName, nicheId) {
        // In a real app, you would verify the phone number with OTP first.
        // For this MVP, we insert directly.
        const { rows } = await pool_1.pool.query(`INSERT INTO users (phone_number, full_name, niche_id) 
       VALUES ($1, $2, $3) RETURNING *`, [phoneNumber, fullName, nicheId]);
        const user = rows[0];
        const token = this.generateToken(user.id);
        return { user, token };
    }
    static async loginUser(phoneNumber) {
        // Simplified login, normally involves OTP check
        const { rows } = await pool_1.pool.query(`SELECT * FROM users WHERE phone_number = $1`, [phoneNumber]);
        if (rows.length === 0) {
            throw new Error('User not found');
        }
        const user = rows[0];
        // Update last_login
        await pool_1.pool.query(`UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1`, [user.id]);
        const token = this.generateToken(user.id);
        return { user, token };
    }
    static generateToken(userId) {
        return jsonwebtoken_1.default.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '30d' });
    }
}
exports.AuthService = AuthService;
//# sourceMappingURL=auth.service.js.map