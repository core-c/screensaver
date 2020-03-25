unit configRCform;
interface
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, jpeg, ExtCtrls;

type
  TConfigRCScreen = class(TForm)
    Img_Background: TImage;
    L_Author: TLabel;
    B_OK: TButton;
    L_RCCInfo: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Me: TImage;
    procedure B_OKClick(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
  public
    procedure WMNCHitTest(var M: TWMNCHitTest); message wm_NCHitTest;
  end;

var
  ConfigRCScreen: TConfigRCScreen;

implementation
uses configform;
{$R *.DFM}

procedure TConfigRCScreen.WMNCHitTest(var M: TWMNCHitTest);
begin
  inherited;                    { call the inherited message handler }
  if  M.Result = htClient then  { is the click in the client area?   }
    M.Result := htCaption;      { if so, make Windows think it's     }
                                { on the caption bar.                }
end;

procedure TConfigRCScreen.B_OKClick(Sender: TObject);
var eenTellertjeDatTelt: double;
begin
  Me.visible:=true;  Me.refresh;
  eenTellertjeDatTelt:=Now;
  repeat until Now>eenTellertjeDatTelt+ 0.4{sec}/(60*60*24) ;
  Me.visible:=false;  Me.refresh;
  ConfigRCScreen.ModalResult:=-1;
end;

procedure TConfigRCScreen.FormDeactivate(Sender: TObject);
begin
  ConfigRCScreen.ModalResult:=-1;
end;

procedure TConfigRCScreen.FormActivate(Sender: TObject);
begin
  top:=ConfigScreen.top+48;
  Left:=ConfigScreen.left+16;
end;

end.
