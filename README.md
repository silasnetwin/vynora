# ✦ Vynora — Discord-inspirierter Web-Messenger

**Status:** Funktionsfähige Entwickler-Vorschau, noch nicht produktionsreif und keine offizielle Discord-App.

## Öffnen

- **Web-App:** https://silasnetwin.github.io/vynora/
- **Alte Offline-Demo:** https://silasnetwin.github.io/vynora/demo.html
- **GitHub-Code:** https://github.com/silasnetwin/vynora

## Funktionen (November 2026)

- 3-Spalten-Layout: Serverleiste, DM-/Kanalnavigation, Nachrichten und Profil-/Mitgliederbereich
- Supabase Auth: Registrierung, Login, Bestätigungsmail erneut anfordern und Passwort-Recovery
- Profile mit Namen, Benutzernamen und Online-/Abwesend-/Nicht-stören-/Unsichtbar-Status
- Freunde: Suche, Anfragen senden, annehmen, ablehnen, zurückziehen, blockieren/entblockieren
- DMs und Server-Textkanäle: Nachrichten schreiben, bearbeiten und löschen
- Reaktionen: Emojis setzen/entfernen mit gespeicherten Zählerständen
- Server erstellen, Textkanäle erstellen, Einladungscode teilen und über Code beitreten
- Suche in derzeit geladenen Nachrichten, responsives Layout und Tastaturkürzel Strg+K
- Ungefährer Online-Status (Heartbeat statt lückenloser Realtime-Präsenz)
- Realtime-Events mit Polling-Fallback

## Technik

- **Frontend:** Eigenständiges HTML/CSS/JS in `index.html` und `cloud.html`, Styles in `assets/vynora-discordlike.css`
- **Deployment:** GitHub Pages für statische Dateien
- **Backend:** Supabase Auth, PostgreSQL, PostgREST, Realtime
- **Sicherheit:** 12 Anwendungstabellen mit RLS, eingeschränkte SQL-Tabellen- und Spaltenrechte, abgesicherte Server-/DM-RPCs
- **Migrationen:** 7 auf dem verbundenen Supabase-Projekt ausgeführte SQL-Migrationen in `supabase/migrations/`
- **Keys:** `supabase-config.js` enthält ausschließlich einen öffentlichen Publishable Key, niemals einen Service-Role-/Secret-Key
- Die ältere Rust-/SQLite-App ist ein getrenntes Desktop-Projekt; diese Webversion verwendet Supabase

## Wichtig: Auth-Weiterleitung korrigieren

Falls die Mail-Bestätigung nach `http://localhost:3000` weiterleitet, muss in **Supabase Dashboard → Authentication → URL Configuration** der Site URL geändert werden:

`https://silasnetwin.github.io/vynora/`

Und als Redirect URL muss die Vynora-Seite erlaubt sein:

`https://silasnetwin.github.io/vynora/**`

Das Projekt lässt sich später zusätzlich auf `app.vynora.me` umstellen. Änderungen an Supabase Auth URL Configuration müssen im Dashboard vorgenommen werden; die Repository-Dateien allein ändern diese Einstellung nicht.

## Realer Funktionstest

1. Konto A anmelden; Profilname wählen.
2. Mit zweitem Browser/Privatfenster Konto B erstellen und E-Mail bestätigen.
3. Account A sucht den Benutzernamen von B, sendet Anfrage; B akzeptiert.
4. DM erstellen, Nachrichten in beiden Fenstern senden, ändern, löschen und mit Emoji reagieren.
5. Server anlegen, Einladungscode teilen, mit B beitreten, Nachrichten in Kanälen austauschen.
6. Blockierung, Nachrichtenrechte und Sichtbarkeit mit separaten Testkonten überprüfen.

### Noch nicht enthalten

Sprach- und Videoanrufe, Medien-Uploads, Rollen-/Rechtesystem wie Discord, Threads, Erwähnungen, Bildschirmfreigabe, Push-Benachrichtigungen und vollständige öffentliche Moderation. Keine Ende-zu-Ende-Verschlüsselung. Ein vollständiger manueller Zwei-Account-Browser-Endtest ist noch offen.

**Sicherheit:** Supabase meldet Warnungen für einige bewusst an angemeldete Nutzer freigegebene `SECURITY DEFINER`-RPCs sowie für die optionale Erkennung kompromittierter Passwörter. Die Anwendung benötigt vor öffentlichem Launch weitere Sicherheits- und Missbrauchstests sowie Rate-Limits.

Unabhängiges Projekt; verwendet eigene Marke und keine proprietären Discord-Grafiken.
