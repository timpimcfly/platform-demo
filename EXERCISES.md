# Uebungen – Mini-IDP mit GitHub bauen

In diesem Dokument findet ihr alle Anleitungen fuer die praktische Uebung. Waehlt
**einen** Use Case (A, B, C oder D) und arbeitet ihn durch.

---

## Vorab: Workflow-Permissions aktivieren

**Dieser Schritt ist Voraussetzung fuer ALLE Use Cases. Macht das als erstes,
sonst laeuft kein Workflow.**

1. Geht in eurem Repo auf **Settings** (oben rechts).
2. Linke Sidebar: **Actions** → **General**.
3. Scrollt nach unten zu "Workflow permissions".
4. Waehlt **"Read and write permissions"**.
5. Aktiviert zusaetzlich die Checkbox **"Allow GitHub Actions to create and approve pull requests"**.
6. Klickt **Save**.

Ohne diesen Schritt kann der Workflow keine Dateien committen und keine Issues kommentieren.

---

## Vorab: Labels anlegen

**Ebenfalls Voraussetzung fuer ALLE Use Cases.** Beim "Use this template" werden
**keine Labels mitkopiert** – ein neues Repo hat nur die GitHub-Standard-Labels.
Die Workflows triggern aber auf Labels (z.B. `doku-request`) und vergeben
Status-Labels (z.B. `completed`). Fehlen sie, **startet der Workflow nicht** oder
bricht beim Setzen des Labels ab.

Legt fuer das Beispiel (Use Case D) diese vier Labels an
(**Issues → Labels → New label**):

| Label | Zweck |
|---|---|
| `doku-request` | Trigger fuer den Beispiel-Workflow |
| `automation` | Kennzeichnung automatisierter Issues |
| `completed` | wird nach Erfolg gesetzt |
| `invalid-input` | wird bei ungueltiger Eingabe gesetzt |

Schneller per GitHub CLI:
```bash
gh label create doku-request --color 1d76db
gh label create automation   --color 0e8a16
gh label create completed    --color 5319e7
gh label create invalid-input --color d93f0b
```

**Fuer eure eigenen Use Cases (A/B/C):** legt die dort verwendeten Labels
(z.B. `service-register`, `access-request-pending`, `tf-pending-review`) genauso
vorab an, bevor ihr testet.

---

## Beispiel: Use Case D ist schon umgesetzt

Bevor ihr loslegt, lauft das mitgelieferte Beispiel einmal durch. Damit versteht
ihr das Muster, das ihr fuer eure eigene Implementierung uebernehmt.

**Was passiert:**
Ein Issue Form fragt nach Service-Name, Owner, Beschreibung und Umgebung. Nach
Submitten erzeugt ein Workflow eine fertige Markdown-Doku-Datei aus einer
Vorlage, committet sie ins Repo und kommentiert das Issue.

**Beteiligte Dateien:**

| Datei | Funktion |
|---|---|
| `.github/ISSUE_TEMPLATE/example-doc-request.yml` | Das Formular |
| `.github/workflows/example-doc-handler.yml` | Der Workflow |
| `templates/doc-template.md` | Die Markdown-Vorlage mit Platzhaltern |
| `generated-docs/` | Hier landet das Ergebnis |

**Testlauf:**
1. **Issues** → **New Issue** → "Doku-Vorlage anfordern" waehlen.
2. Felder ausfuellen (Service-Name z.B. `mein-test-service`).
3. **Submit new issue**.
4. Pruefen, dass am Issue das Label `doku-request` haengt – nur dann startet der Workflow.
5. **Actions**-Tab oeffnen → Workflow laeuft.
6. Wenn fertig: in `generated-docs/` neue Datei pruefen, Kommentar im Issue pruefen.

Wenn das nicht funktioniert: Workflow-Permissions wirklich aktiviert? Labels
angelegt (siehe "Vorab: Labels anlegen")? `docs/TROUBLESHOOTING.md` konsultieren.

---

## Grundrezept: So baust du JEDEN Use Case

