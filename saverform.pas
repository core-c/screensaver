unit saverform;
interface
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs, ExtCtrls, StdCtrls, Registry,Regstr;

type
  TSaverScreen = class(TForm)
    TheTimer: TTimer;
    L_txt: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TheTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyUpDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUpDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    AppStartTicks: integer;
    procedure CheckParamsFromINI;
    procedure WMQueryEndSession(var Msg: TWMQueryEndSession); message WM_QUERYENDSESSION;
    procedure WMSysCommand(var Msg : TWMSysCommand); message WM_SYSCOMMAND;
    function ConvertPicToBMP(theFileToConvert: string): string;
    procedure NextBMP;
    function CheckPwd: boolean;
    procedure SignOff;
  public
    FormBackground: hWnd;
  end;

var SaverScreen: TSaverScreen;
    b3Dfx: boolean;

{========================================================}
implementation
uses check, INISettings, GLAnimate, Waves;

{$R *.DFM}
{$UNDEF USE_3DFX}

procedure TSaverScreen.FormCreate(Sender: TObject);
var iDummy: integer;
begin
{$IFDEF USE_3DFX}
  {check 3Dfx-stuff}
  b3Dfx:=false;
  if CFG.Saver3Dfx then {check for a board along with glide}
    if HCoreInfo.Get3Dfx then b3Dfx:=Use3DfxDLL;
  {}
{$ENDIF}
  Color:=clBlack;
  {get how long Windows is running (in ms.)}
  AppStartTicks:=GetTickCount();
  Cursor:=crNone;
  {--- process the INI-file}
  CFG.ReadINI;
  if CFG.INI_OK then CheckParamsFromINI else close;
  {---}
  Wave.Init(Width,Height);
  MouseTicks:=MouseTicksToIgnore;
  TimerTicksPerSecond:=Round(1000/TheTimer.interval);
  TimerCounter:=0;  FramesDropped:=0;  FramesPerSecond:=0;
  {no alt-tab or ctrl-alt-del any more}
//  SystemParametersInfo(SPI_SCREENSAVERRUNNING, word(True), @iDummy, 0);
end;

