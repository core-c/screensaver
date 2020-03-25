unit PrevInst;

interface

uses
  WinProcs,
  WinTypes,
  SysUtils;

type
  PHWnd = ^HWnd;

function EnumApps(Wnd: HWnd; TargetWindow: PHWnd): bool; export;

procedure ActivatePreviousInstance;

implementation

function EnumApps(Wnd: HWnd; TargetWindow: PHWnd): bool;
var
  ClassName : array[0..30] of char;
begin
  Result := true;
  if GetWindowLong(Wnd, GWL_HINSTANCE) = HPrevInst then begin
    GetClassName(Wnd, ClassName, 30);
    if STRIComp(ClassName,'TApplication')=0 then begin
      TargetWindow^ := Wnd;
      Result := false;
    end;
  end;
end;

procedure ActivatePreviousInstance;
var
  PrevInstWnd: HWnd;
begin
  PrevInstWnd := 0;
  EnumWindows(@EnumApps,LongInt(@PrevInstWnd));
  if PrevInstWnd <> 0 then
    if IsIconic(PrevInstWnd) then
      ShowWindow(PrevInstWnd,SW_Restore)
    else
      BringWindowToTop(PrevInstWnd);
end;

end.

