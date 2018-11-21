program GLGGHGnap;

{-Opm.: bij gebruik vanuit trishell: als de 'Description' de tekst RP1 bevat
  dan wordt de 'GLG/GHG' berekend van een tijdsafhankelijke RP1 dataset
  (t.b.v. bepalen drainageweerstanden.

  KVI 170106  }

uses
  Forms,
  USelectGLGGHGnap in 'USelectGLGGHGnap.pas' {OKBottomDlg},
  uGLGGHGnap in 'uGLGGHGnap.pas' {OKBottomDlg1},
  IniFiles,
  OpWString,
  Dutils,
  SysUtils,
  Dialogs,
  windows,
  Controls,
  system.UITypes,
  UminMaxJaar in 'UminMaxJaar.pas' {OKBottomDlg2},
  uShowResults in 'uShowResults.pas' {OKDialogResults};

var
  f_ini: TiniFile;
  RunDirStr, cfgFileStr, MapFileStr, ExpressionStr, DefaultStr, DescriptionStr,
  ResultFileStr, ResultSetStr, CurrDirBuf, MinTimeStr, MaxTimeStr, MvGridStr,
  TriwacoGridfileStr, ClsNdsFltFileStr: String;

{$R *.RES}

Function GetSetNameFromDescriptionString( const DescriptionStr: String ): String;
var Len: Integer;
const
  WordDelims = ['#'];
begin
  Result := ExtractWord( 2,  DescriptionStr, WordDelims, Len );
  if ( Len = 0 ) then
    Result := '';
end;
Procedure GetMinMaxTimeString( const ExpressionStr: String; var MinTimeStr, MaxTimeStr: String );
var Len: Integer;
const
  WordDelims = [' '];
begin
  MinTimeStr := ExtractWord( 1,  Trim(ExpressionStr), WordDelims, Len );
  if ( Len = 0 ) then
    MinTimeStr := '0';
  MaxTimeStr := ExtractWord( 2,  Trim(ExpressionStr), WordDelims, Len );
  if ( Len = 0 ) then
    MaxTimeStr := '9999999999999';
end;

begin
  Application.Initialize;
  Application.HelpFile := 'GLGGHGNAP.HLP';
  Application.CreateForm(TOKBottomDlg1, OKBottomDlg1);
  Application.CreateForm(TOKBottomDlg, OKBottomDlg);
  Application.CreateForm(TOKBottomDlg2, OKBottomDlg2);
  Application.CreateForm(TOKDialogResults, OKDialogResults);
  if ( ParamCount >= 3 ) then begin

    Mode := Batch;
    RunDirStr   := ParamStr( 1 );
    cfgFileStr  := RunDirStr + '\' + ParamStr( 3 );
    f_ini := TiniFile.Create( cfgFileStr );
    MapFileStr     := f_ini.ReadString( 'Allocator', 'datasource', 'Error' ); {-Triwaco 4}
    if ( MapFileStr = 'Error' ) then begin
      MapFileStr     := f_ini.ReadString( 'Allocator', 'mapfile', 'Error' );  {-Triwaco 3}
      ExpressionStr  := f_ini.ReadString( 'Allocator', 'expression', 'Error' );
      MvGridStr := '';          {-geen GxG output ESRII grids gemaakt}
      TriwacoGridfileStr := '';
      ClsNdsFltFileStr := '';
    end else begin
      ExpressionStr  := f_ini.ReadString( 'Allocator', 'options', 'Error' );
      MvGridStr :=  f_ini.ReadString( 'Allocator', 'idfield', 'Error' );
      TriwacoGridfileStr := f_ini.ReadString( 'Allocator', 'gridfile', 'Error' );
      ClsNdsFltFileStr := ExtractFileDir(  TriwacoGridfileStr )  + '\clsndsf';
    end;

    DefaultStr     := f_ini.ReadString( 'Allocator', 'default', 'Error' );
    ResultFileStr  := f_ini.ReadString( 'Allocator', 'resultfile', 'Error' );
    ResultSetStr   := f_ini.ReadString( 'Allocator', 'setname', 'Error' );
    DescriptionStr := f_ini.ReadString( 'Allocator', 'description', 'Error' );
    f_ini.Free;

    with OKBottomDlg1 do begin
      EditFloFileName.Text       := Trim( MapFileStr );
      GetMinMaxTimeString( ExpressionStr, MinTimeStr, MaxTimeStr );
      MaskEditMinTime.Text       := Trim( MinTimeStr );
      MaskEditMaxTime.Text       := Trim( MaxTimeStr );
      EditDecadeLengte.Text      := Trim( DefaultStr );
      SaveAdoFileDialog.FileName := Trim( ResultFileStr );
      EditESRIgrid.Text          := Trim( MvGridStr );
      EditGridFile.Text          := Trim( TriwacoGridfileStr );
      EditClsNdsFltFileName.Text := Trim( ClsNdsFltFileStr );
      EditSetName.Text := GetSetNameFromDescriptionString( DescriptionStr );
      if ( EditSetName.Text = '' ) then
        EditSetName.Text := 'PHIT';
      CurrDirBuf                 := GetCurrentDir;
      SetCurrentDir( ExtractFileDir( ResultFileStr ) );


      Try
        MinTime      := StrToFloat( Trim( MaskEditMinTime.Text ) );
        MaxTime      := StrToFloat( Trim( MaskEditMaxTime.Text ) );
        DecadeLength := StrToFloat( Trim( EditDecadeLengte.Text ) );
      Except
        if ( Mode = Interactive ) then begin
          MessageDlg( 'Invalid input value(s): values replaced by defaults', mtWarning, [mbOk], 0);
          MaskEditMinTime.Text  := '360';
          EditDecadeLengte.Text := '10';
        end else begin
          showmessage('Specificeer decadelengte bij DEFAULT en min en maxtime bij OPTIONS');
          //MessageBeep( MB_ICONASTERISK );
          SetCurrentDir( CurrDirBuf );
          Exit;
        end;
      end;
    end; {-with OKBottomDlg1}

    {showmessage('ik ben er door');}
    if pos( 'DEBUG', Uppercase( DescriptionStr ) ) <> 0 then
      Mode := Interactive;
  end else begin
    if OKBottomDlg.ShowModal = mrCancel then {-Gebruik prn-file}
      Exit;
  end;

  if ( Mode = Interactive ) then begin
    MessageDlg( 'Interactive', mtInformation, [mbOk], 0);
    Application.Run;
  end else begin
    {MessageDlg( 'Batch', mtInformation, [mbOk], 0);}
    OKBottomDlg1.OKBtn.Click;
  end;
  SetCurrentDir( CurrDirBuf );
end.