procedure TSaverScreen.FormShow(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
end;


procedure TSaverScreen.FormActivate(Sender: TObject);
begin
  FormBackground:=Handle;
  CoreGL.EnableOpenGL(FormBackground,handleDC,handleRC );
  TheTimer.enabled:=true;
end;

procedure TSaverScreen.TheTimerTimer(Sender: TObject);
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


procedure TSaverScreen.WMSysCommand(var Msg : TWMSysCommand);
begin
  {activate only 1 saver at a time}
  if Msg.cmdType=SC_SCREENSAVE then Msg.Result:=1
  else
    inherited;
end;

{---------------------------------------------------------------}
{ Custom procedure to respond to the WM_QUERYENDSESSION message }
{ The application will only receive this message in the event   }
{ that Windows is requesing to exit.                            }
{---------------------------------------------------------------}
procedure TSaverScreen.WMQueryEndSession(var Msg: TWMQueryEndSession);
begin
  inherited;         { let the inherited message handler respond first }
  {--------------------------------------------------------------------}
  { at this point, you can either prevent windows from closing...      }
  { Msg.Result:=0;                                                 }
  {---------------------------or---------------------------------------}
  { just call the same cleanup procedure that you call in FormClose... }
  Msg.Result:=1;
  Close;
//  FormDeactivate(self);
  {--------------------------------------------------------------------}
end;


procedure TSaverScreen.SignOff;
var AppRunningTicks: integer;
    yess: boolean;
begin
  TheTimer.enabled:=false;
  {count how long screensaver is running (in ms.)}
  AppRunningTicks:=GetTickCount()-AppStartTicks;
  yess:=AppRunningTicks<(7*1000);
  if not yess then yess:=Checkpwd;
  if yess then begin
    if CFG.ChangeWallpaper then begin
      {only change wallpaper if saver was running for at least a minute}
      if AppRunningTicks>(60*1000) then NextBMP;
    end;
    close;
  end else
    TheTimer.enabled:=true;
end;


procedure TSaverScreen.FormClose(Sender: TObject; var Action: TCloseAction);
var iDummy: integer;
begin
  TheTimer.enabled:=false;
  {enable every Win95 system key}
//  SystemParametersInfo(SPI_SCREENSAVERRUNNING, Word(false), @iDummy, 0);
  {}
  CoreGL.DisableOpenGL(FormBackground,handleDC,handleRC);
  Cursor:=crDefault;
{$IFDEF USE_3DFX}
  {check 3Dfx-stuff}
  if CFG.Saver3Dfx then
    {check for a board along with glide}
    if b3Dfx then UseOpenGLDLL;
  {}
{$ENDIF}
end;




procedure TSaverScreen.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if CFG.OnImmKeyStop then
    SignOff
  else
    if MouseTicks>0 then Dec(MouseTicks,3)
                    else SignOff;
end;

procedure TSaverScreen.FormKeyUpDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if CFG.OnImmKeyStop then
    SignOff
  else
    if MouseTicks>0 then Dec(MouseTicks,3)
                    else SignOff;
end;


procedure TSaverScreen.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if MouseTicks>0 then Dec(MouseTicks,1)
                  else SignOff;
end;

procedure TSaverScreen.FormMouseUpDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if MouseTicks>0 then Dec(MouseTicks,1)
                  else SignOff;
end;






function TSaverScreen.ConvertPicToBMP(theFileToConvert: string): string;
var MyBMP: TBitmap;
    MyImg: TImage;
    endS: string;
begin
  endS:=HCoreInfo.GetWinDir+ConvertedToBMP_name;
  try
    MyBMP:= TBitmap.Create;
    MyImg:=TImage.Create(SaverScreen);
    MyImg.AutoSize:=true;
    MyImg.Picture.LoadFromFile(theFileToConvert);
    MyBMP.Assign(MyImg.Picture.graphic);
    MyBMP.Width:=MyImg.width;
    MyBMP.Height:=MyImg.Height;
    MyBMP.Canvas.CopyMode:=cmSrcCopy;
    MyBMP.Canvas.Draw(0,0,MyImg.Picture.bitmap);
    MyBMP.SaveToFile(endS);
  finally
    MyBMP.Free;
    MyImg.Free;
  end;
  Result:=endS;
end;

procedure TSaverScreen.NextBMP;
var chPic: integer;
    tStr: string;
    {}
    procedure ShowMyText(inS: string);
    begin
      L_txt.caption:=inS;
      if inS='' then L_txt.Visible:=false
                else L_txt.Visible:=true;
      L_txt.Refresh;
    end;
    {}
begin
  if CFG.ChangeWallpaper then begin
    ShowMyText('');
    {following if-then statements ought to be executed sequencially}
    If CFG.LastPic=-1 then chPic:=0 else chPic:=CFG.LastPic+1;
    if chPic>9 then chPic:=0;
    tStr:=CFG.bmp[chPic];
    if tStr='' then chPic:=0;
    if tStr='' then chPic:=-1;
//    if chPic=-1 then ChangeWallpaper:=false;
    CFG.Lastpic:=chPic;
    CFG.WriteINI;
    {set the picture as the new wallpaper}
    if CFG.LastPic<>-1 then begin
      tStr:=CFG.bmp[CFG.LastPic];
      {convert picture if it is not a real bitmap}
      if Pos('.bmp',tStr)=0 then begin
        ShowMyText('Preparing wallpaper..');
        tStr:=SaverScreen.ConvertPicToBMP(tStr);
      end;
      SystemParametersInfo(SPI_SETDESKWALLPAPER,0,PChar(tStr),0);
      ShowMyText('');
    end;
  end;
end;



{this function checks for password if necessary and closes
 the screen-saver if pwd was correct}
function TSaverScreen.CheckPwd: boolean;
var
  hLib : THandle;
  P : function (Parent : THandle) : Boolean; stdcall;
  SysDir : String;
  Registry : TRegistry;
  bR: boolean;
begin
  {CheckPWD always results true, except:
   when password is needed to logon AND
   entered password is false}
  bR:=true;
  if not (HCoreInfo.RunningWinNT or HCoreInfo.RunningWin31) then begin
      {check if password must be checked}
      Registry:=TRegistry.Create;
      Registry.RootKey:=HKEY_CURRENT_USER;
      if Registry.OpenKey('Control Panel\desktop', false) then
        if Registry.ReadInteger('ScreenSaveUsePassword')<>0 then begin
          ShowCursor(True); {activate mouse}
          {load library PASSWORD.CPL from system-directory}
          SysDir:=HCoreInfo.GetSysDir;
          hLib:=LoadLibrary(PChar(SysDir+'PASSWORD.CPL'));
          if hLib<>0 then begin
            {show the password verification dialog}
            P:=GetProcAddress(hLib, 'VerifyScreenSavePwd');
            bR:=P(Handle);
            FreeLibrary(hLib); {unload PASSWORD.CPL}
          end;
          MouseTicks:=MouseTicksToIgnore;
          ShowCursor(False); {disable the mouse again}
        end;
  end;
  Result:=bR
end;


{==============================================================================}

procedure TSaverScreen.CheckParamsFromINI;
begin
  MouseTicksToIgnore:=CFG.MouseSens;
end;

end.
