# Rapport — PostgreSQL Security Hardening

> Exercice de formation — cadre pédagogique autorisé

---

## 1. Synthèse

Exercice de correction de configuration PostgreSQL sur un environnement de lab.  
Plusieurs problèmes de permissions ont été identifiés et corrigés :
droits excessifs sur des tables sensibles, accès inutiles à des bases critiques
et mécanisme de chiffrement des mots de passe insuffisant.

| Indicateur | Valeur |
|---|---|
| Problèmes identifiés | 4 |
| Niveau de risque avant correction | Élevé |
| Niveau de risque après correction | Faible |
| Corrections appliquées | Révocations + changement de politique de chiffrement |

---

## 2. Contexte

| Élément | Détail |
|---|---|
| Plateforme | Lab PostgreSQL de formation |
| Type d'exercice | Audit et correction de permissions |
| Périmètre | Autorisé et contrôlé |
| Données sensibles | Supprimées ou anonymisées |

---

## 3. Problèmes identifiés

| # | Problème | Risque |
|---|---|---|
| 1 | Droit DELETE excessif sur table sensible | Suppression de données critiques |
| 2 | Accès CONNECT inutile à une base sensible | Mouvement latéral, fuite de données |
| 3 | Chiffrement de mot de passe insuffisant (md5) | Compromission en cas de fuite de hash |
| 4 | Mots de passe faibles sur des comptes actifs | Compromission par brute force |

---

## 4. Corrections appliquées

Voir `commands.sql` pour les commandes complètes (anonymisées).

### 4.1 Révocation de droits DELETE excessifs

Le droit DELETE permettait à un utilisateur non autorisé de supprimer des enregistrements sensibles.  
La révocation applique le principe du moindre privilège : l'utilisateur conserve uniquement
les droits nécessaires à sa fonction applicative.

### 4.2 Révocation d'accès à une base sensible

L'utilisateur n'avait pas besoin d'accéder à cette base.  
La révocation du droit CONNECT réduit la surface d'exposition et le risque de mouvement latéral.

### 4.3 Renforcement du chiffrement des mots de passe

Le mécanisme MD5 présente des faiblesses connues face aux attaques par dictionnaire.  
L'activation de SCRAM-SHA-256 améliore significativement la résistance des hashs stockés.

---

## 5. Analyse de risque

| Élément | Avant correction | Après correction |
|---|---|---|
| Impact | Élevé | Faible |
| Probabilité | Moyenne | Faible |
| Criticité | Élevée | Faible |
| Actifs concernés | Tables sensibles, base logs | Protégés |

---

## 6. Vérification après correction

Commandes de vérification disponibles dans `commands.sql` (section VÉRIFICATION).

---

## 7. Remédiations générales

- Appliquer le moindre privilège sur tous les rôles
- Séparer les rôles applicatifs et administratifs
- Auditer régulièrement les privilèges (`\du`, `information_schema`)
- Utiliser des mots de passe forts et les renouveler régulièrement
- Activer SCRAM-SHA-256 comme méthode de chiffrement
- Journaliser les actions sensibles (pg_audit en production)
- Désactiver ou supprimer les comptes inutilisés

---

## 8. Compétences démontrées

- Audit de permissions PostgreSQL
- Identification de risques liés aux droits excessifs
- Application du principe du moindre privilège
- Documentation technique orientée remédiation
- Vérification post-correction
