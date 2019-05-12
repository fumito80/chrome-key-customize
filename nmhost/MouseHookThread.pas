unit MouseHookThread;

{.$MODE Delphi}
{$CODEPAGE UTF8}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils, Windows, Common, JwaWinUser;

type
  LPMSLLHOOKSTRUCT = ^MSLLHOOKSTRUCT;
  tagMSLLHOOKSTRUCT = record
    pt: TPOINT;
    mouseData: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo: NativeUInt;
  end;
  MSLLHOOKSTRUCT = tagMSLLHOOKSTRUCT;
  TMsllHookStruct = MSLLHOOKSTRUCT;
  PMsllHookStruct = LPMSLLHOOKSTRUCT;

  TMouseHookTh = class(THookTh)
  protected
    stateDownL, stateDownM, stateDownR: Boolean;
    function VaridateEvent(wPrm: UInt64): Boolean; override;
  public
  end;

const
  MSG_MOUSE_LDOWN = WM_LBUTTONDOWN - $0200;
  MSG_MOUSE_LUP   = WM_LBUTTONUP   - $0200;
  MSG_MOUSE_LDBL  = WM_LBUTTONDBLCLK - $0200;
  MSG_MOUSE_RDOWN = WM_RBUTTONDOWN - $0200;
  MSG_MOUSE_RUP   = WM_RBUTTONUP   - $0200;
  MSG_MOUSE_RDBL  = WM_RBUTTONDBLCLK - $0200;
  MSG_MOUSE_MDOWN = WM_MBUTTONDOWN - $0200;
  MSG_MOUSE_MUP   = WM_MBUTTONUP   - $0200;
  MSG_MOUSE_MDBL  = WM_MBUTTONDBLCLK - $0200;
  MSG_MOUSE_WHEEL = WM_MOUSEWHEEL  - $0200;
  WM_WHEEL_UP    = $020B;
  WM_WHEEL_DOWN  = $020D;
  WM_GST_UP      = $021B;
  WM_GST_DOWN    = $021D;
  WM_GST_LEFT    = $022B;
  WM_GST_RIGHT   = $022D;
  FLAG_LDOWN = 16;
  FLAG_RDOWN = 32;
  FLAG_MDOWN = 64;

implementation

function TMouseHookTh.VaridateEvent(wPrm: UInt64): Boolean;
  procedure MakeKeyInputs(scans: TArrayCardinal; index: Integer);
  begin
    KeybdInput(scans[index], 0);
    if (index + 1) < Length(scans) then
      MakeKeyInputs(scans, index + 1);
    KeybdInput(scans[index], KEYEVENTF_KEYUP);
  end;
begin
  modifierFlags:= 0;
  scans:= '00' + IntToStr(wPrm);

  if (configMode) and (wPrm <> WM_WHEEL_UP) and (wPrm <> WM_WHEEL_DOWN) then begin
    PostToChrome('configKeyEvent', scans);
    Exit (True);

  end else begin
    index:= keyConfigList.IndexOf(scans);
    if index = -1 then begin
      Exit (False);
    end else begin
      keyConfig:= TKeyConfig(keyConfigList.Objects[index]);
      if (keyConfig.mode = 'disabled') then begin
        Exit (False);
      end else if (keyConfig.mode = 'remap') then begin
        KeyInputCount:= 0;
        SetLength(KeyInputs, 0);
        SetLength(newScans, 0);
        // CONTROL
        if (keyConfig.modifierFlags and FLAG_CONTROL) <> 0 then begin
          AddScan(SCAN_LCONTROL);
        end;
        // ALT
        if (keyConfig.modifierFlags and FLAG_MENU) <> 0 then begin
          AddScan(SCAN_LMENU);
        end;
        // SHIFT
        if (keyConfig.modifierFlags and FLAG_SHIFT) <> 0 then begin
          AddScan(SCAN_LSHIFT);
        end;
        // WIN
        if (keyConfig.modifierFlags and FLAG_WIN) <> 0 then begin
          AddScan(SCAN_LWIN);
        end;
        AddScan(keyConfig.scanCode);
        MakeKeyInputs(newScans, 0);
        SendInput(KeyInputCount, @KeyInputs[0], SizeOf(KeyInputs[0]));
      end else begin
        PostToChrome(keyConfig.mode, scans);
      end;
    end;
  end;
  Exit (True);
end;

end.

