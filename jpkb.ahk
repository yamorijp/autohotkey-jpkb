/*
            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                    Version 2, December 2004
  
 Copyright (C) 2020 Nihon Yamori (https://yamori-jp.blogspot.com)
 
 Everyone is permitted to copy and distribute verbatim or modified
 copies of this license document, and changing it is allowed as long
 as the name is changed.
  
            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
  
  0. You just DO WHAT THE FUCK YOU WANT TO.
*/

; @IME.ank
ime_set(SetSts, WinTitle="A") {
	ControlGet,hwnd,HWND,,,%WinTitle%
	if	(WinActive(WinTitle))	{
		ptrSize := !A_PtrSize ? 4 : A_PtrSize
	    VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
	    NumPut(cbSize, stGTI,  0, "UInt")   ;	DWORD   cbSize;
		hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
	}

    return DllCall("SendMessage"
            , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
            , UInt, 0x0283  ;Message : WM_IME_CONTROL
            ,  Int, 0x006   ;wParam  : IMC_SETOPENSTATUS
            ,  Int, SetSts) ;lParam  : 0 or 1
}

set_mode(mode) {
    _mode := mode
    update()
}

update() {
    IniWrite, %_mode%, %_ini_name%, settings, mode
    ico := "icon/" . _mode . ".ico"
    Menu, TRAY, Icon, %ico%
    Menu, TRAY, UnCheck, %MODE_CLICK%
    Menu, TRAY, UnCheck, %MODE_IME%
    Menu, TRAY, UnCheck, %MODE_BYPASS%
    Menu, TRAY, Check, %_mode%
}

#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%
#InstallKeybdHook
#UseHook
SetKeyDelay 0

global MODE_CLICK := "Click"
global MODE_IME := "IME"
global MODE_BYPASS := "Bypass"

Menu, TRAY, Add
Menu, TRAY, Add, %MODE_CLICK%, do_click, +Radio
Menu, TRAY, Add, %MODE_IME%, do_ime, +Radio
Menu, TRAY, Add, %MODE_BYPASS%, do_bypass, +Radio

SplitPath, A_ScriptName, , , , script_name
global _ini_name := script_name . ".ini"
global _mode := MODE_CLICK
IniRead, _mode, %_ini_name%, settings, mode, %_mode%

update()
Return


do_click: 
    set_mode(MODE_CLICK)
Return

do_ime:
    set_mode(MODE_IME)
Return
    
do_bypass:
    set_mode(MODE_BYPASS)
Return


; 無変換キー
+sc07B::
^sc07B::
sc07B::
    Switch (_mode)
    {
        case MODE_CLICK: MouseClick, Left
        case MODE_IME: ime_set(0)
    }
Return

!sc07B::
    Switch (_mode)
    {
        case MODE_CLICK: MouseClick, X1
    }
Return    

; 変換キー
+sc079::
^sc079::
sc079::
    Switch (_mode)
    {
        case MODE_CLICK: MouseClick, Right
        case MODE_IME: ime_set(1)
    }
Return

!sc079::
    Switch (_mode)
    {
        case MODE_CLICK: MouseClick, X2
    }
Return

; かなキー
+sc070::
^sc070::
sc070::
    Switch (_mode)
    {
        case MODE_CLICK: MouseClick, Middle
    }
Return

!sc070::
    Switch (_mode)
    {
        case MODE_CLICK: Gosub, do_ime
        case MODE_IME: Gosub, do_bypass
        case MODE_BYPASS: Gosub, do_click
    }
Return
