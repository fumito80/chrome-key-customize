unit Common;

{.$MODE Delphi}
{$CODEPAGE UTF8}
{$LONGSTRINGS ON}

interface

uses
  SysUtils, Classes, SyncObjs, Windows, JwaWinUser;

type

  TKeyConfig = class
  public
    mode, origin, orgModified: string;
    modifierFlags: Byte;
    scanCode: Cardinal;
    constructor Create(
      mode,
      origin,
      orgModified: string;
      modifierFlags: Byte;
      scanCode: Cardinal
    );
  end;

  TArrayCardinal = array of Cardinal;

  THookTh = class(TThread)
  protected
    modifierRelCount, seq: Integer;
    virtualModifires, virtualOffModifires: Byte;
    virtualScanCode, kbdLayout: Cardinal;
    pipeName: string;
    keyConfigList: TStringList;
    configMode, virtualOffModifiresFlag: Boolean;
    lastTarget, lastModified, lastOrgModified: string;
    criticalSection: SyncObjs.TCriticalSection;
    hStdOut: THandle;
    scans: string;
    scanCode: Cardinal;
    modifierFlags, modifiersBoth, modifierFlags2: Byte;
    keyConfig: TKeyConfig;
    keyDownState, index: Integer;
    KeyInputs: array of TInput;
    KeyInputCount: Integer;
    newScans: TArrayCardinal;
    scriptMode, keydownMode, createdKeyConfig: Boolean;
    procedure PostToChrome(action, value: String);
    procedure KeybdInput(scanCode: Cardinal; Flags: DWord);
    procedure ReleaseModifier(vkCode, scanCode: Cardinal; Flags: DWord);
    procedure AddScan(scan: Cardinal);
    function VaridateEvent(wPrm: UInt64): Boolean; virtual; abstract;
    procedure Execute; override;
  public
    constructor Create(pipeName: string; hStdOut: THandle; keyConfigList: TStringList; configMode: Boolean);
  end;

  TShareData = record
    hookKey, hookMouse, hookMouseWheel: HHOOK;
    keyPipeName, mousePipeName: array[0..255] of AnsiChar;
    inWheelTabArea: Boolean;
  end;
  pShareData = ^TShareData;

const
  FILE_MAPPING_NAME = 'scware1';
  CHROME_CLASS_NAME = 'Chrome_WidgetWin_1';
  INPUT_KEYBOARD = 1;

  SCAN_LCONTROL  =  $1D;
  SCAN_RCONTROL  = $11D;
  SCAN_LMENU     =  $38;
  SCAN_RMENU     = $138;
  SCAN_LSHIFT    =  $2A;
  SCAN_RSHIFT    =  $36;
  SCAN_LWIN      = $15B;
  SCAN_RWIN      = $15C;
  FLAG_CONTROL   = 1;
  FLAG_MENU      = 2;
  FLAG_SHIFT     = 4;
  FLAG_WIN       = 8;

var
  modifiersCode: array[0..7] of Cardinal;
  g_configMode: Boolean;
  g_destroy     : UInt64 =  0;
  g_reloadConfig: UInt64 =  1;
  g_pasteText   : UInt64 =  2;
  g_callShortcut: UInt64 =  4;
  g_keydown     : UInt64 =  8;
  g_wheelAreaIn : UInt64 = 16;
  g_wheelAreaOut: UInt64 = 32;

procedure gpcStrToClipboard(const sWText: String);
function gfnsStrFromClipboard: String;
procedure Write2EventLog(Source, Msg: string; eventType: Integer = EVENTLOG_ERROR_TYPE);

implementation

constructor TKeyConfig.Create(mode, origin, orgModified: string; modifierFlags: Byte; scanCode: Cardinal);
begin
  Self.mode:= mode;
  Self.origin:= origin;
  Self.orgModified:= orgModified;
  Self.modifierFlags:= modifierFlags;
  Self.scanCode:= scanCode;
end;

constructor THookTh.Create(pipeName: string; hStdOut: THandle; keyConfigList: TStringList; configMode: Boolean);
begin
  FreeOnTerminate:= False;
  Self.pipeName:= pipeName;
  Self.hStdOut:= hStdOut;
  Self.keyConfigList:= keyConfigList;
  Self.configMode:= configMode;
  kbdLayout:= GetKeyboardLayout(0);
  criticalSection:= SyncObjs.TCriticalSection.Create;
  modifierRelCount:= -1;
  inherited Create(False);
