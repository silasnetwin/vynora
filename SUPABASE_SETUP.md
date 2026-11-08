# Vynora Cloud: Supabase einrichten

**Stand (8. November 2026):** Der Web-Code und die SQL-Migration liegen auf GitHub. **Die Migration wurde noch nicht auf dein Supabase-Projekt ausgeführt.** Die ChatGPT-Supabase-Verbindung kann das Projekt aus deinem Screenshot derzeit nicht abrufen (fehlende Berechtigung). Bitte verbinde die Supabase-App in ChatGPT mit dem Konto/Workspace, das bzw. der das Projekt `vynora` enthält.

## Schritt 1 – Supabase verbinden

Öffne ChatGPT → Einstellungen → Plugins → Supabase. Prüfe, ob die Verbindung zum gleichen Supabase-Konto gehört wie dein Vynora-Projekt, und aktualisiere ggf. die Verbindung. Du brauchst **kein zweites Projekt** anzulegen. Die Anzeige "GitHub: No repository connected" im Supabase-Dashboard blockiert die Messenger-Funktion nicht.

## Schritt 2 – SQL anwenden

Prüfe die Migration unter [supabase/migrations/202611080001_vynora_private_messaging.sql](supabase/migrations/202611080001_vynora_private_messaging.sql). Führe sie erst auf dem gewünschten neuen Projekt aus (direkt nach Verbindungsfreigabe per ChatGPT-Supabase oder im SQL Editor). Sie erstellt `profiles`, `conversations`, `conversation_members`, `messages`, einen Auth-Trigger, sichere DM-RPCs, Zugriffspolicies und Realtime-Publication.

**Sicherheit:** Row Level Security (RLS) ist für alle öffentlichen Tabellen aktiviert. Nachrichten sind nur für Chatmitglieder lesbar. Der Prototyp hat noch keine Freundschaftsanfragen, Spam-Abwehr, Blockier-/Melde-Funktion oder Ende-zu-Ende-Verschlüsselung.

## Schritt 3 – Browser-Konfiguration

1. Supabase-Dashboard → Projekt `vynora` → Project Settings → API Keys.
2. Kopiere **Project URL** und den **Publishable Key** (beginnt üblicherweise mit `sb_publishable_`) in `supabase-config.js`.
3. Veröffentliche nur diesen öffentlichen Schlüssel. **Niemals** die Secret-/Service-Role-Keys, Datenbankpasswörter oder Tokens auf GitHub speichern.
4. Authentication → URL Configuration: Setze Site URL und erlaubte Redirect URL z. B. `https://silasnetwin.github.io/vynora/cloud.html`. Bei der späteren eigenen Domain dort auch die echte Vynora-URL freigeben.
5. E-Mail/Passwort-Login muss unter Authentication → Providers aktiviert sein. Bei aktivierter Mailbestätigung müssen Testaccounts die E-Mail bestätigen.

## Schritt 4 – Test mit zwei Konten

1. Öffne `cloud.html` über GitHub Pages / eine HTTPS-Domain.
2. Erstelle Account A; bestätige die E-Mail falls nötig.
3. Wähle im Seitenpanel einen leicht auffindbaren Nutzernamen (Kleinbuchstaben, Zahlen, `_` und `.`, 3–32 Zeichen).
4. Erstelle Account B in einem zweiten Browser / Privatfenster und gib dort einen anderen Benutzernamen ein.
5. Suche auf Account A nach Account B, beginne einen Chat und sende eine Nachricht.
6. Prüfe, ob Account B die Nachricht sieht, antworten kann und ob andere Accounts die Nachricht *nicht* lesen können.

Die Cloud-App speichert echte Nachrichten in Supabase PostgreSQL, nicht in SQLite. GitHub Pages hostet nur HTML, CSS und JavaScript. Für Realtime ist eine Postgres-Changes-Subscription vorgesehen; bei Verbindungsproblemen fragt die App im Abstand von zehn Sekunden ab.

## Grenzen

Keine Server- oder Sprachkanäle in der Cloud-Version. Es handelt sich um ein Experiment, das vor einem breiteren öffentlichen Start weitere Privacy- und Abuse-Sicherungen sowie echte Browser-/Auth-Tests braucht.

Mehr Infos: [README.md](README.md).
