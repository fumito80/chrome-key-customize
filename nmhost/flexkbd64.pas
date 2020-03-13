program flexkbd64;

{.$MODE Delphi}

{$APPTYPE CONSOLE}
{.$R *.res}
{$CODEPAGE UTF8}
{$LONGSTRINGS ON}

uses
  SysUtils,
  Messages,
  Windows,
  StrUtils,
  ShellApi,
  Common,
  Classes,
  fpjson, jsonparser;

type
  TEnv = record
    keyPipeName: string;
    hFMOBJ: THandle;
    msg: string;
end;

const
  VERSION = '1.0.1';
  MAX_MSG_LEN = 1048576;

function QueryFullProcessImageNameW(Process: THandle; Flags: DWORD; Buffer: PWideChar; Size: PDWORD): Boolean; stdcall; external 'kernel32.dll';
procedure StartConfigMode; external 'Flexkbd64.dll';
procedure EndConfigMode; external 'Flexkbd64.dll';
procedure SetKeyConfig(params: String); stdcall; external 'Flexkbd64.dll';
procedure Initialize(hStdOutIn, threadID: THandle; keyPipeNameIn, mousePipeNameIn: string); stdcall; external 'Flexkbd64.dll';
procedure Destroy; external 'Flexkbd64.dll';

function StringToJSONString(const value: TJSONStringType): TJSONStringType;
var
  ch: AnsiString;
  jsonValue: AnsiString = '';
  i: Integer = 0;
  asc: UInt;
  function utf8dec(utf8Byte: UINT; shift: smallint = 0; mask: UINT = $3F): UINT;
  begin
    Exit ((utf8Byte and mask) shl shift);
  end;
begin
  //Write2EventLog('FlexKbd PostToChrome', value, EVENTLOG_INFORMATION_TYPE);
  while i <= length(value) do begin
    ch:= '';
    case value[i] of
      '/', '\', '"': ch:= '\' + value[i];
      #9:  ch:= '\t';
      #13: ch:= '\n';
    else
      asc:= Ord(value[i]);
      case asc of
        $20..$7E:
          ch:= value[i];
        $C2..$DF: begin
          ch:= '\u' + inttohex(utf8dec(asc, 6, $1F) + utf8dec(ord(value[i + 1])), 4);
          Inc(i);
        end;
        $E0..$EF: begin
          ch:= '\u' + inttohex(utf8dec(asc, 12, $F) + utf8dec(ord(value[i + 1]), 6) + utf8dec(ord(value[i + 2])), 4);
          Inc(i, 2);
        end;
        $F0..$F7: begin
          ch:= '\u' + inttohex(utf8dec(asc, 18, $7) + utf8dec(ord(value[i + 1]), 12) + utf8dec(ord(value[i + 2]), 6) + utf8dec(ord(value[i + 3])), 4);
          Inc(i, 3);
        end;
      end;
    end;
    jsonValue:= jsonValue + ch;
    Inc(i);
  end;
  Exit (jsonValue);
end;

procedure PostToChrome(action: String; value: String);
var
  json: AnsiString;
  sizeOfJson: UInt;
  bytesWrite: UInt = 0;
  B: array of Byte;
  hStdOut: DWORD;
begin
  json:= '{ "action": "' + action + '", "value": "' + StringToJSONString(value) + '" }';
  sizeOfJson:= Length(json);
  SetLength(B, sizeOfJson);
  Move(json[1], B[0], sizeOfJson);
  hStdOut:= GetStdHandle(STD_OUTPUT_HANDLE);
  WriteFile(hStdOut, sizeOfJson, SizeOf(UInt), bytesWrite, nil);
  WriteFile(hStdOut, B[0], sizeOfJson, bytesWrite, nil);
end;

procedure CallShortcut(keyPipeName: string; scanCodeStr: String; subCode: Integer);
var
  dummyFlag: Boolean;
  bytesRead: Cardinal = 0;
  scansInt64, scanCode: UInt64;
  Modifiers: Cardinal;
begin
  try
    if (scanCodeStr <> '') then begin
      scanCode:= StrToInt(Copy(scanCodeStr, 3, 10));
      scansInt64:= scanCode shl 16;
      Modifiers:= StrToInt(LeftBStr(scanCodeStr, 2));
      scansInt64:= scansInt64 + (Modifiers shl 8) + subCode;
      CallNamedPipe(PChar(keyPipeName), @scansInt64, SizeOf(UInt64), @dummyFlag, SizeOf(Boolean), bytesRead, NMPWAIT_NOWAIT);
    end;
  except
  end;
end;

procedure PasteText(keyPipeName: string; text: String);
var
  dummyFlag: Boolean;
  bytesRead: Cardinal = 0;
begin
  if text = '' then Exit;
  gpcStrToClipboard(text);
  CallNamedPipe(PChar(keyPipeName), @g_pasteText, SizeOf(UInt64), @dummyFlag, SizeOf(Boolean), bytesRead, NMPWAIT_NOWAIT);
