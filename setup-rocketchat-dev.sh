#!/bin/bash

set -e

# === CONFIGURATION ===
NODE_VERSION="22.14.0"
DENO_VERSION="1.37.1"
METEOR_VERSION="3.0"

# === FONCTIONS UTILITAIRES ===
function print_step() {
    echo -e "\n🔧 $1"
}

function check_root() {
    if [ "$EUID" -eq 0 ]; then
        echo "❌ ERREUR : Ce script ne doit PAS être exécuté en tant que root."
        echo "❗ Relancez sans sudo : ./setup-rocketchat-dev.sh"
        exit 1
    fi
}

function check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "❌ $1 est manquant."
        return 1
    else
        echo "✅ $1 détecté : $($1 --version | head -n1)"
        return 0
    fi
}

# === DÉMARRAGE ===
print_step "Vérification des droits utilisateur"
check_root

print_step "1/6 - Mise à jour du système et installation des paquets de base"
sudo apt update && sudo apt dist-upgrade -y
sudo apt install -y git curl unzip make build-essential python3 g++

print_step "2/6 - Installation de NVM, Node.js $NODE_VERSION et Yarn"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    source "$HOME/.bashrc"
fi

source "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"
npm install -g yarn

check_command node
check_command npm
check_command yarn

print_step "3/6 - Installation de Deno $DENO_VERSION"
curl -fsSL https://deno.land/install.sh | sh -s v$DENO_VERSION
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Ajout dans .bashrc si absent
if ! grep -q ".deno" "$HOME/.bashrc"; then
    echo 'export DENO_INSTALL="$HOME/.deno"' >> "$HOME/.bashrc"
    echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> "$HOME/.bashrc"
fi

check_command deno

print_step "4/6 - Installation de Meteor $METEOR_VERSION"
curl https://install.meteor.com/?release=$METEOR_VERSION | sh
check_command meteor

print_step "5/6 - Installation des dépendances du projet Rocket.Chat"
yarn


print_step "🛠 Lecture du fichier .env"
if [ -f .env ]; then
    echo "📦 Chargement des variables d'environnement depuis .env"
    export $(grep -v '^#' .env | xargs)
else
    echo "⚠️ Fichier .env introuvable, certaines variables nécessaires pourraient manquer."
fi

print_step "6/6 - Lancement du serveur de développement"
export OVERWRITE_SETTING_Show_Setup_Wizard=completed
yarn dsv
