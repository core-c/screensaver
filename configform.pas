unit configform;
interface
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  StdCtrls, ExtCtrls, ComCtrls, Forms, Dialogs, jpeg, Menus, Trayicon;

type
  TConfigScreen = class(TForm)
    B_OK: TButton;
    B_Cancel: TButton;
    CB_ClearBackground: TCheckBox;
    TB_MouseSens: TTrackBar;
    L_MouseSens: TLabel;
    L_SleepLonger: TLabel;
    Img_Background: TImage;
    L_Author: TLabel;
    CB_OnImmKeyStop: TCheckBox;
    L_OnImmKeyStop: TLabel;
    L_WavePart: TLabel;
    UD_MorphSpeed: TUpDown;
    L_txtMorphSpeed: TLabel;
    L_MorphSpeed: TLabel;
    L_txtMorphRange: TLabel;
    L_MorphRange: TLabel;
    UD_MorphRange: TUpDown;
    TB_XShift: TTrackBar;
    L_XShift: TLabel;
    TB_YSwap: TTrackBar;
    L_YSwap: TLabel;
    CB_ColorCycle: TCheckBox;
    L_ColorCycle: TLabel;
    TB_ColorIntensity: TTrackBar;
    L_ColorIntensity: TLabel;
    L_CoreWave: TLabel;
    TB_CoreWave: TTrackBar;
    CB_Xtra: TCheckBox;
    CB_Harmonica: TCheckBox;
    L_Harmonica: TLabel;
    TB_Gap: TTrackBar;
    L_gap: TLabel;
    CB_BGCycle: TCheckBox;
    TB_Span: TTrackBar;
    L_Span: TLabel;
    CB_ColorBurst: TCheckBox;
    TB_BurstIntensity: TTrackBar;
    L_BurstIntensity: TLabel;
    CB_FadePoints: TCheckBox;
    L_FadePoints: TLabel;
    CB_Stars: TCheckBox;
    L_Stars: TLabel;
    CB_MultiColStars: TCheckBox;
    TB_NrOfStars: TTrackBar;
    CB_3DRot: TCheckBox;
    L_3DRot: TLabel;
    TB_3DRotX: TTrackBar;
    TB_3DRotY: TTrackBar;
    TB_3DRotZ: TTrackBar;
    L_x: TLabel;
    L_y: TLabel;
    L_z: TLabel;
    Img_Wave360: TImage;
    Img_Wave180: TImage;
    Img_Wave540: TImage;
    Img_Wave720: TImage;
    L_CoreWavetxt: TLabel;
    UD_LineWidth: TUpDown;
    L_LineWidth: TLabel;
    CB_ChangeWallpaper: TCheckBox;
    L_ChangeWallpaper: TLabel;
    L_txtWallpaper: TLabel;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    Shape8: TShape;
    Shape12: TShape;
    TrayPopup: TPopupMenu;
    TP_ch3Dfx: TMenuItem;
    TP_chOpenGL: TMenuItem;
    N1: TMenuItem;
    TP_chAbout: TMenuItem;
    L_OSVersion: TLabel;
    L_Processor: TLabel;
    Label1: TLabel;
    theTrayIcon: TTrayIcon;
    L_ClearBG: TLabel;
    CB_Random: TCheckBox;
    Label2: TLabel;
    procedure B_OKClick(Sender: TObject);
    procedure B_CancelClick(Sender: TObject);
    procedure CB_ClearBackgroundClick(Sender: TObject);
    procedure TB_MouseSensChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CB_OnImmKeyStopClick(Sender: TObject);
    procedure UD_MorphSpeedClick(Sender: TObject; Button: TUDBtnType);
    procedure UD_MorphRangeClick(Sender: TObject; Button: TUDBtnType);
    procedure TB_XShiftChange(Sender: TObject);
    procedure TB_YSwapChange(Sender: TObject);
    procedure CB_ColorCycleClick(Sender: TObject);
    procedure TB_ColorIntensityChange(Sender: TObject);
    procedure TB_CoreWaveChange(Sender: TObject);
    procedure CB_XtraClick(Sender: TObject);
    procedure CB_HarmonicaClick(Sender: TObject);
    procedure TB_GapChange(Sender: TObject);
    procedure CB_BGCycleClick(Sender: TObject);
    procedure TB_SpanChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CB_ColorBurstClick(Sender: TObject);
    procedure TB_BurstIntensityChange(Sender: TObject);
    procedure CB_FadePointsClick(Sender: TObject);
    procedure CB_StarsClick(Sender: TObject);
    procedure CB_MultiColStarsClick(Sender: TObject);
    procedure TB_NrOfStarsChange(Sender: TObject);
    procedure CB_3DRotClick(Sender: TObject);
    procedure TB_3DRotXChange(Sender: TObject);
    procedure TB_3DRotYChange(Sender: TObject);
    procedure TB_3DRotZChange(Sender: TObject);
    procedure Img_Wave360DblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Img_Wave180DblClick(Sender: TObject);
    procedure Img_Wave540DblClick(Sender: TObject);
    procedure Img_Wave720DblClick(Sender: TObject);
    procedure UD_LineWidthClick(Sender: TObject; Button: TUDBtnType);
    procedure CB_ChangeWallpaperClick(Sender: TObject);
    procedure L_ChangeWallpaperClick(Sender: TObject);
    procedure TP_ch3DfxClick(Sender: TObject);
    procedure TP_chOpenGLClick(Sender: TObject);
    procedure L_AuthorMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure CB_ClearBGClick(Sender: TObject);
    procedure CB_RandomClick(Sender: TObject);
  private
    procedure CBSelection;
    procedure ImgSelection;
    procedure CheckParamsFromINI;
  public
