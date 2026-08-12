import { Request, Response, NextFunction } from 'express';

export const verifyBotApiKey = (req: Request, res: Response, next: NextFunction) => {
  const apiKey = req.headers['x-api-key'];
  const validApiKey = process.env.BOT_API_KEY;

  if (!validApiKey) {
    console.warn('BOT_API_KEY environment variable is not set!');
    return res.status(500).json({ error: 'Internal server configuration error.' });
  }

  if (apiKey === validApiKey) {
    next();
  } else {
    res.status(403).json({ error: 'Forbidden. Invalid bot API key.' });
  }
};
