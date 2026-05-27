# Rapport — PostgreSQL Security Hardening

> Exercices de formation — cadre pédagogique autorisé

---

## Synthèse

Trois exercices de sécurité PostgreSQL réalisés en environnement de lab.

| Exercice | Objectif | Résultat |
|---|---|---|
| 1 — Gestion des rôles | Créer et tester des rôles avec permissions progressives | Rôles `sales`, `bob`, `senior_sales` configurés et vérifiés |
| 2 — Audit d'un environnement défaillant | Identifier les mauvaises pratiques sur `clinic_db` | 5 faiblesses identifiées, dont exposition d'une clé de chiffrement dans les logs |
| 3 — Correction du désordre | Corriger les faiblesses identifiées | Scram-sha-256 activé, droits révoqués, pg_hba.conf corrigé |

---

## Exercice 1 — Gestion des rôles et permissions

### Contexte

Base de données `business_db` avec 3 tables : `customers`, `items`, `orders`.
Objectif : créer un groupe de permissions `sales`, un utilisateur de connexion `bob`,
puis un rôle avancé `senior_sales` avec des droits supplémentaires.

### Ce qui a été fait

**Création des rôles et utilisateur :**

```sql
CREATE ROLE sales;
CREATE ROLE bob LOGIN PASSWORD '[mot de passe lab]';
GRANT sales TO bob;
```

**Vérification avec `\du`** — le rôle `sales` apparaît bien dans la colonne "Member of" pour `bob`.

**Attribution des permissions de lecture :**

```sql
GRANT CONNECT ON DATABASE business_db TO sales;
GRANT USAGE ON SCHEMA public TO sales;
GRANT SELECT ON TABLE customers TO sales;
```

**Test de refus d'accès** — connecté en tant que `bob`, la requête `SELECT * FROM items` retourne :
```
ERROR: permission denied for table items
```
Résultat attendu : `bob` ne peut lire que `customers`, pas `items`.

**Rôle avancé `senior_sales` :**

```sql
CREATE ROLE senior_sales NOLOGIN;
GRANT sales TO senior_sales;               -- hérite les droits de sales
GRANT UPDATE ON customers TO senior_sales; -- droit supplémentaire
GRANT SELECT ON orders TO sales;
GRANT INSERT ON orders TO sales;
GRANT senior_sales TO bob;
```

### Ce que ça montre

La séparation `rôle de groupe` / `rôle de connexion` est une pratique fondamentale en PostgreSQL.
Attribuer des droits au groupe plutôt qu'à l'utilisateur simplifie la gestion :
si `bob` change de poste, on lui retire `senior_sales` sans toucher aux permissions elles-mêmes.

---

## Exercice 2 — Audit d'un environnement défaillant

### Contexte

Serveur PostgreSQL de lab (`11.10.10.26:5432`).
Bases présentes : `postgres`, `clinic_db`, `logs_db`.
Utilisateurs fournis : `secretary`, `steven_carr`.

### Faiblesses identifiées

#### 1. Mot de passe trivial sur le compte `secretary`

```
psql -h 11.10.10.26 -p 5432 -U secretary -d postgres
Password for user secretary: [mot de passe trivial — 1 caractère]
```

Connexion acceptée immédiatement. Un mot de passe d'un caractère n'offre aucune résistance.

#### 2. Données sensibles lisibles par un compte trop permissif

Connecté en tant que `secretary`, la table `doctors` est accessible en lecture :

```sql
SELECT * FROM doctors WHERE name = 'Steven Carr';
```

Résultat : le numéro de téléphone du médecin apparaît dans la réponse.
Ce numéro était utilisé comme mot de passe du compte `steven_carr`.
Un compte de secrétariat n'a pas besoin d'accéder aux données personnelles des médecins.

#### 3. Droits DELETE excessifs sur `steven_carr`

Connecté en tant que `steven_carr` :

```sql
DELETE FROM doctors;
```

La commande s'exécute. Un médecin n'a aucune raison de pouvoir supprimer des enregistrements
de la table des médecins — ni des autres tables. Ce droit est clairement excessif.

#### 4. Clé de chiffrement visible dans les journaux système

La base `logs_db` contient les journaux PostgreSQL. Accessible à `steven_carr`,
elle exposait l'historique des instructions SQL, notamment la création des tables chiffrées :

```sql
-- Extrait des journaux retrouvé
INSERT INTO patients (full_name, ssn, diagnosis)
SELECT full_name,
       pgp_sym_encrypt(ssn, 'supersecurepassphrase'),
       pgp_sym_encrypt(diagnosis, 'supersecurepassphrase')
FROM temp_data;
```

