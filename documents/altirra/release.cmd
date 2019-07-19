@echo off
setlocal enableextensions enabledelayedexpansion

rem ---echo banner
echo Altirra Build Release Utility Version 3.20
echo Copyright (C) Avery Lee 2014-2019. Licensed under GNU General Public License
echo.

rem ---parse command line arguments
set _incremental=false
set _packonly=false
set _verid=
set _anyvc=false
set _checkvc=false
set _arm64=false
set _clversionexp=19.16.27031.1
set _clversionexpdesc=Visual Studio 2017 Version 15.9.12

:arglist
if "%1"=="" goto endargs

if "%1"=="/packonly" (
	set _packonly=true
) else if "%1"=="/inc" (
	set _incremental=true
) else if "%1"=="/anyvc" (
	set _anyvc=true
) else if "%1"=="/checkvc" (
	set _checkvc=true
) else if "%1"=="/arm64" (
	set _arm64=true
) else if "%1"=="/?" (
	goto :usage
) else if "%1"=="/h" (
	goto :usage
) else if "!_verid!"=="" (
	set _verid=%1
) else (
	goto :usage
)

shift /1
goto :arglist

:usage
echo Usage: release [/inc] [/packonly] [/anyvc] [/checkvc] [/arm64] ^<version-id^>
echo.
exit /b 5

:endargs
if "!_checkvc!"=="false" (
	if "!_verid!"=="" goto :usage
)

@where /q devenv.exe >nul
if errorlevel 1 (
	echo Unable to find Visual C++ IDE ^(devenv.exe^) in current path.
	exit /b 5
)

if "!_anyvc!"=="false" (
	set _clversion=unknown
	for /f "tokens=7 usebackq delims= " %%x in (`cl /? 2^>^&1 ^| findstr "Optimizing Compiler"`) do set _clversion=%%x

	if not "!_clversion!"=="!_clversionexp!" (
		echo Error: Unexpected version of Visual C/C++ compiler.
		echo.
		echo   Expected: !_clversionexp! ^(!_clversionexpdesc!^)
		echo   Detected: !_clversion!
		echo.
		echo If this is expected, use the /anyvc switch to override the version check.
		exit /b 5
	)
	
	if "!_checkvc!"=="true" (
		echo   Expected: !_clversionexp! ^(!_clversionexpdesc!^)
		echo   Detected: !_clversion!
		exit /b 0
	)
)

@where /q zip.exe >nul
if errorlevel 1 (
	echo Unable to find Info-Zip ^(zip.exe^) in current path.
	exit /b 5
)

@where /q advzip.exe >nul
if errorlevel 1 (
	echo Unable to find advancecomp ^(advzip.exe^) in current path.
	exit /b 5
)

if not exist out md out
if not exist out\debug md out\debug
if not exist out\release md out\release
if not exist publish md publish

if not "!_packonly!"=="true" (
	if exist publish\build.log del publish\build.log
	if exist publish\build-x64.log del publish\build-x64.log
)

if exist publish\Altirra-!_verid!-src.zip del publish\Altirra-!_verid!-src.zip
if exist publish\Altirra-!_verid!.zip del publish\Altirra-!_verid!.zip

set _abverfile=src\Altirra\autobuild\version.h

if not exist src\Altirra\autobuild md src\Altirra\autobuild
if not exist src\Kernel\autobuild md src\Kernel\autobuild

if not "!_incremental!"=="true" (
	if not "!_packonly!"=="true" (
		devenv src\Altirra.sln /Clean Release^|Win32
		devenv src\Altirra.sln /Clean Release^|x64
	)
)

echo #ifndef AT_VERSION_H >%_abverfile%
echo #define AT_VERSION_H >>%_abverfile%
echo #define AT_VERSION "%_verid%" >>%_abverfile%

echo "%_verid%" | find "-" >nul
if errorlevel 1 (
	echo #define AT_VERSION_PRERELEASE 0 >>%_abverfile%
) else (
	echo #define AT_VERSION_PRERELEASE 1 >>%_abverfile%
)

echo #endif >>%_abverfile%

if not !_packonly!==true (
	devenv src\Altirra.sln /Build Release^|Win32 /Project Kernel /Out publish\build-kernel.log
	if errorlevel 1 (
		call :reportBuildFailure publish\build-debug.log
		goto :cleanup
	)

	if "!_incremental!"=="true" (
		set _buildswitch=/Build
	) else (
		set _buildswitch=/Rebuild
	)

	devenv src\Altirra.sln !_buildswitch! Release^|Win32 /Out publish\build.log
	if errorlevel 1 (
		call :reportBuildFailure publish\build.log
		goto :cleanup
	)

	devenv src\Altirra.sln !_buildswitch! Release^|x64 /Out publish\build-x64.log
	if errorlevel 1 (
		call :reportBuildFailure publish\build-x64.log
		goto :cleanup
	)

	if !_arm64!==true (
		devenv src\Altirra.sln !_buildswitch! Release^|ARM64 /Out publish\build-arm64.log
		if errorlevel 1 (
			call :reportBuildFailure publish\build-arm64.log
			goto :cleanup
		)
	)

	devenv src\ATHelpFile.sln !_buildswitch! Release /Out publish\build-help.log
	if errorlevel 1 (
		call :reportBuildFailure publish\build-x64-debug.log
		goto :cleanup
	)
)

