from flask import Flask, request, jsonify
from flask_cors import CORS
import subprocess
import tempfile
import os
import re

app = Flask(__name__)
CORS(app)  # autorise les requêtes depuis le navigateur

BINAIRE = './sql2'

def parser_sortie(stdout, stderr):
    """Extrait les infos utiles des sorties du programme."""
    resultat = {
        'ok': True,
        'messages': [],
        'erreurs_syntaxiques': [],
        'erreurs_semantiques': [],
        'erreurs_lexicales': [],
        'stats': {
            'select': 0, 'update': 0,
            'delete': 0, 'where': 0
        }
    }

    for ligne in stderr.splitlines():
        if '[ERREUR SYNTAXIQUE]' in ligne:
            resultat['erreurs_syntaxiques'].append(ligne.strip())
            resultat['ok'] = False
        elif '[ERREUR SEMANTIQUE]' in ligne:
            resultat['erreurs_semantiques'].append(ligne.strip())
        elif '[ERREUR LEXICALE]' in ligne:
            resultat['erreurs_lexicales'].append(ligne.strip())
            resultat['ok'] = False

    for ligne in stdout.splitlines():
        if '[OK]' in ligne:
            resultat['messages'].append(ligne.strip())
        m = re.search(r'SELECT\s*:\s*(\d+)', ligne)
        if m: resultat['stats']['select'] = int(m.group(1))
        m = re.search(r'UPDATE\s*:\s*(\d+)', ligne)
        if m: resultat['stats']['update'] = int(m.group(1))
        m = re.search(r'DELETE\s*:\s*(\d+)', ligne)
        if m: resultat['stats']['delete'] = int(m.group(1))
        m = re.search(r'WHERE\s*:\s*(\d+)', ligne)
        if m: resultat['stats']['where'] = int(m.group(1))

    return resultat

@app.route('/analyse', methods=['POST'])
def analyse():
    data = request.get_json()
    sql = data.get('sql', '').strip()

    if not sql:
        return jsonify({'ok': False, 'erreur': 'Requête vide'}), 400

    # Écrire la requête dans un fichier temporaire
    with tempfile.NamedTemporaryFile(mode='w', suffix='.sql',
                                     delete=False, encoding='utf-8') as f:
        f.write(sql)
        chemin = f.name

    try:
        proc = subprocess.run(
            [BINAIRE, chemin],
            capture_output=True,
            text=True,
            timeout=5  # sécurité : 5 secondes max
        )
        resultat = parser_sortie(proc.stdout, proc.stderr)
        resultat['stdout_brut'] = proc.stdout
        resultat['stderr_brut'] = proc.stderr
        return jsonify(resultat)

    except subprocess.TimeoutExpired:
        return jsonify({'ok': False, 'erreur': 'Timeout — requête trop longue'}), 500
    except FileNotFoundError:
        return jsonify({'ok': False, 'erreur': f'Binaire {BINAIRE} introuvable'}), 500
    finally:
        os.unlink(chemin)  # toujours supprimer le fichier temp

@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
