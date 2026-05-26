# PostgreSQL Security Hardening

Exercice de durcissement PostgreSQL réalisé en environnement contrôlé.  
Objectif : identifier des permissions excessives, corriger les accès dangereux et appliquer le principe du moindre privilège.

---

## Contexte

| Élément | Détail |
|---|---|
| Type | Exercice de formation |
| Environnement | Base PostgreSQL de lab fournie dans un cadre pédagogique |
| Périmètre | Autorisé et contrôlé |
| Données sensibles | Supprimées ou anonymisées |

---

## Points traités

- Révision des rôles et utilisateurs
- Suppression de privilèges excessifs (DELETE, INSERT, UPDATE non justifiés)
- Révocation d'accès à des bases sensibles
- Renforcement du chiffrement des mots de passe (SCRAM-SHA-256)
- Documentation des risques et corrections
- Vérification après chaque correction

---

## Structure du dépôt

| Fichier | Contenu |
|---|---|
| `report.md` | Rapport structuré : problèmes identifiés, corrections, analyse de risque |
| `commands.sql` | Commandes SQL anonymisées d'audit et de correction |
| `notes.md` | Référence sur les privilèges et bonnes pratiques PostgreSQL |
| `CHECKLIST.md` | Checklist avant publication |

---

## Compétences démontrées

- Audit de rôles et privilèges PostgreSQL
- Application du principe du moindre privilège
- Révocation d'accès dangereux
- Renforcement du chiffrement des mots de passe
- Documentation technique orientée remédiation

---

## Avertissement

Exercice réalisé dans un cadre légal, éducatif et autorisé.  
Aucune donnée réelle ou sensible n'est publiée dans ce dépôt.
