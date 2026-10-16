#!/usr/bin/env sh
# ==============================================================================
# SCRIPT DE CONFIGURACIÓN DE SEGURIDAD LOCAL Y GLOBAL PARA GIT (BASH)
# ==============================================================================

echo "Configurando Git Hooks de Seguridad para este repositorio..."

# Asignar permisos de ejecución al hook
chmod +x .githooks/pre-commit 2>/dev/null

# Configurar este repositorio para usar .githooks
git config core.hooksPath .githooks

echo "✅ Git hooks configurados exitosamente para este proyecto (.githooks)."
echo ""
echo "Para proteger TODOS tus proyectos en este equipo (Globalmente), ejecuta:"
echo "git config --global core.hooksPath $(pwd)/.githooks"
