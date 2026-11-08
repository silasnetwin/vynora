# ✦ Vynora — Messenger (Preview)

Vynora ist ein eigenständiger, Discord-inspirierter Browser-Messenger mit eigenem Namen, eigener Oberfläche und Supabase/PostgreSQL als Backend.

## Starten

**[Vynora im Browser](https://silasnetwin.github.io/vynora/)** (vorausgesetzt GitHub Pages ist für den Branch `main` aktiv).

Die erste, rein lokale Test-Demo steht weiterhin unter [demo.html](https://silasnetwin.github.io/vynora/demo.html).

## Eingebaute Funktionen

- Supabase Auth: E-Mail/Passwort Registrierung und Anmeldung
- Profile: Anzeigename und eindeutige Benutzernamen
- Freunde suchen, Freundschaftsanfragen senden, annehmen und ablehnen
- Privatnachrichten mit PostgreSQL und Realtime-Updates (zusätzlicher Polling-Fallback)
- Kontakte blockieren, Server und Textkanäle erstellen
- Einladungscodes teilen, Communities beitreten und Kanalnachrichten schreiben
- Responsive Dark-Mode-App mit Servernavigation, Freunden, DMs und Profilansicht
- Row Level Security für alle 10 Anwendungstabellen

## Architektur

- **Frontend:** Statisches HTML/CSS/JavaScript in `index.html` (auch in `cloud.html`).
- **Hosting:** GitHub Pages; später mögliche eigene Domain `app.vynora.me`.
- **Backend:** Supabase Auth, PostgreSQL (10 Anwendungstabellen), Row Level Security, Postgres Changes Realtime.
- **Browser-Konfiguration:** `supabase-config.js` enthält ausschließlich die öffentliche Project URL und den Publishable Key, **keine Secrets**.
- **SQL-Migrationen:** `supabase/migrations/` enthält die drei auf dem Projekt `vynora` ausgeführten SQL-Migrationen.
- **Altes Prototyp-Projekt:** Rust + SQLite ist ein separater Desktop-Ansatz; der Web-Client verwendet derzeit kein Rust.

## Testen

1. Öffne die Vynora-Seite, registriere dich mit einer E-Mail-Adresse und bestätige sie, falls Supabase das verlangt.
2. Ändere unter ⚙ Einstellungen den automatisch angelegten Benutzernamen in einen kurzen Namen.
3. Registriere einen zweiten Testaccount in einem anderen Browser oder Privatfenster.
4. Suche den zweiten Nutzernamen über **Freund hinzufügen**, sende eine Anfrage und nimm sie im zweiten Konto an.
5. Starte einen DM, sende Nachrichten und überprüfe die Synchronisierung.
6. Erstelle einen Server (＋), kopiere seinen Einladungscode (⤴) und tritt mit einem anderen Konto über ↪ bei.

**Wichtig:** Wenn die Bestätigungs-E-Mail zurück zur falschen URL leitet, muss in Supabase unter Authentication → URL Configuration die richtige GitHub Pages URL als Redirect erlaubt sein, z. B. `https://silasnetwin.github.io/vynora/**`.

## Was noch fehlt

Dies ist noch **keine fertige Discord-Alternative**. Es fehlen unter anderem Sprach- und Videochat, Uploads, Rollen und Berechtigungen, Push-Benachrichtigungen, vollständige Moderation, Suche, Barrierefreiheit-Tests, Rate Limits und umfangreiche Last-/Sicherheitstests. Nachrichten sind noch nicht Ende-zu-Ende-verschlüsselt; verwende die Vorschau nicht für vertrauliche Unterhaltungen.

Das Projekt ist unabhängig und nicht mit Discord verbunden. Für einen öffentlichen Launch sind zusätzliche Schutzfunktionen nötig.
