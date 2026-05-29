-- PostgreSQL Security Hardening — Commandes des exercices
-- Exercices de formation en environnement contrôlé
-- Les mots de passe ont été remplacés par des placeholders

-- ============================================================
--  EXERCICE 1 — Gestion des rôles (base business_db)
-- ============================================================

-- Créer le rôle de groupe sales (pas de connexion directe)
CREATE ROLE sales;

-- Créer l'utilisateur de connexion bob
CREATE ROLE bob LOGIN PASSWORD '[mot_de_passe_lab]';

-- Rattacher bob au groupe sales
GRANT sales TO bob;

-- Vérifier les rôles et membres
\du

-- Accorder les permissions de lecture à sales
GRANT CONNECT ON DATABASE business_db TO sales;
GRANT USAGE ON SCHEMA public TO sales;
GRANT SELECT ON TABLE customers TO sales;

-- Test : connecté en bob, lire items (doit être refusé)
-- \c business_db bob
-- SELECT * FROM items;
-- Résultat attendu : ERROR: permission denied for table items

-- Créer le rôle senior_sales avec droits supplémentaires
CREATE ROLE senior_sales NOLOGIN;
GRANT sales TO senior_sales;
GRANT UPDATE ON customers TO senior_sales;
GRANT SELECT ON orders TO sales;
GRANT INSERT ON orders TO sales;
GRANT senior_sales TO bob;


-- ============================================================
--  EXERCICE 2 — Audit (base clinic_db, serveur 11.10.10.26)
-- ============================================================

-- Connexion initiale avec secretary
-- psql -h 11.10.10.26 -p 5432 -U secretary -d postgres

-- Lister les bases disponibles
\l

-- Se connecter à clinic_db et afficher les tables
\c clinic_db
\dt

-- Lecture de la table doctors (accessible à secretary)
SELECT * FROM doctors WHERE name = 'Steven Carr';
-- Observation : le numéro de téléphone du médecin apparaît en clair

-- Connexion avec steven_carr (mot de passe récupéré dans la table doctors)
-- psql -h 11.10.10.26 -p 5432 -U steven_carr -d postgres

-- Se connecter à logs_db et afficher les privilèges
\c logs_db
\z

-- Tenter DELETE sur doctors (ne devrait pas être possible)
DELETE FROM doctors;
-- Observation : la commande s'exécute — droit DELETE excessif confirmé

-- Consulter les journaux pour identifier les problèmes de configuration
-- NOTE: postgres_log est une foreign table configurée spécifiquement dans ce lab Jedha (file_fdw).
-- En dehors de ce lab, les logs PostgreSQL sont dans des fichiers, pas une table SQL.
-- Alternative standard : SELECT pg_read_file('postgresql.log') ou passer par pg_log.
SELECT log_time, message FROM postgres_log
ORDER BY log_time
LIMIT 50;

-- Déchiffrer un enregistrement avec la clé trouvée dans les logs
\c clinic_db
SELECT pgp_sym_decrypt(diagnosis, 'supersecurepassphrase')
FROM patients
WHERE full_name = 'John West';
-- Résultat : 'Ear Infection' — données médicales déchiffrées avec la clé exposée dans les logs


-- Ex. 3 — Corrections après audit clinic_db

-- 1. Activer scram-sha-256 et redéfinir les mots de passe
ALTER SYSTEM SET password_encryption = 'scram-sha-256';
SELECT pg_reload_conf();
-- Important : redéfinir les mots de passe APRÈS activation, sinon les anciens hashes restent en md5
ALTER ROLE secretary WITH PASSWORD '[nouveau_mdp_fort]';
ALTER ROLE steven_carr WITH PASSWORD '[nouveau_mdp_fort]';

-- 2. Révoquer le droit DELETE excessif
REVOKE DELETE ON TABLE doctors FROM steven_carr;
-- Vérification : DELETE FROM doctors doit retourner "permission denied"

-- 3. Révoquer l'accès à la base de logs
REVOKE CONNECT ON DATABASE logs_db FROM steven_carr;
REVOKE CONNECT ON DATABASE logs_db FROM PUBLIC;
-- Vérification : psql -h ... -U steven_carr -d logs_db → FATAL: permission denied

-- 4. Supprimer la base logs_db si elle n'est pas nécessaire
-- (fermer les connexions actives en premier si besoin)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'logs_db';
\c postgres
DROP DATABASE logs_db;

-- 5. Stocker la clé de chiffrement dans une variable psql (ne passe pas dans les logs serveur)
\set encryption_key 'supersecurepassphrase'
SELECT pgp_sym_decrypt(diagnosis, :'encryption_key')
FROM patients
WHERE full_name = 'John West';

-- 6. Corriger pg_hba.conf (modifier le fichier manuellement, puis recharger)
-- Remplacer : local   all   admin   trust
-- Par :       local   all   admin   scram-sha-256
SELECT pg_reload_conf();
ALTER ROLE admin WITH PASSWORD '[nouveau_mdp_fort_admin]';


-- ============================================================
--  AUDIT GÉNÉRAL — Commandes de vérification utiles
-- ============================================================

-- Lister les rôles et leurs attributs
\du

-- Lister les bases et leurs propriétaires
\l

-- Vérifier les privilèges sur une table
SELECT grantee, privilege_type, table_name
FROM information_schema.role_table_grants
WHERE table_name = 'doctors';

-- Vérifier les droits de connexion aux bases
SELECT datname, datacl
FROM pg_database;

-- Vérifier la méthode de chiffrement active
SHOW password_encryption;

-- Vérifier les paramètres de journalisation
SHOW log_connections;
SHOW log_statement;