Alle vier Use Cases folgen demselben Muster. Wenn du dieses Grundrezept
verstanden hast, musst du in den Use Cases nur noch die Details austauschen.
Du brauchst **immer genau zwei Dateien**: ein Formular und einen Workflow.

> **Wichtiger Tipp:** Erfinde nichts neu. Kopiere die beiden Beispiel-Dateien,
> benenne sie um und aendere nur die markierten Stellen. Fang mit einer
> Minimalversion an (Formular + Kommentar) und baue erst dann den Rest ein.

### Baustein 1 – Das Formular (`.github/ISSUE_TEMPLATE/<name>.yml`)

Kopiervorlage. Tausche `label`, `id` und die Felder aus:

```yaml
name: "Mein Formular"
description: "Was dieses Formular macht"
title: "[Mein-Prefix] "
labels: ["mein-label"]      # <-- merke dir dieses Label, der Workflow filtert darauf
body:
  - type: input
    id: feld_eins           # <-- frei waehlbar, brauchst du spaeter zum Parsen
    attributes:
      label: "Feld Eins"    # <-- daraus wird im Issue-Body "### Feld Eins"
    validations:
      required: true
  - type: dropdown
    id: umgebung
    attributes:
      label: "Umgebung"
      options: [dev, staging, prod]
    validations:
      required: true
```

Merke: Aus jedem `label:` wird im Issue-Body eine Ueberschrift `### Feld Eins`.
Genau diese Ueberschrift benutzt der Workflow zum Auslesen.

### Baustein 2 – Trigger + Berechtigungen (Kopf jedes Workflows)

```yaml
name: "Mein Workflow"
on:
  issues:
    types: [opened]
permissions:
  contents: write
  issues: write
jobs:
  job:
    if: contains(github.event.issue.labels.*.name, 'mein-label')   # <-- Label aus dem Formular
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
```

### Baustein 3 – Ein Feld aus dem Issue auslesen

Diese Hilfsfunktion holt den Wert unter einer `### Ueberschrift`. Genau so steht
sie im Beispiel-Workflow (Schritt "Issue-Body parsen"):

```yaml
      - name: Felder lesen
        id: parse
        env:
          ISSUE_BODY: ${{ github.event.issue.body }}   # <-- Issue-Text sicher als Variable
        run: |
          extract_field() {
            echo "$ISSUE_BODY" | sed -n "/### $1/,/### /{/### $1/d;/### /d;p;}" | sed '/^$/d' | head -1
          }
          echo "feld_eins=$(extract_field 'Feld Eins')" >> "$GITHUB_OUTPUT"
          echo "umgebung=$(extract_field 'Umgebung')" >> "$GITHUB_OUTPUT"
```

Danach nutzt du die Werte in spaeteren Schritten als `${{ steps.parse.outputs.feld_eins }}`.

### Baustein 4 – Werte SICHER weiterverwenden

**Goldene Regel:** Werte aus dem Issue niemals direkt mit `${{ ... }}` in eine
`run:`-Zeile schreiben. Immer ueber `env:` reichen und als `"$VAR"` benutzen.
Sonst koennte ein boeser Issue-Text Befehle ausfuehren.

```yaml
      - name: Etwas tun
        env:
          FELD_EINS: ${{ steps.parse.outputs.feld_eins }}   # <-- ueber env, nicht inline
        run: |
          echo "Wert ist: $FELD_EINS"        # richtig
          # echo "Wert ist: ${{ steps.parse.outputs.feld_eins }}"   # FALSCH/unsicher
```

### Baustein 5 – Issue kommentieren, labeln, schliessen

```yaml
      - name: Issue abschliessen
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ISSUE_NUMBER: ${{ github.event.issue.number }}
        run: |
          gh issue comment "$ISSUE_NUMBER" --body "Erledigt."
          gh issue edit "$ISSUE_NUMBER" --add-label "completed"   # Label muss existieren!
          gh issue close "$ISSUE_NUMBER" --reason "completed"
```

Mehr Bausteine (PR erstellen, Datei committen) findest du in
`docs/CHEATSHEET-actions.md`. Ab hier brauchst du in den Use Cases nur noch
festlegen, **was** zwischen Baustein 3 und 5 passiert.

