program scwinst64;

{$APPTYPE CONSOLE}
{.$R *.res}

{$R 'Installer64.res' 'Installer64.rc'}

uses
  SysUtils,
  Classes,
  Registry;

const
  app = 'Software\Google\Chrome\NativeMessagingHosts';
  mnf = '\AppData\Local\Shortcutware\manifest64.json';

  AppPath = '\AppData\Local\Shortcutware\';
  AppExe = 'Flexkbd64.exe';
  AppDll = 'Flexkbd64.dll';
  Manifest = 'manifest64.json';

var
  prof: String;

procedure ResSaveFile(resName, resType, fileName: String);
var
  rs: TResourceStream;
begin
  rs:= TResourceStream.Create(hInstance, resName, PAnsiChar(resType));
  try
    rs.SaveToFile(prof + AppPath + fileName);
  finally
    rs.Free;
  end;
end;

var
  reg: TRegIniFile;
begin
  reg:= TRegIniFile.Create(app);
  try
    try
      prof:= GetEnvironmentVariable('USERPROFILE');
      reg.WriteString('com.scware.nmhost64', '', prof + mnf);
      ForceDirectories(prof + AppPath);
      ResSaveFile('AppExe'  , 'EXE' , AppExe);
      ResSaveFile('AppDll'  , 'DLL' , AppDll);
      ResSaveFile('Manifest', 'JSON', Manifest);
      Writeln('Shortcutware setup succeeded. Press any key to exit.');
    except
      on E: EFCreateError do
        Writeln('Error! Files are in use. Press any key to exit.');
      on E: Exception do
        Writeln(E.ClassName + ': ' + E.Message + ' Press any key to exit.');
    end;
    Readln;
  finally
    reg.Free;
  end;
end.