//    procedure WMNCHitTest(var M: TWMNCHitTest); message WM_NCHitTest;
  end;

var ConfigScreen: TConfigScreen;


implementation
uses check, INISettings, ConfigRCform, wallpaperform;
{$R *.DFM}

(*!!!!DEBUG  want label-click-events werken niet}
procedure TConfigScreen.WMNCHitTest(var M: TWMNCHitTest);
begin
  inherited; { call the inherited message handler }
  if (M.Result = htClient) and OpDeTitelBalk then begin
//       M.Result := htCaption;
  end;
end;
*)

procedure TConfigScreen.FormShow(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
  ConfigRCScreen.ModalResult:=-1;
  PicsForm.ModalResult:=-1;
  {--- process the INI-file}
  CFG.ReadINI;
  if CFG.INI_OK then CheckParamsFromINI else close;
  {---}
end;

procedure TConfigScreen.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ConfigRCScreen.ModalResult:=-1;
  PicsForm.ModalResult:=-1;
end;



procedure TConfigScreen.CB_ClearBGClick(Sender: TObject);
begin
  //
end;

procedure TConfigScreen.CB_ClearBackgroundClick(Sender: TObject);
begin
  CFG.ClearBackground:=CB_ClearBackground.checked
end;

procedure TConfigScreen.CB_OnImmKeyStopClick(Sender: TObject);
begin
  CFG.OnImmKeyStop:=CB_OnImmKeyStop.Checked
end;


procedure TConfigScreen.CB_XtraClick(Sender: TObject);
begin
  CFG.Xtra:=CB_Xtra.checked
end;

procedure TConfigScreen.CB_ColorBurstClick(Sender: TObject);
begin
  CFG.ColorBurst:=CB_ColorBurst.checked
end;

procedure TConfigScreen.CB_BGCycleClick(Sender: TObject);
begin
  CFG.BGCycle:=CB_BGCycle.checked;
  if CB_BGCycle.checked then ConfigRCScreen.ShowModal
end;


procedure TConfigScreen.L_ChangeWallpaperClick(Sender: TObject);
begin
  {if CB_ChangeWallpaper.checked then }PicsForm.ShowModal
end;

procedure TConfigScreen.CB_ChangeWallpaperClick(Sender: TObject);
begin
  CFG.ChangeWallpaper:=CB_ChangeWallpaper.checked;
end;

procedure TConfigScreen.CB_ColorCycleClick(Sender: TObject);
begin
  CFG.ColorCycle:=CB_ColorCycle.Checked
end;

procedure TConfigScreen.CB_HarmonicaClick(Sender: TObject);
begin
  CFG.Harmonica:=CB_Harmonica.Checked
end;

procedure TConfigScreen.CB_FadePointsClick(Sender: TObject);
begin
  CFG.FadePoints:=CB_FadePoints.checked
end;

procedure TConfigScreen.CB_StarsClick(Sender: TObject);
begin
  CFG.Stars:=CB_Stars.checked
end;

procedure TConfigScreen.CB_MultiColStarsClick(Sender: TObject);
begin
  CFG.MultiColorStars:=CB_MultiColStars.checked
end;

procedure TConfigScreen.CB_3DRotClick(Sender: TObject);
begin
  CFG._3DRot:=CB_3DRot.checked
end;

procedure TConfigScreen.CB_RandomClick(Sender: TObject);
begin
  CFG.RandomShow:=CB_Random.checked; 
end;


procedure TConfigScreen.ImgSelection;
begin
  ShowCursor(false);
  case CFG.Wavepart of
    180: begin Img_Wave180.visible:=true; Img_Wave720.visible:=false; end;
    360: begin Img_Wave360.visible:=true; Img_Wave180.visible:=false; end;
    540: begin Img_Wave540.visible:=true; Img_Wave360.visible:=false; end;
    720: begin Img_Wave720.visible:=true; Img_Wave540.visible:=false; end;
  end;
  ShowCursor(true);
end;

procedure TConfigScreen.Img_Wave180DblClick(Sender: TObject);
begin
  CFG.WavePart:=360;
  ImgSelection
end;

procedure TConfigScreen.Img_Wave360DblClick(Sender: TObject);
begin
  CFG.WavePart:=540;
  ImgSelection
end;

procedure TConfigScreen.Img_Wave540DblClick(Sender: TObject);
begin
  CFG.WavePart:=720;
  ImgSelection
end;

procedure TConfigScreen.Img_Wave720DblClick(Sender: TObject);
begin
  CFG.WavePart:=180;
  ImgSelection
end;



procedure TConfigScreen.TB_NrOfStarsChange(Sender: TObject);
begin
  CFG.NrOfStars:=TB_NrOfStars.position
end;

procedure TConfigScreen.TB_3DRotXChange(Sender: TObject);
begin
  CFG._3DRotX:=TB_3DRotX.position
end;

procedure TConfigScreen.TB_3DRotYChange(Sender: TObject);
begin
  CFG._3DRotY:=TB_3DRotY.position
end;

procedure TConfigScreen.TB_3DRotZChange(Sender: TObject);
begin
  CFG._3DRotZ:=TB_3DRotZ.position
end;

procedure TConfigScreen.TB_MouseSensChange(Sender: TObject);
begin
  CFG.MouseSens:=TB_MouseSens.Position;
end;

procedure TConfigScreen.TB_YSwapChange(Sender: TObject);
begin
  CFG.YSwap:=0.005*(10-TB_YSwap.position);
  {}
  TB_YSwap.SelStart:=TB_YSwap.Position;
  TB_YSwap.SelEnd:=10;
end;

procedure TConfigScreen.TB_ColorIntensityChange(Sender: TObject);
begin
  CFG.ColIntensity:=TB_ColorIntensity.position;
end;

procedure TConfigScreen.TB_BurstIntensityChange(Sender: TObject);
begin
  CFG.BurstIntensity:=TB_BurstIntensity.position
end;

procedure TConfigScreen.TB_CoreWaveChange(Sender: TObject);
begin
  CFG.CoreWave:=1.0+(TB_CoreWave.Position*0.01);
end;

procedure TConfigScreen.CBSelection;
begin
  if CFG.WaveGap<=CFG.Span then begin
    TB_Span.SelStart:={TB_Gap.position} TB_Span.min;
    TB_Gap.SelStart:=TB_Gap.position;
    TB_Span.SelEnd:=TB_Span.position;
    TB_Gap.SelEnd:=TB_Span.position;
  end else {CFG.WaveGap>CFG.Span} begin
    TB_Span.SelStart:={TB_Span.position} TB_Span.min;
    TB_Gap.SelStart:=TB_Span.position;
    TB_Span.SelEnd:={TB_Gap.position} TB_Span.position;
    TB_Gap.SelEnd:=TB_Gap.position;
  end;
end;

procedure TConfigScreen.TB_GapChange(Sender: TObject);
begin
  CFG.WaveGap:=TB_Gap.position;
  CBSelection
end;

procedure TConfigScreen.TB_SpanChange(Sender: TObject);
begin
  CFG.Span:=TB_Span.Position;
  CBSelection
end;

procedure TConfigScreen.TB_XShiftChange(Sender: TObject);
begin
  CFG.PhaseShift:=TB_XShift.position;
  {}
  with TB_XShift do begin
    if position<0 then begin
      SelStart:=position;
      SelEnd:=0;
    end;
    if position=0 then begin
      SelStart:=0;
      SelEnd:=0;
    end;
    if position>0 then begin
      SelStart:=0;
      SelEnd:=position;
    end
  end
end;


procedure TConfigScreen.UD_MorphRangeClick(Sender: TObject;  Button: TUDBtnType);
begin
  CFG.XMorph:=0.025*UD_MorphRange.Position;
  L_MorphRange.Caption:=IntToStr(UD_MorphRange.Position);
end;

procedure TConfigScreen.UD_MorphSpeedClick(Sender: TObject;  Button: TUDBtnType);
begin
  CFG.MorphSpeed:=0.00001*UD_MorphSpeed.Position;
  L_MorphSpeed.Caption:=IntToStr(UD_MorphSpeed.Position);
end;

procedure TConfigScreen.UD_LineWidthClick(Sender: TObject;  Button: TUDBtnType);
begin
  CFG.LineWidth:=UD_LineWidth.position;
  L_LineWidth.Caption:=IntToStr(UD_LineWidth.Position);
end;


procedure TConfigScreen.B_OKClick(Sender: TObject);
begin
  CFG.WriteINI;
  Close
end;

procedure TConfigScreen.B_CancelClick(Sender: TObject);
begin
  Close
end;


{================================================================}


procedure TConfigScreen.CheckParamsFromINI;
begin
  L_Author.caption:='    '+CFG.Author;
  CB_ClearBackground.checked:=CFG.ClearBackground;
  CB_OnImmKeyStop.Checked:=CFG.OnImmKeyStop;
  CB_ColorCycle.Checked:=CFG.ColorCycle;
  CB_Harmonica.Checked:=CFG.Harmonica;
  CB_Xtra.checked:=CFG.Xtra;
  CB_BGCycle.checked:=CFG.BGCycle;
  CB_FadePoints.checked:=CFG.FadePoints;
  CB_Stars.checked:=CFG.Stars;
  CB_MultiColStars.checked:=CFG.MultiColorStars;
  CB_ColorBurst.checked:=CFG.ColorBurst;
  CB_3DRot.checked:=CFG._3DRot;
  CB_Random.Checked:=CFG.RandomShow;
  CB_ChangeWallpaper.checked:=CFG.ChangeWallpaper;
  TB_MouseSens.Position:=CFG.MouseSens;
  UD_MorphSpeed.Position:=Round(CFG.MorphSpeed/0.001);
  L_MorphSpeed.Caption:=IntToStr(UD_MorphSpeed.Position);
  UD_MorphRange.Position:=Round(CFG.XMorph/0.025);
  L_MorphRange.Caption:=IntToStr(UD_MorphRange.Position);
  UD_LineWidth.position:=CFG.LineWidth;
  L_LineWidth.Caption:=IntToStr(UD_LineWidth.Position);
  TB_NrOfStars.position:=CFG.NrOfStars;
  TB_XShift.position:=CFG.PhaseShift;  TB_XShiftChange(Self);
  TB_YSwap.position:=10-Round(CFG.YSwap/0.005);  TB_YSwapChange(Self);
  TB_ColorIntensity.position:=CFG.ColIntensity;
  TB_BurstIntensity.position:=CFG.BurstIntensity;
  TB_CoreWave.Position:=Round((CFG.CoreWave-1.0)/0.01);
  TB_3DRotX.position:=CFG._3DRotX;
  TB_3DRotY.position:=CFG._3DRotY;
  TB_3DRotZ.position:=CFG._3DRotZ;
  TB_Gap.position:=CFG.WaveGap;
  TB_Span.Position:=CFG.Span;
  CBSelection;  {voor de TB_Gap & TB_Span}
  ImgSelection; {voor de WavePart sinus images}
  {tray popupmenu}
  if CFG.Saver3Dfx then TP_ch3Dfx.checked:=true
                   else TP_chOpenGL.checked:=true;
end;



procedure TConfigScreen.FormCreate(Sender: TObject);
var tS: string;
//    ScreenSaving: boolean;
begin
//  {check if screensaving is enabled by user; else give msg}
//  SystemParametersInfo(SPI_GETSCREENSAVEACTIVE,0,@ScreenSaving,0);
//  if not ScreenSaving then
//    MessageDlg('Screensaving is not activated by you.'#13#10#13#10'   (Just to let you know..)',mtInformation,[mbOK],0);
    {}
  {change develop-time Img-coordinates}
  Img_Wave180.top:=Img_Wave360.top;
  Img_Wave540.top:=Img_Wave360.top;
  Img_Wave720.top:=Img_Wave360.top;
  Img_Wave180.left:=Img_Wave360.left;
  Img_Wave540.left:=Img_Wave360.left;
  Img_Wave720.left:=Img_Wave360.left;
  {visual thingies}
  tS:=HCoreInfo.getOS;
  if tS='' then tS:='Windows';
  tS:=tS+'    ';
  L_OSVersion.Caption:=tS+HCoreInfo.getOSVersion;
  L_Processor.Caption:='Processor info : '+HCoreInfo.GetProcessor;
  {}
end;





{=========== tray popup-menu ============================}

procedure TConfigScreen.TP_ch3DfxClick(Sender: TObject);
begin
  CFG.Saver3Dfx:=true;
  TP_ch3Dfx.checked:=true
end;

procedure TConfigScreen.TP_chOpenGLClick(Sender: TObject);
begin
  CFG.Saver3Dfx:=false;
  TP_chOpenGL.checked:=true
end;


procedure TConfigScreen.L_AuthorMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //een muisklik naar de captionbar "verplaatsen"
  ReleaseCapture;
  ConfigScreen.perform(WM_SysCommand, $F012, 0);
end;


end.