---

## Use Case A: Neuen Service registrieren

### Was soll passieren

Ein Entwickler legt einen neuen Service an und meldet ihn im "Service Catalog"
des Unternehmens an. Statt eine Wiki-Seite manuell zu pflegen, fuellt er ein
Formular aus. Der Catalog ist eine Sammlung von YAML-Dateien im `catalog/`-Ordner.

### Eingabefelder

| Feld | Typ | Pflicht | Validierung |
|---|---|---|---|
| `service_name` | input | ja | nur lowercase, Bindestriche, 3–40 Zeichen |
| `owner` | input | ja | GitHub-Username (`@xy` oder `xy`) |
| `repo_url` | input | ja | beginnt mit `https://github.com/` |
| `environment` | dropdown | ja | dev / staging / prod |
| `description` | textarea | nein | freier Text |

### Was der Workflow tun soll

1. Issue-Body parsen.
2. Eine neue Datei `catalog/<service_name>.yml` anlegen mit folgender Struktur:
```yaml
service: <name>
owner: <owner>
repo: <repo_url>
environment: <env>
description: <desc>
created_at: <ISO-Datum>
created_by: <issue-author>
```
3. Datei committen (direkt auf `main`).
4. Issue kommentieren: "Service registriert: `catalog/<name>.yml`".
5. Issue mit Label `service-registered` markieren und schliessen.

### Schritt fuer Schritt

1. **Formular** anlegen (`.github/ISSUE_TEMPLATE/register-service.yml`) –
   nimm Baustein 1 aus dem Grundrezept, Felder: `service_name`, `owner`,
   `repo_url`, `environment`. Setze `labels: ["service-register"]`.
2. **Label anlegen:** `service-register` und `service-registered` unter
   Issues → Labels erstellen (sonst triggert/labelt der Workflow nicht).
3. **Workflow** anlegen (`.github/workflows/register-service.yml`) – nimm
   Bausteine 2–5, filtere auf `service-register`, lies die vier Felder (Baustein 3).
4. Zwischen Parsen und Abschluss die YAML-Datei schreiben (siehe Hilfe unten).
5. **Test:** neues Issue erstellen, dann pruefen: Datei in `catalog/` da?
   Kommentar im Issue? Label gesetzt?

### Konkrete Hilfe (zum Kopieren)

So schreibst du die Katalog-Datei – Werte sicher ueber `env`, kein `sed` noetig:

```yaml
      - name: Katalogeintrag schreiben
        env:
          SERVICE_NAME: ${{ steps.parse.outputs.service_name }}
          OWNER: ${{ steps.parse.outputs.owner }}
          REPO_URL: ${{ steps.parse.outputs.repo_url }}
          ENVIRONMENT: ${{ steps.parse.outputs.environment }}
          AUTHOR: ${{ github.event.issue.user.login }}
        run: |
          # Sicherheits-Check fuer den Dateinamen (kein Path-Traversal)
          [[ "$SERVICE_NAME" =~ ^[a-z][a-z0-9-]+$ ]] || { echo "ungueltiger Name"; exit 1; }
          cat > "catalog/${SERVICE_NAME}.yml" <<EOF
          service: ${SERVICE_NAME}
          owner: ${OWNER}
          repo: ${REPO_URL}
          environment: ${ENVIRONMENT}
          created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
          created_by: ${AUTHOR}
          EOF
```

Den Commit-/Kommentar-/Schliessen-Teil kopierst du direkt aus dem
Beispiel-Workflow (Schritte 5–7).

### Fang klein an

Bau zuerst nur: Formular + Workflow, der das Issue mit "Hallo" kommentiert
(Baustein 5). Wenn das laeuft, ergaenze das Datei-Schreiben. So findest du Fehler
frueh statt am Ende alles auf einmal.

### Stretch-Goals

- Validierung im Workflow: lehnt Service ab, wenn `catalog/<name>.yml` schon existiert.
- Liste aller Services in einer `catalog/README.md` automatisch aktualisieren.