La phrase secrète de chiffrement (`pgcrypto`) apparaît en clair dans les logs.
Elle permettait de déchiffrer les colonnes `ssn` et `diagnosis` de la table `patients`.

#### 5. Mot de passe PostgreSQL transmis sans chiffrement réseau

L'analyse d'un fichier `.pcap` fourni dans l'exercice montrait une trame PostgreSQL
de type `Password message` contenant un mot de passe lisible en clair.
Absence de SSL/TLS sur la connexion PostgreSQL distante.

### Ce que ces faiblesses permettent

Un attaquant ayant un accès réseau au serveur peut :
- Deviner le mot de passe de `secretary` par force brute triviale
- Lire les informations des médecins et déduire le mot de passe de `steven_carr`
- Supprimer l'intégralité de la table `doctors` via `steven_carr`
- Déchiffrer les données médicales des patients avec la phrase secrète récupérée dans les logs
- Capturer des mots de passe PostgreSQL en clair sur le réseau

---

## Exercice 3 — Correction du désordre

### Corrections appliquées

#### Activer scram-sha-256 et redéfinir les mots de passe

```sql
ALTER SYSTEM SET password_encryption = 'scram-sha-256';
SELECT pg_reload_conf();

ALTER ROLE secretary WITH PASSWORD '[nouveau mot de passe fort]';
ALTER ROLE steven_carr WITH PASSWORD '[nouveau mot de passe fort]';
```

Important : activer `scram-sha-256` ne re-hache pas les mots de passe existants.
Il faut redéfinir chaque mot de passe après activation pour que le nouveau hash soit utilisé.

#### Retirer le droit DELETE excessif

```sql
REVOKE DELETE ON TABLE doctors FROM steven_carr;
```

Vérification : `DELETE FROM doctors` renvoie ensuite `ERROR: permission denied for table doctors`.

#### Révoquer l'accès à la base de logs

```sql
REVOKE CONNECT ON DATABASE logs_db FROM steven_carr;
REVOKE CONNECT ON DATABASE logs_db FROM PUBLIC;
```

Vérification depuis Kali : `psql -h 11.10.10.26 -p 5432 -U steven_carr -d logs_db`
retourne `FATAL: permission denied for database "logs_db"`.

#### Protéger la clé de chiffrement contre l'exposition dans les logs

Au lieu d'inscrire la phrase secrète directement dans la requête SQL,
utiliser une variable psql côté client :

```sql
\set encryption_key 'supersecurepassphrase'

SELECT pgp_sym_decrypt(diagnosis, :'encryption_key')
FROM patients
WHERE full_name = 'John West';
```

La variable psql n'est pas envoyée au serveur dans le corps de la requête SQL —
elle ne sera donc pas enregistrée dans les journaux PostgreSQL.
En production, préférer une variable d'environnement ou un gestionnaire de secrets.

#### Corriger l'authentification administrateur dans `pg_hba.conf`

```
# Règle faible à remplacer
local   all   admin   trust

# Règle correcte
local   all   admin   scram-sha-256
host    all   admin   127.0.0.1/32   scram-sha-256
```

Puis recharger :

```sql
SELECT pg_reload_conf();
ALTER ROLE admin WITH PASSWORD '[mot de passe fort]';
```

---

## Synthèse des risques — avant / après

| Faiblesse | Risque avant | Risque après |
|---|---|---|
| Mot de passe trivial | Compromission par force brute immédiate | Mot de passe fort + scram-sha-256 |
| Données sensibles accessibles via role trop large | Fuite d'information + escalade de comptes | Permissions réduites au strict nécessaire |
| DELETE excessif | Destruction de données | Droit révoqué |
| Clé de chiffrement dans les logs | Déchiffrement de données médicales | Variable psql + accès logs révoqué |
| Transmission mot de passe sans SSL | Capture réseau | SSL à activer + scram-sha-256 |
| Authentification admin sans mot de passe | Accès root DB sans credential | `trust` → `scram-sha-256` dans pg_hba.conf |

---

## Ce que j'ai appris

- La différence concrète entre `md5` et `scram-sha-256` en PostgreSQL — et pourquoi il faut redéfinir les mots de passe après le changement de méthode
- Pourquoi les journaux PostgreSQL sont une source de fuite critique si leur accès n'est pas cloisonné
- Comment utiliser les variables psql pour éviter que les secrets apparaissent dans les requêtes SQL journalisées
- Le rôle de `pg_hba.conf` : la méthode d'authentification peut être `trust` (sans mot de passe) sur certaines règles sans que l'administrateur en soit conscient
- L'importance de tester le refus d'accès, pas seulement l'accès autorisé — vérifier que `permission denied` apparaît est aussi important que vérifier que la requête légitime fonctionne
