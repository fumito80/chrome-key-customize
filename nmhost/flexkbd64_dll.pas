library flexkbd64_dll;

{.$MODE Delphi}

{$CODEPAGE UTF8}
{$LONGSTRINGS ON}
{$R *.res}

uses
  SysUtils,
  Classes,
  Windows,
  Messages,
  StrUtils,
  KeyHookThread,
  MouseHookThread,
  Common;

var
  hStdOut, tId: THandle;
  keyHookTh: TKeyHookTh;
  mouseHookTh: TMouseHookTh;
  keyConfigList: TStringList;
  g_mouseWheelF: Boolean = False;
  g_mouseGesturesF: Boolean = False;

procedure EndHook(p: Pointer); forward;
procedure EndMouseHook(p: Pointer); forward;
procedure ReconfigHook(configMode: Boolean = False); forward;

function GetFileMapObj(var h: THandle; var ptr: Pointer): Integer;
begin
  h:= OpenFileMapping(FILE_MAP_ALL_ACCESS, False, PAnsiChar(FILE_MAPPING_NAME));
  if (h = 0) then begin
    Exit (-1);
  end;

  ptr:= MapViewOfFile(h, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if (ptr = nil) then begin
    Exit (-2);
  end;

  Exit (0);
end;

function ReleaseFileMapObj(h: THandle; ptr: Pointer): Integer;
begin
  UnmapViewOfFile(ptr);
  FileClose(h); { *Converted from CloseHandle* }
  Exit (0);
end;

function Initialize(
  hStdOutIn, threadID: THandle;
  keyPipeNameIn, mousePipeNameIn: string): Integer; stdcall;
var
  _hFMOBJ: THandle = 0;
  p: Pointer = nil;
  succeed: Integer;
begin
  keyConfigList:= TStringList.Create;
  hStdOut:= hStdOutIn;
  tId:= threadID;
  succeed:= GetFileMapObj(_hFMOBJ, p);
  if succeed <> 0 then Exit (succeed);
  try
    with pShareData(p)^ do begin
      StrCopy(keyPipeName, PAnsiChar(keyPipeNameIn));
      StrCopy(mousePipeName, PAnsiChar(mousePipeNameIn));
      inWheelTabArea:= False;
      mouseWheelF:= False;
      mouseGesturesF:= False;
    end;
  finally
    ReleaseFileMapObj(_hFMOBJ, p);
  end;
  Exit (0);
end;

procedure Destroy;
var
  _hFMOBJ: THandle = 0;
  p: Pointer = nil;
begin
//  Write2EventLog('FlexKbd Dll fin', fmapName, EVENTLOG_INFORMATION_TYPE);
  GetFileMapObj(_hFMOBJ, p);
  try
    EndHook(p);
    EndMouseHook(p);
  finally
    ReleaseFileMapObj(_hFMOBJ, p);
  end;
  keyConfigList.Free;
end;

function KeyHookFunc(code: Integer; wPrm: Int64; lPrm: Int64): LRESULT;
var
  cancelFlag: Boolean;
  bytesRead: Cardinal = 0;
  _hFMOBJ: THandle = 0;
  p: Pointer = nil;
begin
  if (code < HC_ACTION) then begin
    Exit (CallNextHookEx(0, code, wPrm, lPrm));
  end;

  GetFileMapObj(_hFMOBJ, p);
  try
    with pShareData(p)^ do begin
      CallNamedPipe(keyPipeName, @lPrm, SizeOf(lPrm), @cancelFlag, SizeOf(Boolean), bytesRead, NMPWAIT_WAIT_FOREVER);
      if cancelFlag then begin
        //PMsg(lPrm)^.message:= WM_NULL; // Bad code!
        Exit (1);
      end else begin
        Exit (CallNextHookEx(0, code, wPrm, lPrm));
      end;
    end;
  finally
    ReleaseFileMapObj(_hFMOBJ, p);
  end;
end;

function MouseHookFunc(code: Integer; wPrm: WPARAM; lPrm: LPARAM): LRESULT; stdcall;
  function getGestureDir(moveX, moveY: LongInt): UInt64;
  begin
    if (abs(moveX) < 30) and (abs(moveY) < 30) then begin
      Exit (0);
    end;
    if abs(moveX) > abs(moveY) then begin
      if (moveX > 0) then begin
        Exit (WM_GST_RIGHT);
      end else begin
        Exit (WM_GST_LEFT);
      end;
    end else begin
      if (moveY > 0) then begin
        Exit (WM_GST_DOWN);
      end else begin
        Exit (WM_GST_UP);
      end;
    end;
  end;
var
  buf: array[0..1000] of AnsiChar;
  _hFMOBJ: THandle = 0;
  p: Pointer = nil;
  pMHS: PMouseHookStruct;
  cancelFlag: Boolean;
  bytesRead: Cardinal = 0;
  msgFlag: UInt64;
begin
  if (code <> HC_ACTION) or ((wPrm <> WM_MOUSEMOVE) and (wPrm <> WM_RBUTTONDOWN) and (wPrm <> WM_RBUTTONUP)) then begin
    Exit (CallNextHookEx(0, code, wPrm, lPrm));
  end;

  GetFileMapObj(_hFMOBJ, p);
  try
    with pShareData(p)^ do begin
      pMHS:= PMouseHookStruct(lPrm);
      GetClassName(pMHS^.hwnd, buf, SizeOf(buf));
      if (wPrm = WM_MOUSEMOVE) and (mouseWheelF) and (AnsiStartsText(CHROME_CLASS_WIDGET, buf)) then begin
        // in mouse wheel area
        ScreenToClient(pMHS^.hwnd, pMHS^.pt);
        if (pMHS^.pt.y < 50) then begin
          inWheelTabArea:= True;
        end else begin
          inWheelTabArea:= False;
        end;
      end else if ((wPrm = WM_RBUTTONDOWN) or (wPrm = WM_RBUTTONUP)) and (mouseGesturesF)
          and (AnsiStartsText(CHROME_CLASS_WIDGET, buf) or AnsiStartsText(CHROME_CLASS_RENDER, buf)) then begin
        if (wPrm = WM_RBUTTONDOWN) then begin
          // on mouse right-click button down
          hWnd:= pMHS^.hwnd;
          ScreenToClient(hWnd, pMHS^.pt);
          startX:= pMHS^.pt.x;
          startY:= pMHS^.pt.y;
        end else if (wPrm = WM_RBUTTONUP) then begin
          // on mouse right-click button up
          if (startX > 0) then begin
            ScreenToClient(hWnd, pMHS^.pt);
            msgFlag:= getGestureDir(pMHS^.pt.x - startX, pMHS^.pt.y - startY);
            startX:= 0;
            if (msgFlag > 0) then begin
              CallNamedPipe(mousePipeName, @msgFlag, SizeOf(msgFlag), @cancelFlag, SizeOf(Boolean), bytesRead, NMPWAIT_WAIT_FOREVER);
              if (cancelFlag) then begin
                mouse_event(MOUSEEVENTF_LEFTUP or MOUSEEVENTF_ABSOLUTE, 0, 0, 0, 0);
                Exit (1);
              end;
            end;
          end;
        end;
      end;
    end;
    Exit (CallNextHookEx(0, code, wPrm, lPrm));
  finally
    ReleaseFileMapObj(_hFMOBJ, p);
  end;
end;

function MouseWheelHookFunc(code: Integer; wPrm: WPARAM; lPrm: LPARAM): LRESULT; stdcall;
var
  cancelFlag: Boolean;
  bytesRead: Cardinal = 0;
  msgFlag: UInt64;
  msg: TMsg;
  _hFMOBJ: THandle = 0;
  p: Pointer = nil;
begin
  if (code <> HC_ACTION) or (wPrm <> HC_ACTION) then begin
    Exit (CallNextHookEx(0, code, wPrm, lPrm));
  end;

  GetFileMapObj(_hFMOBJ, p);
  try
    with pShareData(p)^ do begin
      if (not inWheelTabArea) then begin
        Exit (CallNextHookEx(0, code, wPrm, lPrm));
      end;
      msg:= PMsg(lPrm)^;
      if (msg.message = WM_MOUSEWHEEL) then begin
        if SHORT(HIWORD(msg.wParam)) > 0 then begin
          msgFlag:= WM_WHEEL_UP
        end else begin
          msgFlag:= WM_WHEEL_DOWN;
        end;
        CallNamedPipe(mousePipeName, @msgFlag, SizeOf(msgFlag), @cancelFlag, SizeOf(Boolean), bytesRead, NMPWAIT_WAIT_FOREVER);
        msg.message:= WM_NULL;
        Exit (1);
      end;
    end;
    Exit (CallNextHookEx(0, code, wPrm, lPrm));
  finally
    ReleaseFileMapObj(_hFMOBJ, p);
  end;
end;

procedure SetKeyConfig(params: String); stdcall;
var
  modifierFlags, targetModifierFlags, I: Byte;
  paramsList, paramList: TStringList;
  mode, orgModified, target, origin, proxyTarget, proxyOrgModified: string;
  scanCode, targetScanCode, proxyScanCode, kbdLayout: Cardinal;
  function GetProxyScanCode(scanCode: Cardinal): Cardinal;
  var
    I, J: Integer;
    exists: Boolean;
  begin
    for I:= 0 to 200 do begin
      exists:= False;
      for J:= 0 to keyConfigList.Count - 1 do begin
        if IntToStr(scanCode) = Copy(keyConfigList.Strings[J], 3, 10) then begin
          exists:= True;
          Break;
        end;
      end;
      if exists then begin
        Inc(scanCode)
      end else begin
        if MapVirtualKeyEx(scanCode, 3, kbdLayout) <> VK_NONAME then begin
          Inc(scanCode);
        end else
          Break;
      end;
    end;
    Exit (scanCode);
  end;
begin
  g_mouseWheelF:= False;
  g_mouseGesturesF:= False;
  if params = '' then begin
    keyConfigList.Clear;
    ReconfigHook;
    Exit;
  end;
  kbdLayout:= GetKeyboardLayout(0);
  paramsList:= TStringList.Create;
  paramsList.Delimiter:= '|';
  paramsList.DelimitedText:= params;
  paramList:= TStringList.Create;
  keyConfigList.Clear;
  try
    for I:= 0 to paramsList.Count - 1 do begin
      paramList.Delimiter:= ';';
      paramList.DelimitedText:= paramsList.Strings[I];

      target:= paramList.Strings[0];
      targetModifierFlags:= StrToInt('$' + LeftBStr(target, 2));
      targetScanCode:= StrToInt(Copy(target, 3, 10));

      mode:= paramList.Strings[2];

      if (targetScanCode = 1) then begin
        if (mode = 'mousewheel') then begin
          g_mouseWheelF:= true;
          Continue;
        end else if (mode = 'mouseGestures') then begin
          g_mouseGesturesF:= true;
          Continue;
        end;
      end;

      origin:= paramList.Strings[1];
      modifierFlags:= StrToInt('$' + LeftBStr(origin, 2));
      scanCode:= StrToInt(Copy(origin, 3, 10));
      orgModified:= LeftBStr(origin, 2) + Copy(target, 3, 10);

      if (scanCode = targetScanCode) and (mode = 'remap') then begin
        if (modifierFlags = targetModifierFlags) then begin
          mode:= 'through'
        end else begin
          // Make Proxy
          proxyScanCode:= GetProxyScanCode($5A);
          proxyTarget:= LeftBStr(target, 2) + IntToStr(proxyScanCode);
          proxyOrgModified:= LeftBStr(origin, 2) + IntToStr(proxyScanCode);
          keyConfigList.AddObject(proxyTarget, TKeyConfig.Create(
            mode,
            origin,
            proxyOrgModified,
            modifierFlags,
            scanCode
          ));
          // Make Origin
          orgModified:= LeftBStr(target, 2) + Copy(target, 3, 10);
          modifierFlags:= StrToInt('$' + LeftBStr(target, 2));
          scanCode:= proxyScanCode;
        end;
      end;

      keyConfigList.AddObject(target, TKeyConfig.Create(
        mode,
        origin,
        orgModified,
        modifierFlags,
        scanCode
      ));
    end;
    // For Paste Text
    keyConfigList.AddObject('1586', TKeyConfig.Create(
      'remap',
      '0147',
      '0186',
      1,
      47
    ));
  finally
    paramsList.Free;
    paramList.Free;
    //
    ReconfigHook;
  end;
end;

//
procedure StartConfigMode;
begin
  ReconfigHook(True);
end;

procedure EndConfigMode;
begin
  ReconfigHook;
end;

// Start KeyHook
procedure StartHook(configMode: Boolean; p: Pointer);
begin
  with pShareData(p)^ do begin
    keyHookTh:= TKeyHookTh.Create(keyPipeName, hStdOut, keyConfigList, configMode);
    hookKey:= SetWindowsHookEx(WH_KEYBOARD, @KeyHookFunc, hInstance, tId);
  end;
end;

// Start MouseHook
procedure StartMouseHook(p: pointer);
begin
  with pShareData(p)^ do begin
    mouseHookTh:= TMouseHookTh.Create(mousePipeName, hStdOut, keyConfigList, False);
    hookMouse:= SetWindowsHookEx(WH_MOUSE, @MouseHookFunc, hInstance, tId);
    if (g_mouseWheelF) then begin
      hookMouseWheel:= SetWindowsHookEx(WH_GETMESSAGE, @MouseWheelHookFunc, hInstance, tId);
    end;
  end;
end;

// Stop KeyHook
procedure EndHook(p: Pointer);
var
  dummyFlag: Boolean;
  bytesRead: Cardinal = 0;
begin
  with pShareData(p)^ do begin
    if keyHookTh <> nil then begin
      keyHookTh.Terminate;
      CallNamedPipe(keyPipeName, @g_destroy, SizeOf(UInt64), @dummyFlag, SizeOf(Boolean), bytesRead, NMPWAIT_WAIT_FOREVER);
      keyHookTh.WaitFor;
      FreeAndNil(keyHookTh);
    end;
    if hookKey <> 0 then begin
   	  UnHookWindowsHookEX(hookKey);
      hookKey:= 0;
    end;
  end;
end;

// Stop MouseHook
procedure EndMouseHook(p: Pointer);
var
  dummyFlag: Boolean;
  bytesRead: Cardinal = 0;
begin
  with pShareData(p)^ do begin
    if mouseHookTh <> nil then begin
      mouseHookTh.Terminate;
      CallNamedPipe(mousePipeName, @g_destroy, SizeOf(UInt64), @dummyFlag, SizeOf(Boolean), bytesRead, NMPWAIT_WAIT_FOREVER);
      mouseHookTh.WaitFor;
      FreeAndNil(mouseHookTh);
    end;
    if hookMouse <> 0 then begin
   	  UnHookWindowsHookEX(hookMouse);
      hookMouse:= 0;
    end;
    if hookMouseWheel <> 0 then begin
     	UnHookWindowsHookEX(hookMouseWheel);
      hookMouseWheel:= 0;
    end;
    inWheelTabArea:= False;
  end;
end;

// Thread config reload
procedure ReconfigHook(configMode: Boolean = False);
var
  dummyFlag: Boolean;
  bytesRead: Cardinal = 0;
  _hFMOBJ: THandle = 0;
  p: pointer = nil;
begin
  GetFileMapObj(_hFMOBJ, p);
  try
    with pShareData(p)^ do begin
      if (keyHookTh = nil) then begin
        g_configMode:= False;
        StartHook(false, p);
      end else begin
        g_configMode:= configMode;
        CallNamedPipe(keyPipeName, @g_reloadConfig, SizeOf(UInt64), @dummyFlag, SizeOf(Boolean), bytesRead, NMPWAIT_WAIT_FOREVER);
      end;
      mouseWheelF:= g_mouseWheelF;
      mouseGesturesF:= g_mouseGesturesF;
      if (mouseWheelF) or (mouseGesturesF) then begin
        if (mouseHookTh = nil) then begin
          StartMouseHook(p);
        end else begin
          CallNamedPipe(mousePipeName, @g_reloadConfig, SizeOf(UInt64), @dummyFlag, SizeOf(Boolean), bytesRead, NMPWAIT_WAIT_FOREVER);
        end;
      end else begin
        EndMouseHook(p);
      end;
    end;
  finally
    ReleaseFileMapObj(_hFMOBJ, p);
  end;
end;

exports
  StartConfigMode, EndConfigMode, SetKeyConfig, Initialize, Destroy;

begin
  g_mouseWheelF:= False;
  g_mouseGesturesF:= False;
  keyHookTh:= nil;
  mouseHookTh:= nil;
  modifiersCode[0]:= SCAN_LCONTROL;
  modifiersCode[1]:= SCAN_LMENU;
  modifiersCode[2]:= SCAN_LSHIFT;
  modifiersCode[3]:= SCAN_LWIN;
  modifiersCode[4]:= SCAN_RCONTROL;
  modifiersCode[5]:= SCAN_RMENU;
  modifiersCode[6]:= SCAN_RSHIFT;
  modifiersCode[7]:= SCAN_RWIN;
end.
