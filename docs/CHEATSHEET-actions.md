# Cheatsheet: GitHub Actions fuer IssueOps

Kurzreferenz fuer Workflows, die auf Issues reagieren und automatisierte Aktionen ausfuehren.

---

## Trigger fuer IssueOps

```yaml
# Reagiert auf neue und bearbeitete Issues
on:
  issues:
    types: [opened, edited, labeled]

# Reagiert auf Issue-Kommentare (z.B. Slash-Commands wie /approve)
on:
  issue_comment:
    types: [created]
```

---

## Wichtige Kontext-Variablen

| Variable | Inhalt |
|----------|--------|
| `github.event.issue.body` | Vollstaendiger Issue-Body (Formularinhalt) |
| `github.event.issue.title` | Issue-Titel |
| `github.event.issue.number` | Issue-Nummer (z.B. 42) |
| `github.event.issue.user.login` | Username des Issue-Erstellers |
| `github.event.issue.labels.*.name` | Array der Label-Namen |
| `github.event.comment.body` | Kommentartext (nur bei issue_comment) |

---

## Permissions-Block

Der `permissions`-Block definiert, was der Workflow darf. Ohne explizite Angabe gelten die Repo-Defaults.

```yaml
permissions:
  contents: write   # Dateien lesen und schreiben (commit/push)
  issues: write     # Issues kommentieren, labeln, schliessen
  pull-requests: write  # PRs erstellen und kommentieren
```

**Wichtig:** Zusaetzlich muss unter Settings → Actions → General die Option "Read and write permissions" aktiviert sein.

---

## Haeufige Patterns

### Issue kommentieren

```yaml
- name: Kommentar schreiben
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    gh issue comment ${{ github.event.issue.number }} \
      --body "Deine Anfrage wird bearbeitet."
```

### Issue schliessen

```yaml
- name: Issue schliessen
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    gh issue close ${{ github.event.issue.number }} --reason "completed"
```

### Label setzen

```yaml
- name: Label hinzufuegen
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    gh issue edit ${{ github.event.issue.number }} --add-label "completed"
```

### Datei committen und pushen

```yaml
- name: Aenderungen committen
  run: |
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add .
    git commit -m "chore: automatisch erzeugte Datei"
    git push
```

### Pull Request erstellen (mit gh CLI)

```yaml
- name: Branch erstellen und PR oeffnen
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    BRANCH="automated/meine-aenderung"
    git checkout -b "$BRANCH"
    git add .
    git commit -m "feat: automatisch erzeugt"
    git push --set-upstream origin "$BRANCH"
    gh pr create --title "Automatisch erzeugt" \
      --body "Erstellt durch Workflow" \
      --base main
```

---

## Vollstaendiges Mini-Beispiel

Ein Workflow, der auf ein Issue reagiert und einen Kommentar schreibt:

```yaml
name: "Issue begruessen"
on:
  issues:
    types: [opened]

permissions:
  issues: write

jobs:
  greet:
    runs-on: ubuntu-latest
    steps:
      - name: Willkommenskommentar
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh issue comment ${{ github.event.issue.number }} \
            --body "Danke fuer dein Issue, @${{ github.event.issue.user.login }}! Wir schauen uns das an."
```

---

## Haeufige Fehler

| Problem | Ursache | Loesung |
|---------|---------|---------|
| Workflow startet nicht | Falscher Event oder fehlender Label-Filter | `on:` und `if:` pruefen |
| "Resource not accessible by integration" | Fehlende Permissions | `permissions`-Block hinzufuegen UND Repo-Settings pruefen |
| Push schlaegt fehl | `contents: write` fehlt oder Branch Protection | Permissions pruefen, ggf. auf PR umstellen |
| `gh` Befehl scheitert | `GH_TOKEN` nicht gesetzt | `env: GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}` ergaenzen |
| Workflow reagiert auf eigene Commits | Endlosschleife | `if: github.actor != 'github-actions[bot]'` ergaenzen |

---

## Nuetzliche Actions (Public Marketplace)

| Action | Zweck |
|--------|-------|
| `actions/checkout@v4` | Repository auschecken |
| `peter-evans/create-or-update-comment@v4` | Issue/PR kommentieren (Alternative zu gh CLI) |
| `peter-evans/create-pull-request@v6` | PR aus Workflow-Aenderungen erstellen |
| `stefanzweifel/git-auto-commit-action@v5` | Automatisch committen und pushen |

---

## Offizielle Dokumentation

- [GitHub Docs: Events that trigger workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
- [GitHub Docs: Permissions for GITHUB_TOKEN](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
