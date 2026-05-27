# PostgreSQL Security Hardening

Trois exercices de sécurité PostgreSQL réalisés en lab autorisé.  
Objectif : comprendre les erreurs de configuration courantes, les identifier sur un environnement défaillant, puis les corriger.

---

## Contexte

| Élément | Détail |
|---|---|
| Type | Exercices de formation — Jedha Fullstack Cybersécurité |
| Environnement | Serveurs PostgreSQL de lab (local et distant) |
| Périmètre | Autorisé et contrôlé |
| Données | Fictionnelles — aucune donnée réelle publiée |

---

## Exercices réalisés

### Exercice 1 — Gestion des rôles et permissions (`business_db`)

Création d'une hiérarchie de rôles sur une base avec 3 tables (`customers`, `items`, `orders`) :

- Rôle de groupe `sales` sans connexion directe
- Utilisateur `bob` rattaché au groupe `sales`
- Rôle avancé `senior_sales` avec permissions supplémentaires (`UPDATE`, `INSERT`)
- Vérification des refus d'accès : `bob` ne peut pas lire `items` → `permission denied` confirmé

### Exercice 2 — Audit d'un environnement défaillant (`clinic_db`)

Identification de 5 faiblesses sur un serveur PostgreSQL distant :

| # | Faiblesse | Impact |
|---|---|---|
| 1 | Mot de passe trivial sur `secretary` | Compromission par force brute immédiate |
| 2 | Données personnelles lisibles par un compte sans besoin métier | Escalade de compte via données extraites |
| 3 | Droit `DELETE` excessif sur `steven_carr` | Suppression de l'intégralité d'une table critique |
| 4 | Clé de chiffrement `pgcrypto` visible dans les journaux PostgreSQL | Déchiffrement de données médicales |
| 5 | Transmission du mot de passe sans SSL (capturé en `.pcap`) | Vol de credential sur le réseau |

### Exercice 3 — Correction du désordre

Correction systématique de toutes les faiblesses identifiées :

- Activation de `scram-sha-256` + redéfinition des mots de passe
- `REVOKE DELETE` sur `steven_carr`
- `REVOKE CONNECT` sur `logs_db` pour `steven_carr` et `PUBLIC`
- Suppression de `logs_db` (base inutile et dangereuse)
- Protection de la clé de chiffrement via variable psql (n'apparaît plus dans les logs)
- Remplacement de `trust` par `scram-sha-256` dans `pg_hba.conf`

---

## Structure du dépôt

| Fichier | Contenu |
|---|---|
| `report.md` | Rapport complet des 3 exercices — faiblesses, contexte, corrections, analyse |
| `commands.sql` | Commandes SQL des exercices, avec commentaires et placeholders |
| `notes.md` | Référence sur les privilèges PostgreSQL et bonnes pratiques |
| `CHECKLIST.md` | Checklist avant publication |

---

## Compétences démontrées

- Création et gestion de rôles PostgreSQL (groupes, utilisateurs, héritage)
- Audit de permissions : `\du`, `\l`, `information_schema`, `pg_database`
- Identification de configurations dangereuses : `trust`, `md5`, logs exposés, droits excessifs
- Application du principe du moindre privilège
- Lecture de journaux PostgreSQL pour identifier des fuites de configuration
- Analyse réseau basique : lecture d'un `.pcap` pour identifier une transmission de mot de passe en clair
- Documentation technique orientée remédiation

---

## Avertissement

Exercices réalisés dans un cadre légal, éducatif et autorisé.  
Les données sont fictionnelles. Les mots de passe des exercices ont été remplacés par des placeholders.
