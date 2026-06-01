# Mini-IDP Skelett – Schulungsrepo

Dieses Repository ist ein **Template-Repo** fuer eine Schulung zum Thema "Internal Developer Platform (IDP) mit GitHub-Bordmitteln". Es demonstriert, wie Self-Service-Workflows mit GitHub Issue Forms und GitHub Actions umgesetzt werden koennen – ganz ohne externe Tools oder Infrastruktur.

Teilnehmer nutzen dieses Skelett als Ausgangspunkt und implementieren darauf basierend eigene Self-Service-Use-Cases.

---

## Lernziele

Nach der Uebung koennt ihr:

1. Drei Komponenten eines IDP konkret benennen (Portal, Self-Service, Automatisierung).
2. Den Unterschied zwischen *Plattform* und *Portal* erklaeren.
3. Einen einfachen Self-Service-Workflow mit GitHub-Bordmitteln umsetzen.

---

## Was ist hier ein IDP?

Eine **Internal Developer Platform** (IDP) ist eine Sammlung von Werkzeugen und Workflows, die Entwicklungsteams Self-Service-Zugang zu Infrastruktur und Prozessen gibt – ohne dass jedes Mal ein Plattform-Team manuell eingreifen muss. In dieser Schulung setzen wir eine vereinfachte Variante um: GitHub Issues dienen als **Portal** (Eingabeformular fuer Anfragen), GitHub Actions als **Plattform-Logik** (automatisierte Verarbeitung). Das ist kein vollwertiges Backstage oder Humanitec, aber es vermittelt die Kernidee: Standardisierte Schnittstellen ersetzen Tickets und manuelle Arbeit.

**Plattform vs. Portal:** Die Plattform ist der Motor (Workflows, APIs, Infrastruktur-Code). Das Portal ist das Dashboard (UI, Formulare, Katalog). In unserer Uebung ist das Issue-Formular das Portal und der GitHub Actions Workflow die Plattform.

---

## Phase 1 – Recherche (20 Min)

Lest **eine** der beiden Quellen:

- Google Cloud: <https://cloud.google.com/discover/what-is-an-internal-developer-platform?hl=de>
- Red Hat: <https://www.redhat.com/de/topics/platform-engineering/what-is-an-internal-developer-platform>

**Sucht beim Lesen gezielt nach:**

- **Was sind "Golden Paths"?**
- **Welche Self-Service-Aktionen tauchen als Beispiele auf?**

**Ergaenzend (optional, max. 5 Min):** Eine Live-Demo oeffnen und 3 Self-Service-Aktionen identifizieren:
- <https://demo.port.io/self-serve>
- <https://demo.backstage.io>

Notiert/Merkt euch 3 Use Cases, die ihr in echt gesehen habt. Welche Eingaben braucht der User? Was passiert dahinter?

---

## Phase 2 – Use Case auswaehlen (5 Min)

Waehlt **einen** Use Case zur Umsetzung. Vier Optionen:

| Option | Beschreibung | Komplexitaet |
|--------|-------------|--------------|
| A | Neuen Service registrieren | niedrig |
| B | Repo-Einladung | mittel |
| C | S3-Bucket per Terraform-Template rendern | mittel-hoch |
| D | Doku-Vorlage anfordern (Erweiterung des Beispiels) | niedrig |

Details zu jedem Use Case findet ihr in [EXERCISES.md](EXERCISES.md).

---

## Phase 3 – Aufsetzen & Implementieren (50 Min)

### Schritt 1: Skelett-Repo nutzen (5 Min)

1. **"Use this template"** oben rechts klicken und ein eigenes Repository erstellen.
2. Namen vergeben (z.B. `mini-idp-<euerName>`).
3. Public oder Private – egal fuer die Uebung.
4. Eigenes Repo oeffnen.

### Schritt 2: Workflow-Permissions aktivieren (2 Min)

1. **Settings** → **Actions** → **General**.
2. Scrollt zu "Workflow permissions".
3. **"Read and write permissions"** auswaehlen.
4. Checkbox **"Allow GitHub Actions to create and approve pull requests"** aktivieren.
5. **Save** klicken.

