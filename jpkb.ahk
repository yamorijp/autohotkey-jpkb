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

mouse_click_alt(button, alt, down_or_up) {
    b := GetKeyState("Alt") ? alt : button
    MouseClick, %b%, , , , , %down_or_up%
}

#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%
#InstallKeybdHook
#InstallMouseHook
#UseHook
SetKeyDelay -1
SetMouseDelay -1

lock_sc07b = 0
lock_sc079 = 0
lock_sc070 = 0

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
*sc07b::
    If (lock_sc07b) Return
    lock_sc07b = 1
    Switch (_mode) {
        case MODE_CLICK: mouse_click_alt("Left", "X1", "D")
    }
Return

*sc07b up::
    lock_sc07b = 0
    Switch (_mode) {
        case MODE_CLICK: mouse_click_alt("Left", "X1", "U")
        case MODE_IME: ime_set(0)
    }
Return

; 変換キー
*sc079::
    If (lock_sc079) Return
    lock_sc079 = 1
    Switch (_mode) {
        case MODE_CLICK: mouse_click_alt("Right", "X2", "D")
    }
Return

*sc079 up::
    lock_sc079 = 0
    Switch (_mode) {
        case MODE_CLICK: mouse_click_alt("Right", "X2", "U")
        case MODE_IME: ime_set(1)        
    }
Return

; かなキー
*sc070::
    If (lock_sc070) Return
    lock_sc070 = 1
    If (!GetKeyState("Alt")) {
        Switch (_mode) {
            case MODE_CLICK: mouse_click_alt("Middle", "Middle", "D")
        }
    }
Return

*sc070 up::
    lock_sc070 = 0
    If (!GetKeyState("Alt")) {
        Switch (_mode) {
            case MODE_CLICK: mouse_click_alt("Middle", "Middle", "U")
        }
    }
    Else {
        Switch (_mode) {
            case MODE_CLICK: Gosub do_ime
            case MODE_IME: Gosub do_bypass
            case MODE_BYPASS: Gosub do_click
        }        
    }    
Return
