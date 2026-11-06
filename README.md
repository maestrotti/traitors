# Vila izdajnika V10 — privatni susreti, memorija i imunitet

Nadogradnja V9. Pokreni `npm install` i `npm run dev`, zatim otvori `http://localhost:3000`.

- Slučajni susret odmah otvara privatnog sagovornika u chatu; druga strana (AI) odgovara na poruku. Drugi učesnici vide samo da se razgovor dogodio.
- Prije dobrovoljnog odlaska na okrugli sto potrebno je poslati barem jednu privatnu poruku. Dostupan je i ručni izbor sagovornika.
- Memorija: prvo pojedinačno otkrivanje svake od 12 karata (po 1 sekundu, bez bodovanja), zatim igra u parovima s brojačem pokušaja.
- Imunitet: umjesto nasumičnog pehara, proučavaju se tri traga i donosi zaključak. Ovo je početna verzija logičkog izazova.
- Bijeli oblačići iznad učesnika imaju tamna slova.

Napomena: lokalni demo; AI koristi unaprijed pripremljene odgovore, ne jezički model. Ostatak ranijih igara i dalje je u demo obliku. Kompletan Next.js build nije potvrđen jer zavisnosti nisu instalirane u ovom okruženju.
