# ==============================================================================
# SCRIPT DE CONFIGURACIÓN DE SEGURIDAD LOCAL Y GLOBAL PARA GIT
# ==============================================================================

Write-Host "Configurando Git Hooks de Seguridad para este repositorio..." -ForegroundColor Cyan

# Configurar este repositorio para usar la carpeta .githooks
git config core.hooksPath .githooks

Write-Host "✅ Git hooks configurados exitosamente para este proyecto (.githooks)." -ForegroundColor Green
Write-Host ""
Write-Host "Para proteger TODOS tus proyectos en esta computadora (Globalmente):" -ForegroundColor Yellow
Write-Host "Ejecuta en tu terminal PowerShell:" -ForegroundColor White
Write-Host "git config --global core.hooksPath C:\APPS\ATRIO\.githooks" -ForegroundColor Yellow
Write-Host ""
Write-Host "De esta forma, cualquier 'git commit' en cualquier carpeta verificará" -ForegroundColor White
Write-Host "automáticamente que no se filtren secretos ni API keys." -ForegroundColor White