zip -9 -X -r publish\Altirra-!_verid!-src.zip ^
	assets ^
	src ^
	src\Kasumi\data\Tuffy.* ^
	src\Kernel\Makefile ^
	Copying ^
	-i ^
	*.vcxproj ^
	*.vcxproj.filters ^
	*.sln ^
	*.cpp ^
	*.h ^
	*.fx ^
	*.props ^
	*.xml ^
	*.targets ^
	*.asm ^
	*.xasm ^
	*.rc ^
	*.asm64 ^
	*.inl ^
	*.fxh ^
	*.vdfx ^
	*.inc ^
	*.k ^
	*.txt ^
	*.bmp ^
	*.png ^
    *.jpg ^
	*.ico ^
	*.cur ^
	*.manifest ^
	*.s ^
	*.pcm ^
	*.bas ^
	*.html ^
	*.natvis ^
	*.vs ^
	*.ps ^
	*.vsh ^
	*.psh ^
	*.cmd ^
	*.svg ^
	*.atcpengine

if errorlevel 1 (
	echo Packaging step failed.
	exit /b 0
)

zip -9 -X publish\Altirra-!_verid!-src.zip ^
	Copying ^
	release.cmd ^
	src\.editorconfig ^
	src\BUILD-HOWTO.html ^
	src\Kasumi\data\Tuffy.* ^
	src\Kernel\source\shared\atarifont.bin ^
	src\Kernel\source\shared\atariifont.bin ^
	src\atbasic\Makefile ^
	src\Kernel\Makefile ^
	src\ATHelpFile\source\*.xml ^
	src\ATHelpFile\source\*.xsl ^
	src\ATHelpFile\source\*.css ^
	src\ATHelpFile\source\*.hhp ^
	src\ATHelpFile\source\*.hhw ^
	src\ATHelpFile\source\*.hhc ^
	src\Altirra\res\altirraexticons.res ^
	localconfig\example\*.props ^
	out\release\kernel.rom

if errorlevel 1 (
	echo Packaging step failed.
	exit /b 0
)

advzip -z -3 publish\Altirra-!_verid!-src.zip

if errorlevel 1 (
	echo Packaging step failed.
	exit /b 0
)

zip -9 -X -j publish\Altirra-!_verid!.zip ^
	out\release\Altirra.exe ^
	out\releaseamd64\Altirra64.exe ^
	Copying ^
	out\Helpfile\Altirra.chm ^
	out\Release\Additions.atr

if errorlevel 1 (
	echo Packaging step failed.
	exit /b 0
)

advzip -z -3 publish\Altirra-!_verid!.zip

if errorlevel 1 (
	echo Packaging step failed.
	exit /b 0
)

copy out\release\Altirra.pdb publish\Altirra-!_verid!.pdb
copy out\releaseamd64\Altirra64.pdb publish\Altirra64-!_verid!.pdb

if !_arm64!==true (
	zip -9 -X -j publish\Altirra-!_verid!-ARM64.zip ^
		out\releasearm64\AltirraARM64.exe ^
		Copying ^
		out\Helpfile\Altirra.chm ^
		out\Release\Additions.atr

	if errorlevel 1 (
		echo Packaging step failed.
		exit /b 0
	)

	advzip -z -3 publish\Altirra-!_verid!-ARM64.zip

	if errorlevel 1 (
		echo Packaging step failed.
		exit /b 0
	)

	copy out\releasearm64\AltirraARM64.pdb publish\AltirraARM64-!_verid!.pdb
)

dir publish
if exist src\Altirra\autobuild\version.h del src\Altirra\autobuild\version.h
if exist src\Kernel\autobuild\version.h del src\Kernel\autobuild\version.h
exit /b 0

:reportBuildFailure
echo.
echo ============ BUILD FAILED ============

findstr /r "^[0-9]*>*[a-zA-Z0-9:\/]*[ ]*\([0-9][0-9]*\).*error.*" "%1"
findstr /l "fatal error LNK" "%1"
echo ============ BUILD FAILED ============
goto :cleanup

:cleanup
if exist src\Altirra\autobuild\version.h del src\Altirra\autobuild\version.h
exit /b 5
