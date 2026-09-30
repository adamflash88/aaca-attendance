# AACA Attendance

Power Apps canvas app + Dataverse + Power Automate for special-education attendance tracking
across AACA campuses. Design: [docs/architecture.md](docs/architecture.md).

## Layout
| Folder | Contents |
|---|---|
| `docs/` | Architecture, guides, known limitations |
| `schema/tables.json` | Source of truth for tables, columns, choices, lookups and keys |
| `provisioning/` | Scripts that build the Dataverse schema and security in an environment |
| `seed/` | Fake test-data generator (never real student data) |
| `solution/` | Unpacked `AACAAttendance` solution (`pac solution sync`) |
| `app/` | Canvas app `.pa.yaml` sources |
| `flows/` | Power Automate flow definitions and build notes |
| `tests/` | Test cases and UAT scripts |

## Provision a new environment
```powershell
# 1. Validate the schema and preview what will be created (no sign-in)
./provisioning/Deploy-Schema.ps1 -PlanOnly

# 2. Create publisher, solution, tables, columns, lookups, keys (re-runnable)
./provisioning/Deploy-Schema.ps1 -EnvironmentUrl https://<org>.crm.dynamics.com -EnableOrgAuditing
```

## Rules
- No real student data in this repository, in seed files or in logs.
- Never renumber an existing choice value in `schema/tables.json`; append new values.
