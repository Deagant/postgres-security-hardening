-- PostgreSQL Security Hardening — Commandes anonymisées
-- Exercice de formation en environnement contrôlé
-- Les noms de tables, bases et utilisateurs sont génériques


-- ============================================================
--  AUDIT INITIAL — Vérification des rôles et privilèges
-- ============================================================

-- Lister les rôles et leurs attributs (superuser, login, etc.)
\du

-- Lister les bases de données et leurs propriétaires
\l

-- Vérifier les privilèges accordés sur une table spécifique
SELECT grantee, privilege_type, table_name
FROM information_schema.role_table_grants
WHERE table_name = 'nom_table_sensible';

-- Vérifier les droits de connexion aux bases
SELECT datname, datacl
FROM pg_database;

-- Vérifier la méthode de chiffrement active
SHOW password_encryption;


-- ============================================================
--  CORRECTIONS — Révocation de privilèges excessifs
-- ============================================================

-- Révoquer le droit DELETE sur une table sensible
REVOKE DELETE ON TABLE nom_table_sensible FROM nom_utilisateur;

-- Révoquer un droit INSERT non justifié
REVOKE INSERT ON TABLE nom_table_sensible FROM nom_utilisateur;

-- Révoquer l'accès CONNECT à une base sensible non nécessaire
REVOKE CONNECT ON DATABASE nom_base_sensible FROM nom_utilisateur;


-- ============================================================
--  CORRECTIONS — Renforcement du chiffrement des mots de passe
-- ============================================================

-- Activer SCRAM-SHA-256 (remplace md5)
ALTER SYSTEM SET password_encryption = 'scram-sha-256';

-- Recharger la configuration sans redémarrer le serveur
SELECT pg_reload_conf();

-- Renouveler le mot de passe d'un compte pour appliquer SCRAM-SHA-256
-- (à effectuer pour chaque compte concerné après activation)
ALTER ROLE nom_utilisateur PASSWORD 'nouveau_mot_de_passe_fort';


-- ============================================================
--  VÉRIFICATION APRÈS CORRECTION
-- ============================================================

-- Vérifier les privilèges après révocation
SELECT grantee, privilege_type, table_name
FROM information_schema.role_table_grants
WHERE table_name = 'nom_table_sensible';

-- Vérifier la méthode de chiffrement active
SHOW password_encryption;

-- Vérifier les droits de connexion après révocation
SELECT datname, datacl
FROM pg_database
WHERE datname = 'nom_base_sensible';

-- Vérifier les attributs du rôle modifié
\du nom_utilisateur