---

## Use Case B: Repo-Einladung

### Was soll passieren

Ein Plattform-Nutzer moechte einer Person Zugriff auf ein bestimmtes Repo geben
(z.B. neues Teammitglied, externer Berater). Statt direkt im Repo zu klicken,
stellt er die Anfrage ueber ein Formular. Das hat zwei Effekte:
- Es ist nachvollziehbar (Audit-Trail im Issue).
- Ein Plattform-Admin kann die Anfrage pruefen, bevor sie ausgefuehrt wird.

### Wichtige Klaerung: Mock vs. Echt

Ein echter API-Call zum Hinzufuegen eines Collaborators braucht einen Personal
Access Token mit `admin:org` oder `repo`-Rechten. Das geht in der Schulung nicht
sauber aus dem Workflow heraus. Wir machen daher die **Mock-Variante**: Der
Workflow erzeugt einen Issue-Kommentar mit einer fertigen Anweisung fuer den
Plattform-Admin (vier Augen ist eh besser).

Wer mit eigenem Repo + PAT arbeiten will: siehe Stretch-Goals am Ende.

### Eingabefelder

| Feld | Typ | Pflicht | Validierung |
|---|---|---|---|
| `github_username` | input | ja | GitHub-Username (kein `@`, nur Buchstaben/Ziffern/Bindestriche) |
| `target_repo` | input | ja | Format `owner/repo` |
| `permission` | dropdown | ja | read / triage / write / maintain |
| `reason` | textarea | ja | warum braucht diese Person Zugriff |
| `expires` | dropdown | ja | 7 Tage / 30 Tage / unbegrenzt |

### Was der Workflow tun soll

1. Issue-Body parsen.
2. Issue kommentieren mit einem "Approval-Block":
```
## Zugriffsanfrage zur Freigabe

- Benutzer: @<username>
- Repo: <target_repo>
- Berechtigung: <permission>
- Befristung: <expires>
- Begruendung: <reason>

**An den Plattform-Admin:** Bitte mit Label `approved` markieren,
um die Anfrage als genehmigt zu kennzeichnen.
```
3. Issue mit Label `access-request-pending` markieren.
4. Issue NICHT schliessen (wartet auf Approval-Label).

### Schritt fuer Schritt

1. **Formular** anlegen (`.github/ISSUE_TEMPLATE/request-access.yml`) –
   Baustein 1, Felder: `github_username`, `target_repo`, `permission`, `reason`,
   `expires`. Setze `labels: ["access-request"]`.
2. **Label anlegen:** `access-request` und `access-request-pending`.
3. **Workflow** anlegen (`.github/workflows/request-access.yml`) – Bausteine 2–3,
   dann den Kommentar schreiben (Hilfe unten). Issue NICHT schliessen.
4. **Test:** Issue erstellen, Kommentar pruefen, Label `access-request-pending` pruefen.

Dieser Use Case ist bewusst einfach: **kein Datei-Commit**, nur Kommentar + Label.

### Konkrete Hilfe (zum Kopieren)

```yaml
      - name: Freigabe-Kommentar schreiben
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ISSUE_NUMBER: ${{ github.event.issue.number }}
          USERNAME: ${{ steps.parse.outputs.github_username }}
          TARGET_REPO: ${{ steps.parse.outputs.target_repo }}
          PERMISSION: ${{ steps.parse.outputs.permission }}
        run: |
          gh issue comment "$ISSUE_NUMBER" --body "## Zugriffsanfrage zur Freigabe

          - Benutzer: @${USERNAME}
          - Repo: ${TARGET_REPO}
          - Berechtigung: ${PERMISSION}

          **An den Plattform-Admin:** Bitte mit Label \`approved\` markieren."
          gh issue edit "$ISSUE_NUMBER" --add-label "access-request-pending"
```

### Fang klein an

Erst nur das Formular + ein fester Kommentar ("Anfrage erhalten"). Wenn das
laeuft, baue die echten Felder in den Kommentar ein.

### Stretch-Goals

