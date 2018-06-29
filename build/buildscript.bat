call "build\getkdb.bat" || goto :error

if not defined QLIC_KC (
 goto :nokdb
)


set PATH=C:\Miniconda3-x64;C:\Miniconda3-x64\Scripts;%PATH%
mkdir embedpy
cd embedpy
echo getembedpy"latest" 
exit /b 0

:error
echo failed with error 
exit /b 

:nokdb
echo no kdb
exit /b 0
