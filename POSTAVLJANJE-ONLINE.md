# Vila izdajnika – online čekaonica (MVP)

## 1. Supabase

1. Otvori https://supabase.com/dashboard i kreiraj projekat (ili koristi postojeći).
2. Authentication → Providers → Anonymous Sign-ins: **Enable**. Ovo je gost-prijava, bez emaila. Za javnu produkciju treba dodati CAPTCHA/rate limiting i moderaciju.
3. SQL Editor → New query → zalijepi **cijeli** `supabase/online_mvp.sql` → Run. Ovaj SQL dodaje zasebne `online_*` tabele i RPC funkcije; ne briše stari demo schema.sql.
4. Project Settings → API (ili Connect) → kopiraj **Project URL** i **publishable/anon key**. Nikada ne stavljaj `service_role` ili `secret` key u `NEXT_PUBLIC_...`.

## 2. Lokalno

Kopiraj `.env.example` u `.env.local`, unesi URL i javni ključ. Pokreni `npm install` i `npm run dev`, pa idi na `http://localhost:3000/online`.

## 3. GitHub / Vercel

Raspakuj projekat preko postojećeg foldera `traitors` (sačuvaj svoj rad prije zamjene).

```powershell
cd C:\Users\t.nihad\Desktop\traitors
npm install
npm run build
git add .
git commit -m "Online vila: Supabase lobby i chat"
git push origin main
```

U Vercel → Project `traitors` → Settings → Environment Variables dodaj:

- `NEXT_PUBLIC_SUPABASE_URL` = Supabase Project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` = Supabase publishable/anon key

Dodaj ih za Production (i Preview po želji). Zatim **Redeploy** posljednji deployment (ili napravi novi commit) jer se NEXT_PUBLIC vrijednosti ugrađuju tokom builda.

Otvori `https://traitors-psi.vercel.app/online`. Kreiraj vilu, kopiraj pozivni link i pošalji prijatelju. Prijatelj upiše ime i klikne „Pridruži se vili“.

## 4. Šta zaista radi

- Zajednička soba u Supabase bazi, jedinstven kod i pozivni link.
- Više stvarnih igrača s različitih uređaja.
- Zajednički javni chat (osvježava se svake 2,5 sekunde).
- Lista članova, spremnost, domaćin može označiti sobu kao pokrenutu kad su svi spremni i ima najmanje 2 igrača.
- Pristup podacima kroz provjerene SQL funkcije; tajne uloge nisu izložene.

## 5. Šta još NE radi

- Misije, fond, tajne uloge, glasanje, noćna eliminacija i AI igrači iz V10 **nisu** povezani na online sobu.
- Privatni chat i kompletan gameplay nisu multiplayer.
- Nema automatskog uklanjanja neaktivnih korisnika, moderacije, ni ograničavanja poruka po brzini.
- Gost-prijava vezana je za sesiju preglednika; brisanjem podataka može se izgubiti identitet.

**Sigurnost:** Nemoj javno objavljivati servisni ključ. Prije velikog javnog lansiranja dodati autentifikaciju, anti-spam, provjere kapaciteta i ograničenja poziva.