end;

procedure THookTh.PostToChrome(action, value: String);
var
  json: string;
  sizeOfJson, bytesWrite: UInt;
begin
  json:= '{"action": "' + action + '", "value": "' + value + '"}';
  sizeOfJson:= Length(json);
  bytesWrite:= 0;
  WriteFile(hStdOut, sizeOfJson, SizeOf(UInt), bytesWrite, nil);
  WriteFile(hStdOut, json[1], sizeOfJson, bytesWrite, nil);
end;

procedure THookTh.KeybdInput(scanCode: Cardinal; Flags: DWord);
begin
  Inc(KeyInputCount);
  SetLength(KeyInputs, KeyInputCount);
  KeyInputs[KeyInputCount - 1].type_ := INPUT_KEYBOARD;
  with KeyInputs[KeyInputCount - 1].ki do begin
    wVk:= MapVirtualKeyEx(scanCode, 3, kbdLayout);
    wScan:= scanCode;
    dwFlags:= Flags;
    if scanCode > $100 then begin
      dwFlags:= dwFlags or KEYEVENTF_EXTENDEDKEY;
      wScan:= wScan - $100;
      wVk:= MapVirtualKeyEx(wScan, 3, kbdLayout);
    end;
    time:= 0;
    dwExtraInfo:= 0;
  end;
end;

procedure THookTh.ReleaseModifier(vkCode, scanCode: Cardinal; Flags: DWord);
begin
  Inc(KeyInputCount);
  SetLength(KeyInputs, KeyInputCount);
  KeyInputs[KeyInputCount - 1].type_:= INPUT_KEYBOARD;
  with KeyInputs[KeyInputCount - 1].ki do begin
    wVk:= vkCode;
    wScan:= scanCode;
    dwFlags:= KEYEVENTF_KEYUP or Flags;
    time:= 0;
    dwExtraInfo:= 0;
  end;
end;

procedure THookTh.AddScan(scan: Cardinal);
begin
  SetLength(newScans, Length(newScans) + 1);
  newScans[Length(newScans) - 1]:= scan;
end;

procedure THookTh.Execute;
var
  wPrm: UInt64 = 0;
  bytesRead: Cardinal = 0;
  bytesWrite: Cardinal = 0;
  cancelFlag: Boolean;
  pipeHandle: THandle;
begin
  pipeHandle:= CreateNamedPipe(
    PAnsiChar(pipeName), PIPE_ACCESS_DUPLEX,
    PIPE_TYPE_MESSAGE or PIPE_READMODE_MESSAGE or PIPE_WAIT,
    1, 255, 255,
    10000, nil
  );
  if pipeHandle = INVALID_HANDLE_VALUE then begin
    //Write2EventLog('FlexKbd', 'Error: CreateNamedPipe');
    Exit;
  end;
  while True do begin
    if ConnectNamedPipe(pipeHandle, nil) then begin
      try
        if ReadFile(pipeHandle, wPrm, SizeOf(UInt64), bytesRead, nil) then begin
          cancelFlag:= False;
          try
            if wPrm = g_destroy then begin // Destroy
              Break;
            end else if wPrm = g_reloadConfig then begin // Config reload
              criticalSection.Acquire;
              Self.configMode:= g_configMode;
              Self.keyConfigList:= keyConfigList;
              criticalSection.Release;
              Continue;
            end else if wPrm = g_pasteText then begin // Paste Text
              VaridateEvent(wPrm);
              Continue;
            end else begin
              cancelFlag:= VaridateEvent(wPrm);
            end;
          finally
            WriteFile(pipeHandle, cancelFlag, SizeOf(Boolean), bytesWrite, nil);
          end;
        end else begin
          //Write2EventLog('FlexKbd', 'Read named pipe: ' + pipeName);
          Break;
        end;
      finally
        DisconnectNamedPipe(pipeHandle);
      end;
    end else begin
      //Write2EventLog('FlexKbd', 'Error: Connect named pipe: ' + pipeName);
      Break;
    end;
    if Terminated then Break;
  end;
  FileClose(pipeHandle); { *Converted from CloseHandle* }
end;