end;

procedure SetClipboard(text: UTF8String);
begin
  gpcStrToClipboard(text);
end;

procedure GetClipboard;
var
  result: String = '';
begin
  try
    result:= gfnsStrFromClipboard;
  finally
    PostToChrome('result', result);
  end;
end;

procedure Sleep(msec: UInt);
begin
  Windows.Sleep(msec);
end;

procedure ExecUrl(prog, url: String);
begin
  if (prog <> '') then begin
    if (prog = 'edge') then begin
      ShellExecute(0, PChar('open'), PAnsiChar('microsoft-edge:' + url), nil, nil, SW_SHOWNORMAL);
    end
    else begin
      ShellExecute(0, PChar('open'), PAnsiChar(prog), PChar(url), nil, SW_SHOWNORMAL);
    end;
  end;
end;

function exchange_0_2(Src: DWORD): DWORD;
type
  TTemp = array[0..3]of BYTE;
begin
  Result := Src;
  TTemp(Result)[2] := TTemp(Src)[0];
  TTemp(Result)[0] := TTemp(Src)[2];
end;

procedure base64decode(ms: TStream; S: string);
var
  P: PChar;
  I: Integer;

  function decode(code: BYTE): BYTE;
  begin
    case Char(code) of
      'A'..'Z': Result := code - BYTE('A');
      'a'..'z': Result := code - BYTE('a') + 26;
      '0'..'9': Result := code - BYTE('0') + 52;
      '+': Exit (62);
      '/': Exit (63);
    else
      Exit (0);
    end;
  end;

  procedure doNbyte;
  var
    I, N: Integer;
    Dst: DWORD;
  begin
    case Pos('=', P) of
      3: N := 1;
      4: N := 2;
    else
      N := 3;
    end;

    Dst := 0;
    for I := 3 downto 0 do begin
      Inc(Dst, decode(PBYTE(P)^) shl (I * 6));
      Inc(P);
    end;

    Dst := exchange_0_2(Dst);

    ms.Write(Dst, N);
  end;

begin
  P := PChar(S);
  for I := 0 to (Length(S) div 4) - 1 do begin
    doNbyte;
  end;
end;

function EnumFileFromDir(extId: String): String;
const
  extPath2 = '\AppData\Local\Google\Chrome\User Data\Default\Extensions\';
var
  rec: TSearchRec;
  extPath, dir: String;
begin
  extPath:= SysUtils.GetEnvironmentVariable('USERPROFILE') + extPath2 + extId;
  dir:= IncludeTrailingPathDelimiter(extPath);

  if FindFirst(dir + '*.*', faAnyFile, rec) = 0 then begin
    try
      repeat
        if (rec.Attr and faDirectory <> 0) then begin
          if (rec.Name='.') or (rec.Name='..') then begin
            Continue;
          end;
          EnumFileFromDir(dir + rec.Name);
        end else
          if (rec.Name = 'toolbarIcon.png') then begin
            Exit (dir + rec.Name);
          end;
      until (FindNext(rec) <> 0);
    finally
      SysUtils.FindClose(rec);
    end;
  end;
end;

procedure SetIcon(pngFile: string; data: String);
var
  fs: TFileStream;
begin
  if (pngFile <> '') then begin
    Delete(data, 1, 22); // data:image/png;base64,
    fs:= TFileStream.Create(pngFile, fmOpenWrite);
    try
      base64decode(fs, data);
    finally
      fs.Free;
    end;
  end;
end;

function GetChromeThreadID(hParent: HWnd): DWORD;
const
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
var
  className: String;
  exeName: WideString;
  threadID, exeNameLen: DWORD;
  hChild: HWnd = 0;
  pID: DWORD = 0;
  hHandle: THANDLE;
begin
  SetLength(className, MAX_PATH + 1);
  GetClassName(hParent, PChar(className), MAX_PATH);
  SetLength(className, StrLen(PChar(className)));

  if className = CHROME_CLASS_WIDGET then begin
    threadID:= GetWindowThreadProcessId(hParent, pID);
    hHandle:= OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pID);
    exeNameLen:= MAX_PATH;
    SetLength(exeName, MAX_PATH + 1);
    if QueryFullProcessImageNameW(hHandle, 0, PWideChar(exeName), @exeNameLen) then begin
      SetLength(exeName, StrLen(PWideChar(exeName)));
      if (String(exeName).EndsWith('chrome.exe') or String(exeName).EndsWith('msedge.exe')) then begin
        Exit (threadID);
      end;
    end;
  end;

  while true do begin
    hChild:= FindWindowEx(hParent, hChild, nil, nil);
    if hChild = 0 then begin
      Break;
    end;
    threadID:= GetChromeThreadID(hChild);
    if threadID <> 0 then begin
      Exit (threadID);
    end;
  end;

  Exit (0);

end;

