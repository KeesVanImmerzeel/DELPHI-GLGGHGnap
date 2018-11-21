unit uShowResults;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

type
  TOKDialogResults = class(TForm)
    OKBtn: TButton;
    Bevel1: TBevel;
    MemoResults: TMemo;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OKDialogResults: TOKDialogResults;

implementation

{$R *.DFM}

end.
