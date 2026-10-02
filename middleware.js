import { NextResponse } from 'next/server';
export function middleware(req) {
  if (req.cookies.get('session')?.value !== 'admin') return NextResponse.redirect(new URL('/login', req.url));
  return NextResponse.next();
}
export const config = { matcher: ['/admin/:path*'] };
