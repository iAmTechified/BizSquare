import { Router, Response } from 'express';
import { AuthRequest, authenticateJWT } from '../middleware/auth.middleware';
import { pool } from '../db/pool';

const router = Router();

router.use(authenticateJWT);

router.get('/contacts', async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    
    // Fetch contacts, joining with users table if they are registered on Akawo
    const { rows } = await pool.query(
      `SELECT uc.*, u.full_name as network_name, u.phone_number as network_phone
       FROM user_contacts uc
       LEFT JOIN users u ON uc.contact_user_id = u.id
       WHERE uc.owner_id = $1
       ORDER BY uc.created_at DESC`,
      [userId]
    );

    res.json({ contacts: rows });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/contacts/:id', async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    const contactId = req.params.id;
    const { label, lead_grade, notes } = req.body;

    const { rows } = await pool.query(
      `UPDATE user_contacts 
       SET label = COALESCE($1, label), 
           lead_grade = COALESCE($2, lead_grade), 
           notes = COALESCE($3, notes)
       WHERE id = $4 AND owner_id = $5
       RETURNING *`,
      [label, lead_grade, notes, contactId, userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Contact not found or does not belong to you' });
    }

    res.json({ success: true, contact: rows[0] });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
