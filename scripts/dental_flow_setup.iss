; Dental Flow — Windows installer (Inno Setup 6)
; Local build:
;   flutter build windows --release
;   ISCC.exe scripts\dental_flow_setup.iss
;
; CI build passes /DMyAppVersion /DBuildDir /DOutputDir /DOutputBaseFilename

#ifndef MyAppName
  #define MyAppName "Dental Flow"
#endif

#ifndef MyAppVersion
  #define MyAppVersion "1.0.1"
#endif

#ifndef MyAppPublisher
  #define MyAppPublisher "CodeMind.ahk"
#endif

#ifndef MyAppExeName
  #define MyAppExeName "dental_managment_system.exe"
#endif

#ifndef BuildDir
  #define BuildDir "..\build\windows\x64\runner\Release"
#endif

#ifndef OutputDir
  #define OutputDir "..\release"
#endif

#ifndef OutputBaseFilename
  #define OutputBaseFilename "DentalFlow-setup"
#endif

[Setup]
AppId={{CDC115CE-CAAD-429F-8BC4-FC658D042DB6}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseFilename}
SolidCompression=yes
WizardStyle=modern
Compression=lzma2/ultra64
PrivilegesRequired=admin
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; Exclude MSVC link artifacts if present in the output folder.
Source: "{#BuildDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
