unit wallpaperform;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtDlgs, StdCtrls, jpeg, ExtCtrls;

type
  TPicsForm = class(TForm)
    LB_BMPs: TListBox;
    B_Add: TButton;
    B_Remove: TButton;
    B_OK: TButton;
    B_Cancel: TButton;
    Image1: TImage;
    OPicDlg: TOpenPictureDialog;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure B_AddClick(Sender: TObject);
    procedure B_RemoveClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure B_OKClick(Sender: TObject);
    procedure B_CancelClick(Sender: TObject);
    procedure LB_BMPsClick(Sender: TObject);
  private
    procedure CopyCFGToList(hold2: boolean);
    procedure RefreshButtons;
  public
    procedure WMNCHitTest(var M: TWMNCHitTest); message wm_NCHitTest;
  end;

var
  PicsForm: TPicsForm;
  KeepPath: array[0..9] of string;

implementation
uses INISettings;

{$R *.DFM}


procedure TPicsForm.WMNCHitTest(var M: TWMNCHitTest);
begin
  inherited;                    { call the inherited message handler }
  if  M.Result = htClient then  { is the click in the client area?   }
    M.Result := htCaption;      { if so, make Windows think it's     }
                                { on the caption bar.                }
end;

procedure TPicsForm.RefreshButtons;
begin
  B_Add.Enabled:=(LB_BMPs.Items.Count<10);
  B_Remove.Enabled:=((LB_BMPs.Items.Count>0) and
                     (LB_BMPs.SelCount>0));
end;

procedure TPicsForm.CopyCFGToList(hold2: boolean);
var ii: integer;
begin
  LB_BMPs.Items.Clear;
  for ii:=0 to 9 do begin
    {make a copy for the 'cancel'-function}
    if hold2 then KeepPath[ii]:=CFG.bmp[ii];
    if CFG.bmp[ii]<>'' then
      LB_BMPs.Items.Add(CFG.bmp[ii]);
  end;
end;


procedure TPicsForm.FormActivate(Sender: TObject);
begin
  CopyCFGToList(true);
  RefreshButtons;
end;

procedure TPicsForm.FormClose(Sender: TObject; var Action: TCloseAction);
var ii: integer;
begin
  for ii:=0 to LB_BMPs.Items.Count-1 do
    CFG.bmp[ii]:=LB_BMPs.Items.Strings[ii];
  for ii:=LB_BMPs.Items.Count to 9 do
    CFG.bmp[ii]:='';
  ModalResult:=-1
end;

procedure TPicsForm.B_AddClick(Sender: TObject);
var ii,Poss: integer;
begin
  OPicDlg.InitialDir:=CFG.LastPath;
  if OPicDlg.Execute then
    if OPicDlg.Files.Count>0 then begin
      CFG.LastPath:=ExtractFileDir(OPicDlg.Files.Strings[0]);
      Poss:=9-(LB_BMPs.Items.Count-1);
      if OPicDlg.Files.Count<Poss then Poss:=OPicDlg.Files.Count;
      for ii:=0 to Poss-1 do
        LB_BMPs.Items.Add(OPicDlg.Files.Strings[ii]);
    end;
  RefreshButtons;
end;

procedure TPicsForm.B_RemoveClick(Sender: TObject);
var ii: integer;
begin
  for ii:=9 downto 0 do
    if ii<LB_BMPs.Items.Count then
      if LB_BMPs.Selected[ii] then LB_BMPs.Items.Delete(ii);
  RefreshButtons;
end;

procedure TPicsForm.B_OKClick(Sender: TObject);
begin
  ModalResult:=-1
end;

procedure TPicsForm.B_CancelClick(Sender: TObject);
var ii: integer;
begin
  for ii:=0 to 9 do
    {restore the copy}
    CFG.bmp[ii]:=KeepPath[ii];
  CopyCFGToList(false);
  ModalResult:=-1
end;

procedure TPicsForm.LB_BMPsClick(Sender: TObject);
begin
  RefreshButtons
end;


end.