function InitApp(hStdOut: UInt): TEnv;
var
  sGuid: string;
  guid: TGUID;
  mousePipeName: string;
  threadID: DWORD;
  env: TEnv;
begin
  try
    with env do begin
      msg:= 'begin CreateFileMapping: ';
      hFMOBJ:= CreateFileMapping(HANDLE($FFFFFFFFFFFFFFFF), nil, PAGE_READWRITE, 0, SizeOf(TShareData), PChar(FILE_MAPPING_NAME));
      if hFMOBJ = 0 then begin
        msg:= 'Error at CerateFileMapping: ' + IntToStr(GetLastOSError);
        Exit (env);
      end;
      CreateGUID(guid);
      sGuid:= GUIDToString(guid);
      sGuid:= AnsiReplaceStr(sGuid, '{', '');
      sGuid:= AnsiReplaceStr(sGuid, '}', '');
      keyPipeName:= '\\.\pipe\' + sGuid + '-kbd';
      mousePipeName:= '\\.\pipe\' + sGuid + '-mus';
      msg:= 'begin GetChromeThreadID: ';
      threadID:= GetChromeThreadID(GetDesktopWindow);
      msg:= 'begin Initialize: ';
      if threadID <> 0 then begin
        Initialize(hStdOut, threadID, keyPipeName, mousePipeName);
      end else begin
        msg:= 'No found running chrome.exe .';
      end;
      msg:= '';
    end;
  except
    on E: Exception do
      env.msg:= env.msg + E.Message;
  end;
  Exit (env);
end;

procedure Main;
var
  hStdIn, hStdOut: UInt;
  msgLen: UInt = 0;
  bytesRead: UInt = 0;
  msg: array[0..MAX_MSG_LEN - 1] of Char;
  command: string;
  js, jsPrm1: TJSONData;
  pngFile: string = '';
  extId: string = 'unknown';
  env: TEnv;

begin
  try
    hStdIn:= GetStdHandle(STD_INPUT_HANDLE);
    hStdOut:= GetStdHandle(STD_OUTPUT_HANDLE);
    FillChar(msg, Sizeof(msg), 0);

    while True do begin
      if not ReadFile(hStdIn, msgLen, SizeOf(UInt), bytesRead, nil) then Break;
      if not ReadFile(hStdIn, msg, msgLen, bytesRead, nil) then Break;

      js:= GetJSON(msg, false);
      try
        command:= js.FindPath('command').AsString;
        jsPrm1 := js.FindPath('prm1');
      except
        on E: Exception do begin
          Break;
        end;
      end;

      //if (jsPrm1 <> nil) then
      //Write2EventLog('FlexKbd command log', UTF8Decode(msg), EVENTLOG_INFORMATION_TYPE);
      if (extId = 'unknown') then begin
        if (command = 'StartApp') then begin
          env:= InitApp(hStdOut);
          if env.msg <> '' then begin
            Write2EventLog('FlexKbd Initialize error', env.msg, EVENTLOG_ERROR_TYPE);
            Break;
          end;
          extId:= jsPrm1.AsString;
          PostToChrome('doneAppInit', VERSION);
        end else if (command = 'GetVersion') then begin
          PostToChrome('version', VERSION);
          Break;
        end else if (command = 'GetClipboard') then begin
          GetClipboard;
          Break;
        end else if (command = 'Terminate') then begin
          PostToChrome('terminatedApp', 'done');
          Break;
        end;
      end else begin
        if (command = 'StartConfigMode') then begin
          StartConfigMode;
        end else if (command = 'GetVersion') then begin
          PostToChrome('version', VERSION);
        end else if (command = 'EndConfigMode') then begin
          EndConfigMode;
        end else if (command = 'SetKeyConfig') then begin
          SetKeyConfig(jsPrm1.AsString);
        end else if (command = 'PasteText') then begin
          PasteText(env.keyPipeName, jsPrm1.AsString);
        end else if (command = 'SetClipboard') then begin
          SetClipboard(jsPrm1.AsString);
        end else if (command = 'GetClipboard') then begin
          GetClipboard;
        end else if (command = 'Sleep') then begin
          Sleep(jsPrm1.AsInt64);
        end else if (command = 'CallShortcut') then begin
          CallShortcut(env.keyPipeName, jsPrm1.AsString, js.FindPath('prm2').AsInteger);
        end else if (command = 'ExecUrl') then begin
          ExecUrl(jsPrm1.AsString, js.FindPath('prm2').AsString);
        end else if (command = 'SetIcon') then begin
          if (pngFile = '') then begin
            pngFile:= EnumFileFromDir(extId);
          end;
          SetIcon(pngFile, jsPrm1.AsString);
        end else if (command = 'StartApp') then begin
          Continue;
        end else begin
          Break;
        end;
      end;
    end;

  finally
    if env.hFMOBJ <> 0 then begin
      Destroy;
      FileClose(env.hFMOBJ); { *Converted from CloseHandle* }
    end;
  end;

end;

// Start Main
begin
  Main;
end.

