# Vynora + Supabase: Online-Setup

## Aktueller Stand (8. November 2026)

Das Supabase-Projekt `vynora` ist über ChatGPT verbunden. Die Migrationen für private Nachrichten, Freunde, Server, Textkanäle und Blockierregeln sind auf diesem Projekt **erfolgreich ausgeführt**. Die entsprechenden SQL-Dateien stehen im Verzeichnis `supabase/migrations/`. Alle 10 Anwendungstabellen haben Row Level Security aktiviert.

Die öffentliche Browserkonfiguration in `supabase-config.js` ist mit der Vynora-Projekt-URL und einem **Publishable Key** verbunden. Das ist kein geheimer Service-Role-Schlüssel.

## App öffnen

- Vynora: https://silasnetwin.github.io/vynora/
- Ältere Offline-Demo: https://silasnetwin.github.io/vynora/demo.html

**GitHub Pages veröffentlicht Dateien.** Ein erfolgreiches Deployment allein beweist noch nicht, dass Registrierung und Live-Chat im Browser-Endtest funktionieren.

## Einmalig in Supabase prüfen

Öffne [Supabase Authentication URL Configuration](https://supabase.com/dashboard/project/nassqnkmuzuuuylelreh/auth/url-configuration) und stelle sicher, dass die Browser-App als erlaubtes Redirect-Ziel eingetragen ist:

`https://silasnetwin.github.io/vynora/**`

Den Site URL kannst du vorerst auf `https://silasnetwin.github.io/vynora/` setzen. Später auch die eigene Domain `app.vynora.me` ergänzen. Verifiziere im Supabase Dashboard, dass E-Mail/Passwort-Login unter Authentication → Providers aktiviert ist. Falls E-Mail-Bestätigung aktiv ist, muss jeder Testaccount seine E-Mail bestätigen.

## Realer Test

1. Registriere einen Testaccount A über die Vynora-Seite.
2. Registriere Account B über einen privaten Browser / zweiten Browser.
3. Lege für beide unter ⚙ ein eindeutiges `username` fest.
4. Suche B über „Freund hinzufügen“, sende eine Anfrage und nimm sie in B an.
5. Starte einen DM, sende Nachrichten, prüfe die Darstellung in beiden Browsern.
6. Erstelle mit A einen Server, kopiere mit ⤴ den Einladungscode, tritt mit B über ↪ bei, sende Kanalnachrichten.
7. Prüfe, dass ein dritter Nutzer ohne Einladung Servernachrichten nicht lesen kann und dass Blockieren DM-Senden verhindert.

## Sicherheit und Einschränkungen

- Nachrichten sind **nicht Ende-zu-Ende-verschlüsselt**.
- Vor öffentlicher Nutzung fehlen unter anderem Anti-Spam-Rate-Limits, Moderation, Reporting und Blockier-UI zum Entblocken.
- Funktionen mit `SECURITY DEFINER` wurden mit Auth-/Berechtigungsprüfungen implementiert. Supabase Security Advisor meldet für einige absichtlich erreichbare authentifizierte RPC-Funktionen Warnungen. Diese müssen vor einem öffentlichen Launch nochmals geprüft werden.
- Kein Sprach-/Videochat und noch keine vollständige Rechteverwaltung.
- Keine Secret Keys, Service-Role-Keys oder Passwörter in GitHub eintragen.

Weitere Details in [README.md](README.md).
