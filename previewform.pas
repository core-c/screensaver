unit previewform;
interface
uses Windows, Messages, SysUtils, Classes, Graphics, Controls,
     Forms, Dialogs, ExtCtrls, Trayicon;

type
  TPreviewScreen = class(TForm)
    Timer_Preview: TTimer;
    theTrayIcon: TTrayIcon;
    procedure Timer_PreviewTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
(*    procedure FormPaint(Sender: TObject);*)
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    procedure CheckParamsFromINI;
    procedure GetPreviewChildHandle;
  public
    PreviewChildHandle: hWnd;
    PrevRect: TRect;
  end;

var PreviewScreen: TPreviewScreen;

implementation
uses check, INIsettings, GLAnimate, Waves;

{$R *.DFM}


function MyWndProc (Wnd : HWnd; Msg : Integer; wParam : Word; lParam : Integer) : Integer; far; stdcall;
begin
  if (Msg=WM_DESTROY) or (Msg=WM_CLOSE) then
    PostMessage(Wnd, WM_QUIT, 0, 0)
  else if Msg=WM_PAINT then {on paint is always the complete background now}
    CoreGL.ForceRect:=PreviewScreen.PrevRect;

  DefWindowProc(Wnd, Msg, wParam, lParam);
end;

(*
procedure TPreviewScreen.FormPaint(Sender: TObject);
begin
  CoreGL.ForceRect:=PreviewScreen.PrevRect;
end;
*)

procedure TPreviewScreen.GetPreviewChildHandle;
var WndClass: TWndClass;
    Atom: TAtom;
begin
  {create a new window class}
  with WndClass do begin
    style:=CS_PARENTDC;
    lpfnWndProc:=@MyWndProc;
    cbClsExtra:=0;
    cbWndExtra:=0;
    hIcon:=0;
    hCursor:=0;
    hbrBackground:=0;
    lpszMenuName:=nil;
    lpszClassName:='HCoreXxXPreviewClass';
  end;
  WndClass.hInstance:=hInstance;
  Atom:=Windows.RegisterClass(WndClass);
  {}
  GetWindowRect(ParamHandle, PrevRect);
  PrevRect.Bottom:=PrevRect.Bottom-PrevREct.Top;
  PrevRect.Right:=PrevRect.Right-PrevRect.Left;
  PrevRect.Top:=0;  PrevRect.Left:=0;
  {create the window as a child-window given in ParamHandle}
  PreviewChildHandle:=CreateWindowEx(WS_EX_NOPARENTNOTIFY,'HCoreXxXPreviewClass', 'PrEvIeW',
                      WS_CHILD or WS_DISABLED or WS_VISIBLE or WS_OVERLAPPED,
                      0, 0, PrevRect.Right, PrevRect.Bottom,
                      ParamHandle, 0, hInstance, nil);
  if PreviewChildHandle=0 then close;
end;


procedure TPreviewScreen.FormCreate(Sender: TObject);
begin
  {little buggy in my program. the form always seems to be
   visible. So i'll just shift it off-screen to the left}
  PreviewScreen.left:=-(PreviewScreen.Width+100);

  {--- process the INI-file}
  CFG.ReadINI;
  if CFG.INI_OK then CheckParamsFromINI else close;
  {---}
  Wave.Init(PrevRect.Right,PrevRect.Bottom);
  MouseTicks:=MouseTicksToIgnore;
  TimerTicksPerSecond:=Round(1000/Timer_Preview.interval);
  TimerCounter:=0;  FramesDropped:=0;  FramesPerSecond:=0;
  {}
  if ParamHandle<>0 then GetPreviewChildHandle else close;
end;


procedure TPreviewScreen.FormShow(Sender: TObject);
begin
  Cursor:=crArrow;
  ShowWindow(Application.Handle, SW_HIDE);
end;


procedure TPreviewScreen.FormActivate(Sender: TObject);
var Msg: tMsg;
begin
  if not (HCoreInfo.RunningWin95 or HCoreInfo.RunningWin31) then
    if (PrevActWnd<>0) then BringWindowToTop(GetParent(PreviewChildHandle));
  if PreviewChildHandle<>0 then
    CoreGL.EnableOpenGL(PreviewChildHandle,handleDC,handleRC );
  Timer_Preview.enabled:=true;
(*
  while GetMessage(Msg, 0, 0, 0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
*)
//  if (PrevActWnd<>0) then SetWindowPos( PrevActWnd,HWND_TOP,0,0,0,0,(SWP_NOCOPYBITS or SWP_NOMOVE or SWP_NOSIZE) );
end;


procedure TPreviewScreen.Timer_PreviewTimer(Sender: TObject);
begin
  inc(TimerCounter);
  if TimerCounter>TimerTicksPerSecond then Begin
    FramesPerSecond:=TimerTicksPerSecond-FramesDropped;
    FramesDropped:=0;  TimerCounter:=0;
    MouseTicks:=MouseTicksToIgnore;  {reset accidental mouse-movements}
  End;
  if CoreGL.StillBusy then inc(FramesDropped)
                      else Wave.GLAnimate;
end;


procedure TPreviewScreen.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Timer_Preview.enabled:=false;
  if PreviewChildHandle<>0 then
    CoreGL.DisableOpenGL(PreviewChildHandle,handleDC,handleRC);
end;


{==============================================================================}

procedure TPreviewScreen.CheckParamsFromINI;
begin
  MouseTicksToIgnore:=CFG.MouseSens;
end;



end.
