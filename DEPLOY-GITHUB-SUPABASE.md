# Vila izdajnika V10 — GitHub, Vercel i Supabase

## Važno: šta je trenutno funkcionalno

V10 je **lokalni demo**. `app/page.tsx` čuva partiju u `localStorage`. SQL u `supabase/schema.sql` je **početna struktura baze**, ali V10 **ne čita i ne upisuje** podatke u Supabase. Postavljanje baze samo po sebi NE omogućava multiplayer. Svaki posjetilac javnog linka ima vlastitu partiju i simulirane AI igrače.

## 1. Lokalna provjera

U folderu projekta pokreni:

```powershell
npm install
npm run build
npm run dev
```

Otvori http://localhost:3000. Ako `npm run build` prijavi grešku, popravi je prije objave.

## 2. GitHub

1. Na https://github.com/new kreiraj prazan repozitorij, npr. `vila-izdajnika`. Nemoj dodavati README ni .gitignore u GitHub interfejsu.
2. Otvori terminal u folderu projekta (folder u kojem je `package.json`) i pokreni:

```powershell
git init
git add .
git commit -m "Initial Vila izdajnika V10 demo"
git branch -M main
git remote add origin https://github.com/TVOJ_USERNAME/vila-izdajnika.git
git push -u origin main
```

Ako Git kaže da `origin` već postoji, umjesto `git remote add` koristi `git remote set-url origin https://github.com/TVOJ_USERNAME/vila-izdajnika.git`.

**Ne objavljuj** `.env.local`, Supabase service-role/secret ključeve, lozinke ili privatne podatke. `.gitignore` već ignoriše `.env*` osim `.env.example`.

## 3. Vercel (javni link)

1. Idi na https://vercel.com/new i prijavi se GitHub računom.
2. Izaberi repozitorij `vila-izdajnika` i `Import`.
3. Framework: Next.js; Root Directory: folder s `package.json` (ako si sadržaj ovog ZIP-a direktno pushovao, to je root repozitorija).
4. Za sada ne trebaš Supabase environment varijable jer demo ne koristi bazu.
5. Klikni `Deploy`. Nakon uspješnog builda dobit ćeš adresu poput `https://vila-izdajnika-....vercel.app`.
6. Podijeli **Vercel link**, ne GitHub URL. Novi `git push` na `main` automatski pokreće novu produkcijsku objavu ako je integracija povezana.

## 4. Supabase — priprema baze (još nije integrisana)

1. Otvori https://supabase.com/dashboard i kreiraj projekat.
2. U `SQL Editor` napravi novi upit, zalijepi sadržaj `supabase/schema.sql` i klikni `Run`.
3. Provjeri da su tabele kreirane u `Table Editor`.
4. U `Project Settings` / `API` (ili `Connect`, zavisno od interfejsa) pronađi Project URL i publishable/anon key.
5. Kada kod stvarno bude koristio Supabase klijent, u Vercel Project > Settings > Environment Variables postavi:

```env
NEXT_PUBLIC_SUPABASE_URL=https://TVP_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=TVP_PUBLISHABLE_ILI_ANON_KEY
```

Ključeve ne unosi u GitHub kod. **Nikada** ne stavljaj `service_role` / secret key u `NEXT_PUBLIC_` varijable.

## 5. Šta treba implementirati za zajedničku online vilu

- Supabase Auth i korisnički profili, stvaranje i pridruživanje vili preko pozivnice.
- Server-authoritative game engine: faze, trajanje, izbor uloga, misije, fond, imunitet, glasanje, noćne eliminacije.
- Privatni podaci (uloge, privatne poruke, meta napada) dostupni isključivo ovlaštenim učesnicima; RLS i server-side RPC/API.
- Realtime događaji, javni chat, privatni razgovori, prisustvo i istovremeni potezi.
- Sigurno bodovanje misija na serveru i provjere protiv dvostrukog izvršavanja.
- Upravljanje AI učesnicima na serveru, bez otkrivanja skrivenih uloga klijentu.

**Ne dodavati široke SELECT politike na `game_players`**, jer ta tabela sadrži tajne uloge. Trenutna SQL shema namjerno ograničava pristup dok se ne implementiraju server-side pravila.

## 6. Česti problemi

- `npm run build` pada: prvo popraviti TypeScript/Next.js greške.
- Vercel ne nalazi `package.json`: pogrešan Root Directory.
- Nove promjene se ne vide: provjeriti deployment status i je li push na `main`.
- Prijatelji ne vide iste igrače/poruke: očekivano za V10; nema Supabase multiplayer integracije.
- Upozorenje o lockfileu iz korisničkog foldera: ne brisati naslijepo tuđe lockfileove; provjeriti projektnu konfiguraciju.
