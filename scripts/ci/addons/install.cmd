%MSYS2_PATH%\usr\bin\bash -lc "pacman --noconfirm -S --needed unzip rsync"

rem Install the addon in the addons folder.
move %APPVEYOR_BUILD_FOLDER% %OF_ROOT%\addons\%APPVEYOR_PROJECT_NAME%

if "%BUILDER%"=="VS" (
    rem set PATH="C:\Program Files (x86)\MSBuild\14.0\Bin;%PATH%"
    %MSYS2_PATH%\usr\bin\bash -lc "scripts/vs/download_libs.sh --silent"

    rem Download and set up the project generator.
    set PG_OF_PATH=%OF_ROOT%
    %MSYS2_PATH%\usr\bin\bash -lc "wget http://ci.openframeworks.cc/projectGenerator/projectGenerator-vs.zip -nv"
    %MSYS2_PATH%\usr\bin\bash -lc "unzip -qq projectGenerator-vs.zip"
    rm projectGenerator-vs.zip

    rem Install any addon-specific dependencies.
    if exist addons\%OF_ADDON_NAME%\scripts\ci\install.sh (
      rem Temporarily unset the OF_ROOT, which is a windows path and rely on the makefiles to determine a posix OF_ROOT.
      set TMP_OF_ROOT=%OF_ROOT%
      set OF_ROOT=
      call %MSYS2_PATH%\usr\bin\bash -lc "addons/%OF_ADDON_NAME%/scripts/ci/install.sh"
      set OF_ROOT=%TMP_OF_ROOT%
      set TMP_OF_ROOT=
    )

    rem Windows batch install script, if it exists.
    if exist addons\%OF_ADDON_NAME%\scripts\ci\install.bat call addons\%OF_ADDON_NAME%\scripts\ci\install.bat
    rem Windows Powershell script, if it exists.
    if exist addons\%OF_ADDON_NAME%\scripts\ci\install.ps call addons\%OF_ADDON_NAME%\scripts\ci\install.ps

    rem Install any addon-platform-specific dependencies.
    if exist addons\%OF_ADDON_NAME%\scripts\ci\vs\install.sh (
       rem Temporarily unset the OF_ROOT, which is a windows path and rely on the makefiles to determine a posix OF_ROOT.
       set TMP_OF_ROOT=%OF_ROOT%
       set OF_ROOT=
       call %MSYS2_PATH%\usr\bin\bash -lc "addons/%OF_ADDON_NAME%/scripts/ci/vs/install.sh"
       set OF_ROOT=%TMP_OF_ROOT%
       set TMP_OF_ROOT=
    )

    rem Windows batch install script, if it exists.
    if exist addons\%OF_ADDON_NAME%\scripts\ci\vs\install.bat call addons\%OF_ADDON_NAME%\scripts\ci\vs\install.bat
    rem Windows Powershell script, if it exists.
    if exist addons\%OF_ADDON_NAME%\scripts\ci\vs\install.ps call addons\%OF_ADDON_NAME%\scripts\ci\vs\install.ps

    rem Generate VS Solutions for each example in the addon folder.
    for /D %%e in (addons\%OF_ADDON_NAME%\example*) do (
        projectGenerator.exe %%e
    )
)

if "%BUILDER%"=="MSYS2" (
    rem Install platform dependencies.
    %MSYS2_PATH%\usr\bin\bash -lc "scripts/msys2/install_dependencies.sh --noconfirm"

    rem Install 3rd party libraries.
    %MSYS2_PATH%\usr\bin\bash -lc "scripts/msys2/download_libs.sh --silent"

    rem Install any addon-specific dependencies.
    if exist addons\%OF_ADDON_NAME%\scripts\ci\install.sh (
        rem Temporarily unset the OF_ROOT, which is a windows path and rely on the makefiles to determine a posix OF_ROOT.
        set TMP_OF_ROOT=%OF_ROOT%
        set OF_ROOT=
        %MSYS2_PATH%\usr\bin\bash -lc "addons/%OF_ADDON_NAME%/scripts/ci/install.sh"
        set OF_ROOT=%TMP_OF_ROOT%
        set TMP_OF_ROOT=
    )

    rem Install any addon-platform-specific dependencies.
    if exist addons\%OF_ADDON_NAME%\scripts\ci\msys2\install.sh (
        rem Temporarily unset the OF_ROOT, which is a windows path and rely on the makefiles to determine a posix OF_ROOT.
        set TMP_OF_ROOT=%OF_ROOT%
        set OF_ROOT=
        %MSYS2_PATH%\usr\bin\bash -lc "addons/%OF_ADDON_NAME%/scripts/ci/msys2/install.sh"
        set OF_ROOT=%TMP_OF_ROOT%
        set TMP_OF_ROOT=
    )

    rem Copy project Makefiles into addon example directories.
    for /D %%e in (addons\%OF_ADDON_NAME%\example*) do (
        copy scripts\templates\msys2\Makefile %%e\Makefile
        copy scripts\templates\msys2\config.make %%e\config.make
    )
)
