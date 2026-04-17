# 🧠 SQL Analyzer (Flex + Bison + Flask)

Ce projet est un **analyseur de requêtes SQL** développé avec :

* 🔧 **Flex** (analyse lexicale)
* 🧠 **Bison** (analyse syntaxique + sémantique)
* 🌐 **Flask (Python)** pour l’API
* 💻 Interface web interactive

---

## ✨ Fonctionnalités

* Analyse **lexicale, syntaxique et sémantique**
* Support des requêtes :

  * SELECT
  * UPDATE
  * DELETE
* Détection des erreurs :

  * ❌ Lexicales
  * ❌ Syntaxiques
  * ⚠️ Sémantiques (tables inexistantes)
* Statistiques :

  * Nombre de SELECT / UPDATE / DELETE
  * Nombre de clauses WHERE

---

## 📁 Structure du projet

```
.
├── sql2.l                         # Analyseur lexical (Flex)
├── sql2.y                         # Analyseur syntaxique (Bison)
├── server.py                      # API Flask
├── sql_analyser_interface.html    # Interface web
├── README.md
```

---

## ⚙️ Prérequis

Installer :

```bash
sudo apt install flex bison gcc python3 python3-pip
pip install flask flask-cors
```

---

## 🔨 Compilation

```bash
bison -d sql2.y
flex sql2.l
gcc sql2.tab.c lex.yy.c -o sql2 -lfl
```

---

## ▶️ Lancer le serveur

```bash
python3 server.py
```

Le serveur démarre sur :

```
http://localhost:5000
```

---

## 🌐 Utilisation

1. Ouvrir le fichier :

```
sql_analyser_interface.html
```

2. Saisir une requête SQL

Exemple :

```sql
SELECT nom, prenom 
FROM employes 
WHERE salaire > 3000;
```

3. Cliquer sur **Analyser**

---

## 📊 Exemple de résultat

* ✅ Requête valide
* ⚠️ Avertissement si table inexistante
* ❌ Erreur syntaxique détectée

---

## 🧪 Tables disponibles

* `employes`
* `departements`

---

## ⚠️ Remarques

* Ce projet est un **analyseur pédagogique**
* Il ne se connecte pas à une vraie base de données

---

## 👨‍💻 Auteur

* Projet réalisé dans le cadre du module de compilation
