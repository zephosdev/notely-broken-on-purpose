export const metadata = { title: 'Notely' };
export default function RootLayout({ children }) {
  return (<html lang="en"><body style={{ fontFamily: 'system-ui', margin: 40 }}>{children}</body></html>);
}
