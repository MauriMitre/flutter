# Script para preparar los íconos de la aplicación

# Crear carpeta si no existe
if (-not (Test-Path -Path "assets\icon")) {
    New-Item -Path "assets\icon" -ItemType Directory -Force
    Write-Host "Carpeta assets\icon creada correctamente" -ForegroundColor Green
}

# Mostrar instrucciones
Write-Host "=== PREPARACIÓN DE ÍCONOS PARA EDIFICIOGEST ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para implementar el ícono de la aplicación, sigue estos pasos:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Guarda la imagen del ícono (con fondo rosa) como:" -ForegroundColor White
Write-Host "   assets\icon\app_icon.png" -ForegroundColor Green
Write-Host ""
Write-Host "2. Guarda la versión con solo los edificios blancos (fondo transparente) como:" -ForegroundColor White
Write-Host "   assets\icon\app_icon_foreground.png" -ForegroundColor Green
Write-Host ""
Write-Host "3. Ejecuta el siguiente comando para generar todos los íconos:" -ForegroundColor White
Write-Host "   flutter pub run flutter_launcher_icons" -ForegroundColor Green
Write-Host ""
Write-Host "4. Reconstruye la aplicación con:" -ForegroundColor White
Write-Host "   flutter clean" -ForegroundColor Green
Write-Host "   flutter pub get" -ForegroundColor Green
Write-Host "   flutter build apk --release" -ForegroundColor Green
Write-Host ""
Write-Host "=== VERIFICACIÓN DE ARCHIVOS ===" -ForegroundColor Cyan

# Verificar si los archivos existen
if (Test-Path -Path "assets\icon\app_icon.png") {
    Write-Host "✓ app_icon.png encontrado" -ForegroundColor Green
} else {
    Write-Host "✗ app_icon.png no encontrado" -ForegroundColor Red
    Write-Host "  Por favor, guarda el ícono principal en assets\icon\app_icon.png" -ForegroundColor Yellow
}

if (Test-Path -Path "assets\icon\app_icon_foreground.png") {
    Write-Host "✓ app_icon_foreground.png encontrado" -ForegroundColor Green
} else {
    Write-Host "✗ app_icon_foreground.png no encontrado" -ForegroundColor Red
    Write-Host "  Por favor, guarda el ícono de primer plano en assets\icon\app_icon_foreground.png" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Presiona cualquier tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 