- **Approval-Workflow**: zweiter Workflow, der auf das Setzen des Labels
  `approved` triggert (`on: issues: types: [labeled]`), kommentiert "Anfrage
  genehmigt" und schliesst das Issue.
- **Echter API-Call** (nur mit eigenem Repo + Personal Access Token):
  Token als Repo-Secret `PLATFORM_TOKEN` hinterlegen, Workflow ruft
  `gh api -X PUT /repos/<owner>/<repo>/collaborators/<user>` auf.
  Warnung: Token-Handling ist sicherheitskritisch; tut das nur in Test-Repos.

### Stolpersteine

- Wenn das `expires`-Feld eine Befristung verlangt, aber der Workflow nichts
  damit tut: in echt muesste ein Scheduler den Zugriff entziehen. Das ist in
  unserer Mock-Variante nicht umgesetzt – als Diskussionspunkt fuer die
  Abschluss-Demo parkieren.

---

## Use Case C: S3-Bucket per Terraform-Template rendern

### Was soll passieren

Ein Entwickler braucht einen S3-Bucket. Statt selbst Terraform-Code zu schreiben,
fuellt er ein Formular aus. Der Workflow nimmt das vorhandene TF-Template aus
`templates/terraform-s3-snippet.tf`, ersetzt die Platzhalter mit den
Formular-Inputs und erzeugt eine fertige `.tf`-Datei als Pull Request. Ein
Plattform-Admin reviewed den PR.

**Wichtig:** Es findet **kein** `terraform apply` statt. Wir generieren nur Code.
Das ist auch in echten IDPs ein ueblicher Zwischenschritt – Code-Review vor Deployment.

### Eingabefelder

| Feld | Typ | Pflicht | Validierung |
|---|---|---|---|
| `bucket_name` | input | ja | lowercase, 3–63 Zeichen, Bindestriche erlaubt, keine Punkte (S3-Regeln) |
| `region` | dropdown | ja | eu-central-1 / eu-west-1 / us-east-1 |
| `environment` | dropdown | ja | dev / staging / prod |
| `project_tag` | input | ja | Projekt-Kennzeichnung fuer Tagging |
| `versioning` | dropdown | ja | enabled / disabled |

### Was der Workflow tun soll

1. Issue-Body parsen.
2. Inhalt von `templates/terraform-s3-snippet.tf` laden.
3. Platzhalter ersetzen:
   - `__BUCKET_NAME__` → `bucket_name`
   - `__REGION__` → `region`
   - `__ENVIRONMENT__` → `environment`
   - `__TAG_PROJECT__` → `project_tag`
4. Ergebnis schreiben nach `generated-tf/<bucket_name>.tf`.
5. Branch erstellen: `feature/s3-<bucket_name>`.
6. Datei dort committen.
7. Pull Request oeffnen gegen `main` mit aussagekraeftigem Titel und Beschreibung.
8. Issue kommentieren: "PR erzeugt: #<pr-number>".
9. Issue mit Label `tf-pending-review` markieren (offen lassen).

### Schritt fuer Schritt

1. **Formular** anlegen (`.github/ISSUE_TEMPLATE/request-s3-bucket.yml`) –
   Baustein 1, Felder: `bucket_name`, `region`, `environment`, `project_tag`,
   `versioning`. Setze `labels: ["s3-request"]`.
   - Issue Forms koennen NICHT per Regex validieren (nur `required`). Den
     Bucket-Namen pruefst du daher im Workflow (siehe Hilfe unten).
2. **Labels anlegen:** `s3-request` und `tf-pending-review`. Ordner
   `generated-tf/` anlegen (z.B. eine leere `.gitkeep` darin).
3. **Workflow** anlegen (`.github/workflows/request-s3-bucket.yml`) – Bausteine
   2–3, dann Template rendern + PR erstellen (Hilfe unten).
4. **Test** mit `cloudhelden-demo-bucket`. PR pruefen: alle Werte korrekt eingesetzt?

### Konkrete Hilfe (zum Kopieren)

Validieren und rendern – sicher gegen Sonderzeichen mit Python (wie im Beispiel):

