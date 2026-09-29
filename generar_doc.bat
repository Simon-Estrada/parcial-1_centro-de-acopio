@echo off

echo {application, util, [{modules, ['Elixir.Util']}]} > util.app

ex_doc "Util" "1.0.0" . -m "Util" -o doc

if errorlevel 1 (
    echo.
    echo Error generando la documentacion.
    pause
    exit /b 1
)

cd doc

start "" index.html