Ohne diesen Schritt kann kein Workflow Dateien committen oder Issues kommentieren.

### Schritt 3: Labels anlegen (3 Min) – PFLICHT

**Wichtig:** Beim "Use this template" werden **keine Labels mitkopiert** (Labels
sind Repo-Metadaten, kein Git-Inhalt). Der Beispiel-Workflow triggert aber auf
dem Label `doku-request` und vergibt am Ende `completed` bzw. `invalid-input`.
Fehlen diese Labels, **startet der Workflow gar nicht** oder bricht beim
Label-Setzen ab.

Legt daher diese vier Labels **vor dem ersten Test** an
(Issues → Labels → New label):

| Label | Zweck |
|---|---|
| `doku-request` | Trigger fuer den Beispiel-Workflow |
| `automation` | Kennzeichnung automatisierter Issues |
| `completed` | wird nach Erfolg gesetzt |
| `invalid-input` | wird bei ungueltiger Eingabe gesetzt |

Schneller per GitHub CLI (falls lokal vorhanden):
```bash
gh label create doku-request --color 1d76db
gh label create automation   --color 0e8a16
gh label create completed    --color 5319e7
gh label create invalid-input --color d93f0b
```

### Schritt 4: Beispiel testen (5 Min)

Bevor ihr eigenes baut: erlebt das Beispiel.

1. **Issues** → **New Issue** → "Doku-Vorlage anfordern" waehlen.
2. Felder ausfuellen (Service-Name z.B. `mein-test-service`).
3. **Submit new issue**.
4. Pruefen, dass am Issue das Label `doku-request` haengt (sonst startet der Workflow nicht).
5. **Actions**-Tab oeffnen → Workflow laeuft.
6. Wenn fertig: in `generated-docs/` neue Datei pruefen, Kommentar im Issue pruefen.

Wenn das nicht funktioniert: `docs/TROUBLESHOOTING.md` konsultieren.

### Schritt 5: Eigenen Use Case umsetzen (30 Min)

Folgt [EXERCISES.md](EXERCISES.md) fuer euren gewaehlten Use Case (A/B/C/D).

Kurzanleitung:
1. Issue Form anlegen: kopiert `example-doc-request.yml`, benennt um, passt Felder an.
2. Workflow anlegen: kopiert `example-doc-handler.yml`, benennt um, passt Logik an.
3. Fuer euren Use Case benoetigte Labels anlegen (analog Schritt 3).
4. Testen wie in Schritt 4.

### Schritt 6: Akzeptanzkriterien pruefen (5 Min)

Euer Mini-IDP funktioniert, wenn:
- Ein Issue kann ueber das Formular erstellt werden.
- Der Workflow laeuft automatisch nach Issue-Erstellung.
- Es entsteht ein sichtbares Ergebnis (Datei, PR, oder Kommentar) im Repo.
- Das Issue wird automatisch geschlossen oder mit einem Label markiert.

---

## Stolpersteine, die typisch auftreten

| Problem | Loesung |
|---|---|
| Workflow laeuft nicht, kein Trigger | `on:` im Workflow falsch. Muss `on: issues: types: [opened]` sein. |
| Workflow startet nicht, obwohl Issue da ist | Label `doku-request` fehlt im Repo und wird daher nicht gesetzt. Labels anlegen (Schritt 3). |
| Workflow bricht beim Label-Setzen ab | Label `completed`/`invalid-input` existiert nicht. Labels anlegen (Schritt 3). |
| Workflow laeuft, kann aber nicht schreiben | Settings → Actions → General → Read and write permissions aktivieren. |
| YAML-Fehler im Issue Form | Indentation! YAML ist whitespace-sensitive. Cheatsheet konsultieren. |
| Formular taucht nicht im Issue-Chooser auf | Datei muss in `.github/ISSUE_TEMPLATE/` liegen, Endung `.yml`, valide YAML. |
| Workflow laeuft mehrmals | Bei mehreren Workflows mit gleichem Trigger: Filter via `if:` oder Labels. |