```yaml
      - name: Template rendern
        env:
          BUCKET: ${{ steps.parse.outputs.bucket_name }}
          REGION: ${{ steps.parse.outputs.region }}
          ENVIRONMENT: ${{ steps.parse.outputs.environment }}
          PROJECT: ${{ steps.parse.outputs.project_tag }}
        run: |
          # Bucket-Name pruefen (S3-Regeln). Bricht ab, wenn ungueltig.
          [[ "$BUCKET" =~ ^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$ ]] || { echo "ungueltiger Bucket-Name"; exit 1; }
          mkdir -p generated-tf
          python3 - "generated-tf/${BUCKET}.tf" <<'PY'
          import os, sys
          with open("templates/terraform-s3-snippet.tf", encoding="utf-8") as f:
              tf = f.read()
          tf = tf.replace("__BUCKET_NAME__", os.environ["BUCKET"])
          tf = tf.replace("__REGION__", os.environ["REGION"])
          tf = tf.replace("__ENVIRONMENT__", os.environ["ENVIRONMENT"])
          tf = tf.replace("__TAG_PROJECT__", os.environ["PROJECT"])
          with open(sys.argv[1], "w", encoding="utf-8") as f:
              f.write(tf)
          PY
```

Fuer den Pull Request ist `peter-evans/create-pull-request@v6` am einfachsten –
die Action erstellt Branch, Commit und PR in einem Schritt:

```yaml
      - name: Pull Request erstellen
        uses: peter-evans/create-pull-request@v6
        with:
          branch: "feature/s3-${{ steps.parse.outputs.bucket_name }}"
          title: "S3-Bucket: ${{ steps.parse.outputs.bucket_name }}"
          commit-message: "feat: S3-Bucket ${{ steps.parse.outputs.bucket_name }} gerendert"
          body: "Automatisch aus Issue erzeugt. Bitte vor Apply pruefen."
```

### Fang klein an

Erst nur: Formular + Workflow, der das Template rendert und die Datei **direkt
auf main committet** (wie im Beispiel). Den PR-Teil baust du erst ein, wenn das
Rendern funktioniert.

### Stolpersteine

- Bucket-Namen-Validierung im Issue Form ist tricky. Wenn der User einen
  ungueltigen Namen eingibt, laeuft der Workflow trotzdem. Daher zweite
  Validierung im Workflow selbst einbauen (Workflow bricht ab und kommentiert
  Fehler).
- `sed` mit Sonderzeichen im Wert kann brechen. Wenn ein User in `project_tag`
  ein `/` oder `&` eingibt: `sed`-Trenner anpassen oder Werte vorher escapen.
- `peter-evans/create-pull-request@v6` braucht einen Branch-Namen, der noch
  nicht existiert. Bei zweitem Lauf mit gleichem Bucket-Namen: Fehler. Loesung:
  Timestamp anhaengen oder im Workflow pruefen.

### Stretch-Goals

- Workflow validiert, dass `bucket_name` nicht schon in `generated-tf/` existiert.
- Workflow laeuft `terraform fmt` und `terraform validate` (ohne Provider-Init)
  ueber die erzeugte Datei und kommentiert das Ergebnis am PR.
- PR-Beschreibung enthaelt automatisch einen Hinweis "Bitte vor Apply pruefen:
  Tags, Naming, Public-Access-Block".

---

## Use Case D: Doku-Vorlage anfordern (Erweiterung)

Use Case D ist das Beispiel im Skelett. Fuer die eigene Uebung **erweitert** ihr
das Beispiel um drei Aspekte – das macht aus dem Beispiel einen produktionsnahen
Workflow.

### Erweiterungen

1. **Validierung des Service-Namens.** Wenn der Name nicht dem Schema entspricht
   (lowercase, 3–40 Zeichen, Bindestriche): Workflow erzeugt KEINE Datei,
   sondern kommentiert das Issue mit einem Fehlerhinweis und schliesst das Issue
   mit Label `rejected`.
2. **Duplikat-Check.** Wenn `generated-docs/<service_name>.md` schon existiert:
   Workflow lehnt ab und verlangt einen anderen Namen.
