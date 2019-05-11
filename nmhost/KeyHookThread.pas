unit KeyHookThread;

{.$MODE Delphi}
{$CODEPAGE UTF8}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils, Windows, StrUtils, Common, JwaWinUser;

type
  TArrayCardinal = array of Cardinal;

  TKeyHookTh = class(THookTh)
  protected
    singleKeyFlag: Boolean;
    function VaridateEvent(wPrm: UInt64): Boolean; override;
  public
  end;

implementation

function TKeyHookTh.VaridateEvent(wPrm: UInt64): Boolean;
var
  KeyState: TKeyboardState;
  I: Integer;
  procedure AlterModified(var virtualModifires: Byte; var virtualScanCode: Cardinal; Flags: DWord);
  begin
    if virtualScanCode <> 0 then
      KeybdInput(virtualScanCode, Flags);
    if (virtualModifires and FLAG_CONTROL) <> 0 then begin
      ReleaseModifier(VK_RCONTROL, SCAN_RCONTROL, Flags or KEYEVENTF_EXTENDEDKEY);
      ReleaseModifier(VK_LCONTROL, SCAN_LCONTROL, Flags);
    end;
    if (virtualModifires and FLAG_MENU) <> 0 then begin
      ReleaseModifier(VK_RMENU, SCAN_RMENU, Flags or KEYEVENTF_EXTENDEDKEY);
      ReleaseModifier(VK_LMENU, SCAN_LMENU, Flags);
    end;
    if (virtualModifires and FLAG_SHIFT) <> 0 then begin
      ReleaseModifier(VK_RSHIFT, SCAN_RSHIFT, Flags or KEYEVENTF_EXTENDEDKEY);
      ReleaseModifier(VK_LSHIFT, SCAN_LSHIFT, Flags);
    end;
    if (virtualModifires and FLAG_WIN) <> 0 then begin
      ReleaseModifier(VK_RWIN, SCAN_RWIN, Flags or KEYEVENTF_EXTENDEDKEY);
      ReleaseModifier(VK_LWIN, SCAN_LWIN, Flags or KEYEVENTF_EXTENDEDKEY);
    end;
    SendInput(KeyInputCount, @KeyInputs[0], SizeOf(KeyInputs[0]));
    virtualScanCode:= 0;
    virtualModifires:= 0;
  end;
  procedure ClearAll;
  begin
    virtualOffModifires:= 0;
    virtualOffModifiresFlag:= False;
    modifierRelCount:= -1;
    lastTarget:= '';
    lastModified:= '';
    lastOrgModified:= '';
    singleKeyFlag:= False;
    AlterModified(virtualModifires, virtualScanCode, KEYEVENTF_KEYUP);
  end;
