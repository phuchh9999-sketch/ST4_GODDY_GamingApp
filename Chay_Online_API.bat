@echo off
title Goddy Gaming Hub - Online Cloud Tunnel
echo ========================================================
echo   KHOI DONG DUONG HAM ONLINE CHO WEBAPI GODDY GAMING
echo   (Ket noi xuyen mang 4G / Wi-Fi khac nhau toan quoc)
echo ========================================================
echo.
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel --url http://localhost:5271
pause
