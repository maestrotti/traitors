import type {Metadata} from 'next';import './globals.css';
export const metadata:Metadata={title:'Vila Izdajnika — Igra povjerenja',description:'Društvena igra tajnih uloga, misija i izdaje.'};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="bs"><body>{children}</body></html>}
