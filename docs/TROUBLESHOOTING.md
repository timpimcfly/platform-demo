# Troubleshooting

Haeufige Probleme und deren Loesungen bei der Arbeit mit diesem Schulungsrepo.

---

## Problemuebersicht

| Symptom | Wahrscheinliche Ursache | Loesung |
|---------|------------------------|---------|
| Workflow startet gar nicht, Issue hat kein `doku-request`-Label | Label existiert nicht im Repo. Beim "Use this template" werden Labels NICHT mitkopiert, daher kann das Issue-Formular sie nicht setzen. | Label `doku-request` (und `automation`, `completed`, `invalid-input`) unter Issues → Labels anlegen. Siehe "Vorab: Labels anlegen" in EXERCISES.md. |
| Workflow bricht beim Label-Setzen ab (`gh issue edit --add-label`) | Ziel-Label (`completed`/`invalid-input`) existiert nicht | Labels vorab anlegen. `gh issue edit --add-label` erstellt fehlende Labels NICHT automatisch. |
| Workflow startet nicht nach Issue-Erstellung | 1. Label stimmt nicht ueberein 2. Event-Typ falsch 3. Workflow-Datei hat YAML-Fehler | Label im Issue-Template und im Workflow-`if` vergleichen. Unter Actions → Workflow pruefen, ob der Workflow ueberhaupt sichtbar ist. YAML mit einem Linter pruefen. |
| Workflow startet, bricht aber bei "Commit" ab | Fehlende Schreibrechte fuer den GITHUB_TOKEN | Settings → Actions → General → "Read and write permissions" aktivieren. Im Workflow `permissions: contents: write` setzen. |
| Workflow startet, bricht bei "gh issue comment" ab | `permissions: issues: write` fehlt oder `GH_TOKEN` nicht gesetzt | `permissions: issues: write` im Workflow ergaenzen. Step braucht `env: GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}`. |
| Issue-Formular taucht nicht im "New Issue"-Dialog auf | 1. Datei liegt am falschen Ort 2. Dateiname endet nicht auf `.yml` 3. YAML-Syntaxfehler | Pfad muss exakt `.github/ISSUE_TEMPLATE/<name>.yml` sein. YAML-Syntax pruefen (Einrueckung, fehlende Anführungszeichen). |
| Datei wird nicht erzeugt (Workflow gruen, aber leer) | Pfad in `sed`/`cp` stimmt nicht oder Variable ist leer | Workflow-Logs im Actions-Tab pruefen. Debug-Ausgaben (`echo`) einbauen, um Variablenwerte zu sehen. |
| Push wird abgelehnt ("branch protection") | Branch Protection Rules auf `main` aktiv | Fuer die Schulung: Branch Protection deaktivieren. Alternativ: Workflow so umbauen, dass ein PR statt direktem Push erstellt wird. |
| "Resource not accessible by integration" | Genereller Permissions-Fehler | Sowohl den `permissions`-Block im Workflow ALS AUCH die Repo-Settings pruefen. Beides muss stimmen. |
| Workflow reagiert nicht auf das richtige Issue | Label-Filter (`if: contains(...)`) matcht nicht | Exakte Schreibweise der Labels vergleichen. Gross-/Kleinschreibung beachten. Labels muessen VOR dem Workflow-Start am Issue haengen (also im Template definiert sein). |

---

## Debugging-Tipps

### 1. Workflow-Logs lesen
- Im Repository: Actions-Tab → Workflow-Run anklicken → Job anklicken → Steps aufklappen.
- Jeder Step zeigt seine Ausgabe. Fehlermeldungen stehen meist am Ende eines fehlgeschlagenen Steps.

### 2. Debug-Ausgaben einbauen
```yaml
- name: Debug - Variablen ausgeben
  run: |
    echo "Issue-Nummer: ${{ github.event.issue.number }}"
    echo "Labels: ${{ join(github.event.issue.labels.*.name, ', ') }}"
    echo "Body-Laenge: $(echo '${{ github.event.issue.body }}' | wc -c)"
```

### 3. Workflow manuell re-triggern
Ein Workflow mit `on: issues: types: [opened]` laesst sich nicht manuell neu starten. Stattdessen: Issue schliessen und ein neues oeffnen.

### 4. YAML validieren
- Online: [YAML Lint](https://www.yamllint.com/)
- Im Browser: GitHub zeigt YAML-Fehler in Issue-Templates direkt an (rotes Banner ueber dem Formular).

---

## Checkliste: Neuen Workflow zum Laufen bringen

1. [ ] Workflow-Datei liegt unter `.github/workflows/<name>.yml`
2. [ ] `on:`-Trigger ist korrekt (Event + Type)
3. [ ] `if:`-Bedingung matcht die Labels im Issue-Template
4. [ ] `permissions:`-Block enthaelt alle benoetigten Rechte
5. [ ] Repo-Settings: "Read and write permissions" ist aktiviert
6. [ ] Alle `env: GH_TOKEN` sind gesetzt wo `gh` verwendet wird
7. [ ] Pfade zu Templates/Ausgabedateien stimmen (relativ zum Repo-Root)
8. [ ] YAML-Einrueckung ist konsistent (2 Spaces, keine Tabs)
