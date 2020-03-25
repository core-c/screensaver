program HCore;
{$UNDEF PrevInst_Method}
uses
{  PrevInst in 'PrevInst.pas',}
  check in 'check.pas',
  INIsettings in 'INIsettings.pas',
  saverform in 'saverform.pas',
  windows,
  Forms,
  Dialogs,
  GLAnimate in 'GLAnimate.pas',
  configform in 'configform.pas',
  previewform in 'previewform.pas',
  configRCform in 'configRCform.pas' {RightClick on file},
  wallpaperform in 'wallpaperform.pas' {PicsForm},
  waves in 'waves.pas';

            {=================================}
            {== PreviewScreen.left= -300 !! ==}
            {== form valt uit beeld !!!!!!! ==}
            {=================================}
{$E .scr}
{$D SCRNSAVE: HCore}
{$R *.RES}
begin
  if HPrevInst<>0 then begin
    {$IFDEF PrevInst_Method}
      ActivatePreviousInstance;
    {$ENDIF}
    Halt;
  end;
  Application.Title:='HCore';
  Application.Initialize;
  Application.HintPause:=150;
  Application.HintHidePause:=5000;
  Application.HintShortPause:=500;
  case SaverMode of
    FullScreenMode : Application.CreateForm(TSaverScreen, SaverScreen);
    PreviewMode    : if (ParamHandle<>0){ and
                        (not HCoreInfo.RunningWin95) and
                        (not HCoreInfo.RunningWin31)} then
                       Application.CreateForm(TPreviewScreen, PreviewScreen);
    ConfigMode, ConfigRCMode : begin
        Application.CreateForm(TConfigScreen, ConfigScreen);
        Application.CreateForm(TConfigRCScreen, ConfigRCScreen);
        Application.CreateForm(TPicsForm, PicsForm);
      end;
    PasswordMode   : begin
        SetPwd;
//        MessageDlg('HCore says: Password security not implemented yet.', mtInformation, [mbIgnore], 0);
        Halt;
      end;
  end;
  Application.Run;
end.

