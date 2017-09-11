@echo off
setlocal EnableDelayedExpansion
for /L %%n in (1 1 500) do if "!__cd__:~%%n,1!" neq "" set /a "len=%%n+1"
setlocal DisableDelayedExpansion
for /r . %%g in (*.wr*) do (
  set "absPath=%%g"
  setlocal EnableDelayedExpansion
  set "relPath=!absPath:~%len%!"
  del "!relPath!.temp" 2>nul
  echo "Json Pretty >> !relPath!"
  tidyjson "!relPath!" >> "!relPath!.temp" 
  del "!relPath!"
  ren "!relPath!.temp" "%%~nxg"
  endlocal
)