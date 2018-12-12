if not defined QLIC_KC (
 goto :nokdb
)

call "build\getkdb.bat" || goto :error

set PATH=C:\Miniconda3-x64;C:\Miniconda3-x64\Scripts;%PATH%
mkdir embedpy
cd embedpy
echo getembedpy"latest" | q ..\build\getembedpy.q -q || goto :error
cd ..
echo p)print('embedpy runs') | q -q || goto :error
exit /b 0

:error
echo failed with error 
exit /b 

:nokdb
echo no kdb
exit /b 0
