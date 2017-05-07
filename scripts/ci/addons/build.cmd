
if "%BUILDER%"=="VS" (
    rem Build the openFrameworks lib with VS logging.
    msbuild libs/openFrameworksCompiled/project/vs/openframeworksLib.vcxproj  /verbosity:minimal /logger:"C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll"

    rem Build each example with VS logging.
    for /D %%e in (addons\%OF_ADDON_NAME%\example*) do (
        msbuild %%e/%%~ne.vcxproj  /verbosity:minimal /logger:"C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll"
    )
)

if "%BUILDER%"=="MSYS2" (
    rem Build each example, will trigger the openFrameworks lib build if not yet built.
    for /D %%e in (addons\%OF_ADDON_NAME%\example*) do (
        rem Temporarily unset the OF_ROOT, which is a windows path and rely on the makefiles to determine a posix OF_ROOT.
        set TMP_OF_ROOT=%OF_ROOT%
        set OF_ROOT=
        %MSYS2_PATH%\usr\bin\bash -lc "make -C addons/%OF_ADDON_NAME%/%%~ne Debug"
        set OF_ROOT=%TMP_OF_ROOT%
        set TMP_OF_ROOT=
    )
)
