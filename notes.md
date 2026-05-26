# Notes de référence — Sécurité PostgreSQL

## Privilèges de base

| Privilège | Description | Risque si excessif |
|---|---|---|
| SELECT | Lire des données | Fuite d'information |
| INSERT | Insérer des données | Injection de données |
| UPDATE | Modifier des données | Altération |
| DELETE | Supprimer des données | Destruction |
| CONNECT | Se connecter à une base | Accès non autorisé |
| SUPERUSER | Tous les droits | Compromission totale |
| CREATEDB | Créer des bases | Prolifération non contrôlée |
| CREATEROLE | Créer des rôles | Élévation de privilèges |

## Commandes d'audit essentielles

```sql
-- Rôles et attributs
\du

-- Bases et propriétaires
\l

-- Privilèges sur une table
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'ma_table';

-- Paramètres système actifs
SHOW password_encryption;
SHOW log_connections;
SHOW log_statement;
```

## Principe du moindre privilège

Chaque rôle ne doit avoir que les droits strictement nécessaires à sa fonction :

| Rôle | Droits appropriés |
|---|---|
| Lecture seule | SELECT uniquement |
| Applicatif web | SELECT, INSERT, UPDATE sur les tables concernées uniquement |
| Reporting | SELECT sur les vues ou tables de rapport uniquement |
| Administratif | Séparé du rôle applicatif, usage rare et tracé |
| Superuser | Réservé à l'administration système, jamais utilisé en production courante |

## Chiffrement des mots de passe

| Méthode | Statut | Remarque |
|---|---|---|
| `md5` | Obsolète — ne plus utiliser | Hash faible, vulnérable aux attaques par dictionnaire |
| `scram-sha-256` | Standard recommandé | Résistant, à activer sur toutes les installations |

## Bonnes pratiques

- Auditer les privilèges régulièrement (au moins trimestriel)
- Désactiver les comptes inutilisés (`NOLOGIN`)
- Utiliser des rôles de groupe pour simplifier la gestion
- Journaliser avec `pg_audit` en production
- Changer les mots de passe par défaut immédiatement à l'installation
- Limiter les connexions distantes via `pg_hba.conf`
- Activer SSL pour les connexions distantes

## Références

- PostgreSQL docs — Privileges : https://www.postgresql.org/docs/current/ddl-priv.html
- CIS PostgreSQL Benchmark : https://www.cisecurity.org/benchmark/postgresql
