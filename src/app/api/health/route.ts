import { NextResponse } from 'next/server';

/**
 * Health check endpoint for production monitoring
 * GET /api/health
 */
export async function GET() {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: '0.1.0',
  };

  return NextResponse.json(health, { status: 200 });
}

