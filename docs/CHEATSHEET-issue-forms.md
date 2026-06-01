# Cheatsheet: GitHub Issue Forms

Kurzreferenz fuer das Erstellen von Issue-Formularen in GitHub.

---

## Wo liegt die Datei?

```
.github/ISSUE_TEMPLATE/<name>.yml
```

Der Dateiname ist frei waehlbar, muss aber auf `.yml` oder `.yaml` enden. Die Datei `config.yml` im selben Ordner steuert die Template-Auswahl (kein Formular selbst).

---

## Die 5 Top-Level-Felder

| Feld | Pflicht | Beschreibung |
|------|---------|--------------|
| `name` | ja | Anzeigename im Template-Chooser |
| `description` | ja | Kurzbeschreibung unter dem Namen |
| `title` | nein | Vorausgefuellter Issue-Titel (kann Platzhalter enthalten) |
| `labels` | nein | Labels, die automatisch gesetzt werden (Array) |
| `body` | ja | Array der Formular-Elemente |

---

## Die 5 Element-Typen

### 1. markdown – Erklaerungstext (wird nicht im Body gespeichert)
```yaml
- type: markdown
  attributes:
    value: "Hier steht ein Hinweis fuer den Ausfuellenden."
```

### 2. input – Einzeilige Texteingabe
```yaml
- type: input
  id: service_name
  attributes:
    label: "Service-Name"
    description: "Nur Kleinbuchstaben und Bindestriche"
    placeholder: "mein-service"
  validations:
    required: true
```

### 3. textarea – Mehrzeilige Texteingabe
```yaml
- type: textarea
  id: description
  attributes:
    label: "Beschreibung"
    description: "Was macht der Service?"
    placeholder: "Dieser Service..."
    render: markdown
  validations:
    required: true
```

### 4. dropdown – Auswahlmenue
```yaml
- type: dropdown
  id: environment
  attributes:
    label: "Umgebung"
    options:
      - dev
      - staging
      - prod
  validations:
    required: true
```

### 5. checkboxes – Checkboxen (z.B. Bestaetigungen)
```yaml
- type: checkboxes
  id: agreements
  attributes:
    label: "Bestaetigungen"
    options:
      - label: "Ich bestaetige die Richtigkeit."
        required: true
      - label: "Optionale Zusatzoption"
        required: false
```

---

## Eingaben validieren – WICHTIG

GitHub Issue Forms unterstuetzen **keine** Regex-Validierung. Das einzige
unterstuetzte Feld unter `validations` ist `required: true|false`. Ein Schluessel
wie `pattern:` ist **kein gueltiges Schema** und fuehrt dazu, dass das Formular
nicht gerendert wird ("There is an error in the issue template").

Format-Vorgaben (z.B. "nur Kleinbuchstaben und Bindestriche") muessen daher
**im Workflow** geprueft werden, nachdem das Issue erstellt wurde – siehe den
Schritt "Eingaben validieren" in `.github/workflows/example-doc-handler.yml`.

Typische Regex fuer die Workflow-Validierung (Bash `=~`):

| Zweck | Pattern |
|-------|---------|
| Nur Kleinbuchstaben + Bindestriche | `^[a-z][a-z0-9-]+$` |
| GitHub-Username | `^[a-zA-Z0-9-]+$` |
| URL | `^https://.*` |
| S3-Bucket-Name (3-63 Zeichen) | `^[a-z][a-z0-9-]{2,62}$` |

---

## Haeufige Fehler

| Problem | Ursache | Loesung |
|---------|---------|---------|
| Formular erscheint nicht | Datei nicht unter `.github/ISSUE_TEMPLATE/` | Pfad pruefen, auf `.yml` achten |
| YAML-Parse-Fehler | Falsche Einrueckung | Immer 2 Spaces, keine Tabs |
| `type` fehlt | Element ohne `type`-Angabe | Jedes Body-Element braucht `type` |
| `id` Fehler | Doppelte IDs oder Sonderzeichen | IDs muessen eindeutig sein, nur `[a-z0-9_-]` |
| `pattern:` verwendet | Issue Forms kennen kein Regex-Feld | `pattern` entfernen, Format im Workflow pruefen |
| Dropdown leer | `options` fehlt oder ist kein Array | `options:` muss eine YAML-Liste sein |

---

## Offizielle Dokumentation

- [GitHub Docs: Issue Forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues/syntax-for-issue-forms)
- [GitHub Docs: YAML Schema Reference](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues/syntax-for-githubs-form-schema)