function gfnsStrFromClipboard: String;
var
  li_Format: array[0..1] of UInt;
  li_Text: Integer;
  lh_Clip, lh_Data: THandle;
  lp_Clip, lp_Data: Pointer;
begin
  Result := '';
  li_Format[0] := CF_UNICODETEXT;
  li_Format[1] := CF_TEXT;
  li_Text := GetPriorityClipboardFormat(li_Format, 2);
  if (li_Text > 0) then begin
    if (OpenClipboard(GetActiveWindow)) then begin
      lh_Clip := GetClipboardData(li_Text);
      if (lh_Clip <> 0) then begin
        lh_Data := 0;
        if (GlobalFlags(lh_Clip) <> GMEM_INVALID_HANDLE) then begin
          try
            if (li_Text = CF_UNICODETEXT)  then begin
              //Unicode
              lh_Data := GlobalAlloc(GHND or GMEM_SHARE, GlobalSize(lh_Clip));
              lp_Clip := GlobalLock(lh_Clip);
              lp_Data := GlobalLock(lh_Data);
              lstrcpyW(lp_Data, lp_Clip);
              Result := UTF8Encode(WideString(PWideChar(lp_Data)));
              GlobalUnlock(lh_Data);
              GlobalFree(lh_Data);
              GlobalUnlock(lh_Clip); //GlobalFree
            end else if (li_Text = CF_TEXT) then begin
              lh_Data := GlobalAlloc(GHND or GMEM_SHARE, GlobalSize(lh_Clip));
              lp_Clip := GlobalLock(lh_Clip);
              lp_Data := GlobalLock(lh_Data);
              lstrcpy(lp_Data, lp_Clip);
              Result := AnsiToUtf8(AnsiString(PAnsiChar(lp_Data)));
              GlobalUnlock(lh_Data);
              GlobalFree(lh_Data);
              GlobalUnlock(lh_Clip); //GlobalFree
            end;
          finally
            if (lh_Data <> 0) then GlobalUnlock(lh_Data);
            CloseClipboard;
            //Write2EventLog('FlexKbd gfnsStrFromClipboard', Result);
          end;
        end;
      end;
    end;
  end;
end;

procedure gpcStrToClipboard(const sWText: String);
var
  //unicodeText: UnicodeString;
  //li_WLen: Integer;
  ls_Text: AnsiString;
  li_Len: Integer;
  lh_Mem: THandle;
  lp_Data: Pointer;
begin
  //li_WLen := Length(sWText) * 2 + 2;
  //unicodeText := UTF8Decode(sWText);
  ls_Text:= Utf8ToAnsi(sWText);
  li_Len  := Length(ls_Text) + 1;
  //Write2EventLog('FlexKbd gpcStrToClipboard', 'ls_Text: ' + ls_Text, EVENTLOG_INFORMATION_TYPE);
  if (OpenClipboard(GetActiveWindow)) then begin
    try
      EmptyClipboard;
      if (sWText <> '') then begin
        //CF_UNICODETEXT
        //lh_Mem  := GlobalAlloc(GHND or GMEM_SHARE, li_WLen);
        //lp_Data := GlobalLock(lh_Mem);
        //lstrcpyW(lp_Data, PWideChar(unicodeText));
        //GlobalUnlock(lh_Mem);
        //SetClipboardData(CF_UNICODETEXT, lh_Mem);
        //CF_TEXT
        lh_Mem  := GlobalAlloc(GHND or GMEM_SHARE, li_Len);
        lp_Data := GlobalLock(lh_Mem);
        lstrcpy(lp_Data, PAnsiChar(ls_Text));
        GlobalUnlock(lh_Mem);
        SetClipboardData(CF_TEXT, lh_Mem);
      end;
    finally
      CloseClipboard;
    end;
  end;
end;

procedure Write2EventLog(Source, Msg: string; eventType: Integer = EVENTLOG_ERROR_TYPE);
var h: THandle;
    ss: array [0..0] of pchar;
begin
    ss[0] := pchar(Msg);
    h := RegisterEventSource(nil, // uses local computer
             pchar(Source));      // source name
    if h <> 0 then
      ReportEvent(h,    // event log handle
            eventType,  // event type
            0,          // category zero
            0,          // event identifier
            nil,        // no user security identifier
            1,          // one substitution string
            0,          // no data
            @ss,        // pointer to string array
            nil);       // pointer to data
    DeregisterEventSource(h);
end;

end.