begin
  GetKeyState(0);
  GetKeyboardState(KeyState);
  modifierFlags:= 0;
  modifierFlags:= modifierFlags or (Ord((KeyState[VK_CONTROL] and 128) <> 0) * FLAG_CONTROL);
  modifierFlags:= modifierFlags or (Ord((KeyState[VK_MENU]    and 128) <> 0) * FLAG_MENU);
  modifierFlags:= modifierFlags or (Ord((KeyState[VK_SHIFT]   and 128) <> 0) * FLAG_SHIFT);
  modifierFlags:= modifierFlags or (Ord(((KeyState[VK_LWIN]   and 128) <> 0) or ((KeyState[VK_RWIN] and 128) <> 0)) * FLAG_WIN);
  keyDownState:= 0;
  scriptMode:= False;
  keydownMode:= False;
  createdKeyConfig:= False;
  modifierFlags2:= 0;
  // Paste Text Mode
  if wPrm = g_pasteText then begin
    scanCode:= 86;
    scans:= '1586';
  end else if ((wPrm and g_callShortcut) <> 0) or ((wPrm and g_keydown) <> 0) then begin
    scanCode:= HiWord(wPrm);
    if (wPrm and g_callShortcut) <> 0 then
      scriptMode:= True
    else begin
      keydownMode:= True;
      if scanCode >= $200 then Exit (False);
    end;
    modifierFlags2:= HiByte(LoWord(wPrm));
    scans:= IntToHex(modifierFlags2, 2) + IntToStr(scanCode);
  end else begin
    scanCode:= HiWord(wPrm and $00000000FFFFFFFF);
    if (scanCode and $8000) <> 0 then begin
      keyDownState:= KEYEVENTF_KEYUP;
      scanCode:= scanCode and $7FFF;
    end;
    if (scanCode and $6000) <> 0 then begin
      scanCode:= scanCode and $1FFF; // リピート or Alt
    end;
    scans:= IntToHex(modifierFlags, 2) + IntToStr(scanCode);
  end;

  KeyInputCount:= 0;
  SetLength(KeyInputs, 0);

  // Exit1 --> Modifierキー単独のとき
  for I:= 0 to 7 do begin
    if scanCode = modifiersCode[I] then begin
      if (modifierRelCount > -1) and (keyDownState = KEYEVENTF_KEYUP) then begin
        if modifierRelCount = 0 then begin
          ClearAll;
        end else begin
          Dec(modifierRelCount);
        end;
      end;
      Exit (False);
    end;
  end;
  // Exit2 --> Modifierキーが押されていない or Shiftのみ ＆ ファンクションキーじゃないとき
  if (modifierFlags in [0, 4])
    and not(scancode in [$3B..$44, $56, $57, $58])
    and not(scancode = $15D)
    and not((keyDownState = 0) and (virtualScanCode <> 0))
    and not(scriptMode) and not(keydownMode) then
  begin
    // SingleKeyの処理 (Pending)
    Exit (False);
  end;

  if configMode and (keyDownState = 0) then begin
    PostToChrome('configKeyEvent', scans);
    Exit (True);
  end else begin
    if (scans = lastOrgModified) and (keyDownState = 0) then begin
      // リピート対応
      scans:= lastTarget;
      modifierFlags:= StrToInt('$' + LeftBStr(lastModified, 2));
    end
    else if (scans <> lastModified) and ((virtualModifires > 0) or (virtualOffModifires > 0)) then begin
      // Modifier及びキー変更対応
      scans:= IntToHex(modifierFlags and (not virtualModifires) or virtualOffModifires, 2) + IntToStr(scanCode);
    end
    else if (scans = lastModified) and (scanCode = virtualScanCode) then begin
      // エコーバックは捨てる(循環参照対応)
      if keyDownState = KEYEVENTF_KEYUP then
        virtualScanCode:= 0;
      // 単独キーのとき
      if singleKeyFlag then begin
        ClearAll;
      end;
      Exit (False);
    end;

    Result:= False;
    index:= keyConfigList.IndexOf(scans);
    if (index > -1) or (scriptMode) or (keydownMode) then begin
      Result:= True;
      if ((index = -1) and scriptMode) or keydownMode then begin
        keyConfig:= TKeyConfig.Create(
          'remap',
          scans,
          '',
          modifierFlags2,
          scanCode);
      end else begin
        keyConfig:= TKeyConfig(keyConfigList.Objects[index]);
        if scriptMode and (keyConfig.mode = 'through') then begin
          keyConfig:= TKeyConfig.Create(
            'remap',
            scans,
            '',
            modifierFlags2,
            scanCode);
          createdKeyConfig:= True;
        end;
      end;
      if keyConfig.mode = 'remap' then begin
        modifierRelCount:= 0;
        SetLength(newScans, 0);
        if keyDownState = KEYEVENTF_KEYUP then
          AddScan(keyConfig.scanCode);
        modifiersBoth:= modifierFlags and keyConfig.modifierFlags;
        // CONTROL
        if (modifiersBoth and FLAG_CONTROL) <> 0 then begin
          ;
        end else begin
          if (keyConfig.modifierFlags and FLAG_CONTROL) <> 0 then begin
            AddScan(SCAN_LCONTROL);
            if (virtualOffModifires and FLAG_CONTROL) = 0 then
              virtualModifires:= virtualModifires or FLAG_CONTROL;
          end
          else if ((modifierFlags and FLAG_CONTROL) <> 0) and (keyDownState = 0) then begin
            ReleaseModifier(VK_RCONTROL, SCAN_RCONTROL, KEYEVENTF_EXTENDEDKEY);
            ReleaseModifier(VK_LCONTROL, SCAN_LCONTROL, 0);
            Inc(modifierRelCount, 2);
            if (virtualModifires and FLAG_CONTROL) = 0 then
              virtualOffModifires:= virtualOffModifires or FLAG_CONTROL;
          end;
        end;
        // ALT
        if (modifiersBoth and FLAG_MENU) <> 0 then begin
          ;
        end else begin
          if (keyConfig.modifierFlags and FLAG_MENU) <> 0 then begin
            AddScan(SCAN_LMENU);
            if (virtualOffModifires and FLAG_MENU) = 0 then
              virtualModifires:= virtualModifires or FLAG_MENU;
          end
          else if ((modifierFlags and FLAG_MENU) <> 0) and (keyDownState = 0) then begin
            ReleaseModifier(VK_RMENU, SCAN_RMENU, KEYEVENTF_EXTENDEDKEY);
            ReleaseModifier(VK_LMENU, SCAN_LMENU, 0);
            Inc(modifierRelCount, 2);
            if (virtualModifires and FLAG_MENU) = 0 then
              virtualOffModifires:= virtualOffModifires or FLAG_MENU;
          end;
        end;
        // SHIFT
        if (modifiersBoth and FLAG_SHIFT) <> 0 then begin
          ;
        end else begin
          if (keyConfig.modifierFlags and FLAG_SHIFT) <> 0 then begin
            AddScan(SCAN_LSHIFT);
            if (virtualOffModifires and FLAG_SHIFT) = 0 then
              virtualModifires:= virtualModifires or FLAG_SHIFT;
          end
          else if ((modifierFlags and FLAG_SHIFT) <> 0) and (keyDownState = 0) then begin
            ReleaseModifier(VK_RSHIFT, SCAN_RSHIFT, KEYEVENTF_EXTENDEDKEY);
            ReleaseModifier(VK_LSHIFT, SCAN_LSHIFT, 0);
            Inc(modifierRelCount, 2);
            if (virtualModifires and FLAG_SHIFT) = 0 then
              virtualOffModifires:= virtualOffModifires or FLAG_SHIFT;
          end;
        end;
        // WIN
        if (modifiersBoth and FLAG_WIN) <> 0 then begin
          ;
        end else begin
          if (keyConfig.modifierFlags and FLAG_WIN) <> 0 then begin
            AddScan(SCAN_LWIN);
            if (virtualOffModifires and FLAG_WIN) = 0 then
              virtualModifires:= virtualModifires or FLAG_WIN;
          end
          else if ((modifierFlags and FLAG_WIN) <> 0) and (keyDownState = 0) then begin
            ReleaseModifier(VK_RWIN, SCAN_RWIN, KEYEVENTF_EXTENDEDKEY);
            ReleaseModifier(VK_LWIN, SCAN_LWIN, KEYEVENTF_EXTENDEDKEY);
            Inc(modifierRelCount, 2);
            if (virtualModifires and FLAG_WIN) = 0 then
              virtualOffModifires:= virtualOffModifires or FLAG_WIN;
          end;
        end;
        if keyDownState = 0 then
          AddScan(keyConfig.scanCode);
        for I:= 0 to Length(newScans) - 1 do begin
          KeybdInput(newScans[I], keyDownState);
        end;
        SendInput(KeyInputCount, @KeyInputs[0], SizeOf(KeyInputs[0]));
        lastOrgModified:= keyConfig.orgModified;
        lastTarget:= scans;
        lastModified:= keyConfig.origin;
        virtualScanCode:= keyConfig.scanCode;
        if ((modifierFlags = 0) or singleKeyFlag) and (virtualOffModifires = 0) then
          singleKeyFlag:= True
        else
          singleKeyFlag:= False;
        if (wPrm = g_pasteText) or scriptMode or keydownMode then begin
          KeyInputCount:= 0;
          SetLength(KeyInputs, 0);
          AlterModified(modifierFlags, scanCode, KEYEVENTF_KEYUP);
          if scriptMode or keydownMode then begin
            KeyInputCount:= 0;
            SetLength(KeyInputs, 0);
            keyConfig.scanCode:= 0;
            AlterModified(keyConfig.modifierFlags, keyConfig.scanCode, KEYEVENTF_KEYUP);
          end;
          if keydownMode or createdKeyConfig then
            keyConfig.Free;
        end;
      end else if keyConfig.mode = 'through' then begin
        Exit (False);
      end else if (keyDownState = 0) and ((keyConfig.mode = 'bookmark') or (keyConfig.mode = 'command') or (keyConfig.mode = 'batch')) then begin
        PostToChrome(keyConfig.mode, scans);
      end;
      // Application key
      if (scancode = $15D) then begin
        Exit (False);
      end;
    end;
  end;
end;

end.
