unit UminMaxJaar;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

type
  TOKBottomDlg2 = class(TForm)
    OKBtn: TButton;
    Bevel1: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    EditMinJaar: TEdit;
    EditAantalJaren: TEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OKBottomDlg2: TOKBottomDlg2;

implementation

{$R *.DFM}

end.