3. **Owner-Notification.** Workflow kommentiert das Issue zusaetzlich mit
   `@<owner-username>` (aus dem Owner-Feld), damit der genannte Owner per
   GitHub-Notification informiert wird.

### Schritt fuer Schritt

1. `example-doc-handler.yml` als Basis nehmen (NICHT die Datei direkt
   editieren – kopieren als `example-doc-handler-v2.yml` und das Original
   deaktivieren oder loeschen).
2. Vor dem Datei-Erzeugen-Schritt einen "Validate"-Schritt einbauen. Den
   Issue-Wert NICHT direkt mit `${{ ... }}` in die `run`-Zeile schreiben (das
   waere Script-Injection), sondern ueber `env` reichen und als `"$NAME"` lesen:
```yaml
- name: Validate inputs
  id: validate
  env:
    NAME: ${{ steps.parse.outputs.service_name }}
  run: |
    if [[ ! "$NAME" =~ ^[a-z0-9-]{3,40}$ ]]; then
      echo "INVALID=true" >> "$GITHUB_OUTPUT"
      echo "REASON=Service-Name entspricht nicht dem Schema" >> "$GITHUB_OUTPUT"
    elif [[ -f "generated-docs/${NAME}.md" ]]; then
      echo "INVALID=true" >> "$GITHUB_OUTPUT"
      echo "REASON=Service '${NAME}' existiert bereits" >> "$GITHUB_OUTPUT"
    else
      echo "INVALID=false" >> "$GITHUB_OUTPUT"
    fi
```
3. Folgende Schritte mit `if: steps.validate.outputs.INVALID == 'false'` konditionieren.
4. Einen Reject-Pfad einbauen mit `if: steps.validate.outputs.INVALID == 'true'`:
   - Kommentar mit Fehlertext.
   - Label `rejected`.
   - Issue schliessen.

### Stolpersteine

- Konditionale Steps: `if:` auf Job-Ebene vs. Step-Ebene unterscheiden.
- `outputs` zwischen Steps brauchen die Syntax `echo "KEY=value" >> $GITHUB_OUTPUT`.
- `@<username>` im Kommentar funktioniert nur, wenn der Username gueltig ist –
  GitHub macht daraus dann eine Notification.

### Stretch-Goals

- Reject-Pfad wartet 5 Minuten und loescht dann das Issue komplett (per `gh issue delete`).
- Owner-Feld bekommt eine GitHub-User-Search-Validierung (per API).

---

## Akzeptanzkriterien (fuer alle Use Cases)

Eure Implementierung gilt als erfolgreich, wenn alle Punkte erfuellt sind:

- [ ] Es gibt ein neues Issue Form, das im **New Issue**-Chooser auftaucht.
- [ ] Das Formular hat mindestens 3 sinnvolle Pflichtfelder.
- [ ] Der Workflow laeuft automatisch nach Issue-Erstellung (Actions-Tab zeigt gruen).
- [ ] Der Workflow erzeugt ein **sichtbares Ergebnis** im Repo (Datei oder PR).
- [ ] Das Issue wird mit einem aussagekraeftigen Kommentar versehen.
- [ ] Das Issue erhaelt ein Label, das den Status erkennen laesst.
- [ ] (Use Cases A/D) Das Issue wird automatisch geschlossen.
- [ ] (Use Cases B/C) Das Issue bleibt offen und wartet auf einen Folgeschritt.

---

## Wo ihr Hilfe findet

- `docs/CHEATSHEET-issue-forms.md` – Syntax-Spickzettel fuer Issue Forms
- `docs/CHEATSHEET-actions.md` – Syntax-Spickzettel fuer Workflows
- `docs/TROUBLESHOOTING.md` – die haeufigsten Fehler mit Loesung
- Offizielle GitHub-Doku zu Issue Forms:
  <https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues/syntax-for-issue-forms>
- Beispiel-Workflow im Skelett: `.github/workflows/example-doc-handler.yml` – die Kommentare dort sind euer wichtigster Referenzpunkt.
