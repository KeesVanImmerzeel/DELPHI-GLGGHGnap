unit uGLGGHGnap;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, Dialogs, LargeArrays, AdoSets, OpWString, Mask, FileCtrl,
  uTSingleESRIgrid, uError, uTriwacoGrid, AVGRIDIO, uTabstractESRIgrid,
  System.UITypes;

{.$Define Test}

type
  TOKBottomDlg1 = class(TForm)
    OKBtn: TButton;
    Bevel1: TBevel;
    Label1: TLabel;
    EditFloFileName: TEdit;
    SelectFloFileNameDialog: TOpenDialog;
    SaveAdoFileDialog: TSaveDialog;
    SelectFloFileButton: TButton;
    EditDecadeLengte: TMaskEdit;
    Label4: TLabel;
    Label2: TLabel;
    MaskEditMinTime: TMaskEdit;
    PHITAdoSet: TRealAdoSet;
    GLGsumSet: TRealAdoSet;
    GHGsumSet: TRealAdoSet;
    GemSet: TRealAdoSet;
    MinSet: TRealAdoSet;
    MaxSet: TRealAdoSet;
    Min1YearSet: TLargeRealArray;
    Max1YearSet: TLargeRealArray;
    Max2YearSet: TLargeRealArray;
    Min2YearSet: TLargeRealArray;
    Min3YearSet: TLargeRealArray;
    Max3YearSet: TLargeRealArray;
    GVGset: TRealAdoSet;
    GLGdaySumSet: TRealAdoSet;
    GHGdaySumSet: TRealAdoSet;
    Min1DayNrSet: TLargeIntegerArray;
    Max1DayNrSet: TLargeIntegerArray;
    Min2DayNrSet: TLargeIntegerArray;
    Max2DayNrSet: TLargeIntegerArray;
    Min3DayNrSet: TLargeIntegerArray;
    Max3DayNrSet: TLargeIntegerArray;
    GemSumSet: TLargeRealArray;
    Label3: TLabel;
    EditSetName: TEdit;
    Label5: TLabel;
    MaskEditMaxTime: TMaskEdit;
    EditAdoSetRead: TEdit;
    LabelAdoSetRead: TLabel;
    EditESRIgrid: TEdit;
    Label6: TLabel;
    SingleESRImvGrid: TSingleESRIgrid;
    GHGmvESRIgrid: TSingleESRIgrid;
    Label7: TLabel;
    EditGridFile: TEdit;
    OpenGridFileDialog: TOpenDialog;
    aTriwacoGrid: TtriwacoGrid;
    EditClsNdsFltFileName: TEdit;
    Label8: TLabel;
    SingleESRIgridclsndsflt: TSingleESRIgrid;
    GLGmvESRIgrid: TSingleESRIgrid;
    GVGmvESRIgrid: TSingleESRIgrid;
    Peilbuislokaties: TDbleMtrxUngPar;
    GtESRIgrid: TSingleESRIgrid;
    procedure SelectFloFileButtonClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure EditESRIgridClick(Sender: TObject);
    procedure EditGridFileClick(Sender: TObject);
    procedure EditClsNdsFltFileNameClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
  TMode = (Batch, Interactive);

var
  OKBottomDlg1: TOKBottomDlg1;
  MinTime, MaxTime, DecadeLength: Double;
  Mode: TMode;

implementation

{$R *.DFM}
procedure TOKBottomDlg1.SelectFloFileButtonClick(Sender: TObject);
begin
  if SelectFloFileNameDialog.Execute then begin
    EditFloFileName.Text := SelectFloFileNameDialog.FileName;
  end;
end;

procedure TOKBottomDlg1.OKBtnClick(Sender: TObject);
var
  f, {lf,} g, h: TextFile;
  aTime, YearLength, aHead, TVoorjaar, aValue: Double;
  LineNr, SetCount, GLGCount, GVGCount, NrSetsInYear, iCellCount: LongWord;
  MsgDlgType: TMsgDlgType;
  Save_Cursor:TCursor;
  ISetIdStr, PlaatjesDirStr, PeilbuisFileNamStr, GxGCalcFileNameStr: String;
  Initiated, Finished: Boolean;
  AcoSetSize, CurrentYear, YearNr, DayNr, i, NrOfValuesEvaluated, iResult,
  NRows, NCols, j: Integer;

  nod1, nod2, nod3, MaxNod1, MaxCellDepth, CellDepth: integer;
  x, y, Mv : Single;
  GHGmv, GLGmv, GVGmv, Gt, dist1, dist2, dist3, w1, w2, w3: double;
const
  cMaxDistForMvInterpolation = 100; {-Maximale afstand waarin maaiveldshoogte informatie nog bruikbaar wordt geacht}
  cMaxDistForGwLevelInterpolation = 500; {-Maximale afstand waarin berekende stijghoogte informatie nog bruikbaar wordt geacht}

  Procedure SetMinMaxGem;
  var
    i: Integer;
    aHead: Double;
  begin
    for i:=1 to AcoSetSize do begin
      aHead := PHITAdoSet[ i ];
      if ( aHead < MinSet[ i ] ) then MinSet[ i ] := aHead
      else if ( aHead > MaxSet[ i ] ) then MaxSet[ i ] := aHead;
      GemSumSet[ i ] := GemSumSet[ i ] + aHead;
    end;
  end; {-Procedure SetMinMaxGem;}

  Procedure SetYearMinMax;
  var
    i: Integer;
    aHead, Min1Year, Min2Year, Min3Year, Max1Year, Max2Year, Max3Year: Double;
    Min1DayNr, Min2DayNr, Max1DayNr, Max2DayNr: Integer;
  begin
    for i:=1 to AcoSetSize do begin
      aHead := PHITAdoSet[ i ];

      {-Jaar-minima}
      Min1Year  := Min1YearSet[ i ];
      Min1DayNr := Min1DayNrSet[ i ];
      if ( aHead < Min1Year ) then begin
        Min2Year          := Min2YearSet[ i ];
        Min1YearSet[ i ]  := aHead;
        Min2YearSet[ i ]  := Min1Year;
        Min3YearSet[ i ]  := Min2Year;

        Min2DayNr         := Min2DayNrSet[ i ];
        Min1DayNrSet[ i ] := DayNr;
        Min2DayNrSet[ i ] := Min1DayNr;
        Min3DayNrSet[ i ] := Min2DayNr;
      end else begin
        Min2Year  := Min2YearSet[ i ];
        Min2DayNr := Min2DayNrSet[ i ];
        if ( aHead < Min2Year ) then begin
          Min2YearSet[ i ]  := aHead;
          Min3YearSet[ i ]  := Min2Year;

          Min2DayNrSet[ i ] := DayNr;
          Min3DayNrSet[ i ] := Min2DayNr;
        end else begin
          Min3Year  := Min3YearSet[ i ];
          if ( aHead < Min3Year ) then begin
            Min3YearSet[ i ]  := aHead;
            Min3DayNrSet[ i ] := DayNr;
          end;
        end;
      end;

      {-Jaar-maxima}
      Max1Year  := Max1YearSet[ i ];
      Max1DayNr := Max1DayNrSet[ i ];
      if ( aHead > Max1Year ) then begin
        Max2year         := Max2YearSet[ i ];
        Max1YearSet[ i ] := aHead;
        Max2YearSet[ i ] := Max1Year;
        Max3YearSet[ i ] := Max2Year;

        Max2DayNr         := Max2DayNrSet[ i ];
        Max1DayNrSet[ i ] := DayNr;
        Max2DayNrSet[ i ] := Max1DayNr;
        Max3DayNrSet[ i ] := Max2DayNr;
      end else begin
        Max2Year  := Max2YearSet[ i ];
        Max2DayNr := Max2DayNrSet[ i ];
        if ( aHead > Max2Year ) then begin
          Max2YearSet[ i ] := aHead;
          Max3YearSet[ i ] := Max2Year;

          Max2DayNrSet[ i ] := DayNr;
          Max3DayNrSet[ i ] := Max2DayNr;
        end else begin
          Max3Year  := Max3YearSet[ i ];
          if ( aHead > Max3Year ) then begin
            Max3YearSet[ i ]  := aHead;
            Max3DayNrSet[ i ] := DayNr;
          end;
        end;
      end;
    end; {-for}
  end; {-Procedure SetYearMinMax}

  Procedure IncreaseSumSets;
  var
    i: Integer;
    Function MakeGHGDayNr( const GHGDayNr: Integer ): Integer;
    begin
      if ( GHGDayNr > ( YearLength / 2 ) ) then
        Result := GHGDaynR - Trunc( YearLength )
      else
        Result := GHGDayNr;
    end;
  begin
    if ( NrSetsInYear = 36 ) then begin
      WriteToLogFile( 'IncreaseSumSets' );
      for i:=1 to AcoSetSize do begin
        GLGSumSet[ i ] := GLGSumSet[ i ] + Min1YearSet[ i ] + Min2YearSet[ i ] + Min3YearSet[ i ];
        GHGSumSet[ i ] := GHGSumSet[ i ] + Max1YearSet[ i ] + Max2YearSet[ i ] + Max3YearSet[ i ];

        GLGDaySumSet[ i ] := GLGDaySumSet[ i ] + Min1DayNrSet[ i ] + Min2DayNrSet[ i ] + Min3DayNrSet[ i ];
        GHGDaySumSet[ i ] := GHGDaySumSet[ i ] +
                             MakeGHGDayNr( Max1DayNrSet[ i ] ) +
                             MakeGHGDayNr( Max2DayNrSet[ i ] ) +
                             MakeGHGDayNr( Max3DayNrSet[ i ] );
        GemSet[ i ]       := GemSet[ i ] + GemSumSet[ i ];
      end;
      GLGCount := GLGCount + 3;
    end else; {-doe niks als NrSetsInYear <> 36}
  end; {-Procedure IncreaseSumSets;}

  Function Decade( const aTime: Double ): Integer;
  begin
    Result := ( ( Round ( ( aTime - ( YearNr - 1 ) * YearLength ) / DecadeLength ) ) mod 36 ) + 1;
  end;

  Function Voorjaar: Boolean;
  begin
    Result := ( Decade( aTime ) = 10 );
  end;

    Function GetGt( const GHG, GLG: Double ): Double;
    begin
      if ( GLG <= 0.50 ) then GetGt := 10 else begin    { (A, B, C) 1 )}
        if ( GLG <= 0.80 ) then begin
          if      ( GHG <= 0.25 ) then GetGt := 20      { A 2 }
          else if ( GHG <= 0.40 ) then GetGt := 25      { B 2 }
          else                         GetGt := 40;     { C 2 }
        end else if ( GLG <= 1.20 ) then begin
          if      ( GHG <= 0.25 ) then GetGt := 30      { A 3 }
          else if ( GHG <= 0.40 ) then GetGt := 35      { B 3 }
          else if ( GHG <= 0.80 ) then GetGt := 40      { C 3 }
          else                         GetGt := 70;     { D 3 }
        end else begin
          if      ( GHG <= 0.25 ) then GetGt := 50      { A 4 }
          else if ( GHG <= 0.40 ) then GetGt := 55      { B 4 }
          else if ( GHG <= 0.80 ) then GetGt := 60      { C 4 }
          else if ( GHG <= 1.40 ) then GetGt := 70      { D 4 }
          else                         GetGt := 75;     { E 4 }
        end; {-if}
      end; {-if}
    end; {-Function GetGt}

begin

{$ifdef test}
  AssignFile( h, 'TestGLGGHGnap.log'); Rewrite( h );
{$endif}

  if ( not FileExists( EditFloFileName.Text ) ) then begin
    if ( Mode = Interactive ) then
      MessageDlg( 'File: "' + ExpandFileName( EditFloFileName.Text ) + '" does not exist.',
                  mtError, [mbOk], 0)
    else MessageBeep( MB_ICONASTERISK );
    Exit;
  end;

  //showmessage('hallo ik ben er');

  Try
    MinTime      := StrToFloat( Trim( MaskEditMinTime.Text ) );
    MaxTime      := StrToFloat( Trim( MaskEditMaxTime.Text ) );
    if ( MaxTime <= MinTime ) then
      Raise Exception.Create( 'MaxTime <= MinTime' );
    DecadeLength := StrToFloat( Trim( EditDecadeLengte.Text ) );
  Except
    if ( Mode = Interactive ) then
      MessageDlg( 'Invalid input value(s).', mtError, [mbOk], 0)
    else MessageBeep( MB_ICONASTERISK );
    Exit;
  end;

  With SaveAdoFileDialog do begin
    if ( Mode = Batch ) or ( ( Mode = Interactive ) and Execute ) then begin
      Try
        //AssignFile( lf, ExtractFileDir( ParamStr( 0 ) ) + '\GLGGHGnap.log' ); Rewrite( lf );
        WriteToLogFile( 'Opening file: "' + EditFloFileName.Text + '"' );
        AssignFile( f, EditFloFileName.Text ); Reset( f );
        // showmessage('flo file ' + ExpandFileName(EditFloFileName.Text)+ 'geopend.' );
      except
        //Try CloseFile( lf ); CloseFile( f ); except end;
        if ( Mode = Interactive ) then
          MessageDlg( 'Error opening file "' + EditFloFileName.Text + '"' + #13 +
                      'Check "GLGGHGnap.log"', mtError, [mbOk], 0)
        else MessageBeep( MB_ICONASTERISK );
        Exit;
      end;
      Try
        AssignFile( g, FileName ); Rewrite( g );
        WriteToLogFile( 'Creating file: "' + FileName + '"' );
      except
        //CloseFile( lf );
        if ( Mode = Interactive ) then
          MessageDlg( 'Error creating file "' + FileName + '"' + #13 +
                      'Check "GLGGHGnap.log"', mtError, [mbOk], 0)
        else MessageBeep( MB_ICONASTERISK );
        Exit;
      end;

      ISetIdStr := EditSetName.Text + ',$';

      SetCount          := 0;
      GLGCount          := 0;
      GVGCount          := 0;
      CurrentYear       := 0;
      NrSetsInYear      := 0;
      YearLength        := 36 * DecadeLength;
      TVoorjaar         :=  9 * DecadeLength;
      LineNr            := 0;
      Save_Cursor       := Screen.Cursor;
      Screen.Cursor     := crHourglass;    { Show hourglass cursor }
      Finished          := false;

      EditAdoSetRead.Text := '';
      EditAdoSetRead.Visible := true;
      LabelAdoSetRead.Visible := true;

      Try
        Repeat
          Try
            //Showmessage( 'zoek set ' + ISetIdStr );
            PHITAdoSet := TRealAdoSet.InitFromOpenedTextFile( f, ISetIdStr,
                           self, LineNr, Initiated );
          except
            Initiated := False;
          end;
          {Writeln( lf, 'Average value:' +
                        FormatFloat( '####.######', PHITAdoSet.GetStatInfo( Average, NrOfValuesEvaluated ) ) );}
          if Initiated then begin
            //showmessage('gevonden');

            EditAdoSetRead.Text := ISetIdStr;
            aTime := PHITAdoSet.AdoTime;
            WriteToLogFile( 'a PHITAdoSet is initiated. AdoTime, MinTime, MaxTime = ' +
              FloatToStr(aTime) + ' ' + FloatToStr(MinTime) + ' ' + FloatToStr(MaxTime) );
            Finished := ( aTime > MaxTime );
            YearNr := Trunc ( ( aTime + YearLength - TVoorjaar - 0.001 ) / YearLength );
            DayNr  := Trunc( aTime - YearLength*Trunc( aTime/YearLength ) );
{$ifdef test}
            WriteToLogFile( '--> aTime, YearNr, DecadeNr, DayNr: ', aTime:8:4, ' ', YearNr:5, ' ', Decade( aTime ), ' ', DayNr );
{$endif}
            if ( aTime > MinTime ) and ( not Finished ) then begin

              if ( SetCount = 0 ) then begin
                AcoSetSize  := PHITAdoSet.NrOfElements;

                Min1YearSet := TLargeRealArray.Create( AcoSetSize, self );
                Min2YearSet := TLargeRealArray.Create( AcoSetSize, self );
                Min3YearSet := TLargeRealArray.Create( AcoSetSize, self );
                Max1YearSet := TLargeRealArray.Create( AcoSetSize, self );
                Max2YearSet := TLargeRealArray.Create( AcoSetSize, self );
                Max3YearSet := TLargeRealArray.Create( AcoSetSize, self );
                GLGSumSet   := TRealAdoSet.CreateF( AcoSetSize, 'GLGNAP', 0, self );
                GHGSumSet   := TRealAdoSet.CreateF( AcoSetSize, 'GHGNAP', 0, self );

                Min1DayNrSet := TLargeIntegerArray.Create( AcoSetSize, self );
                Min2DayNrSet := TLargeIntegerArray.Create( AcoSetSize, self );
                Min3DayNrSet := TLargeIntegerArray.Create( AcoSetSize, self );
                Max1DayNrSet := TLargeIntegerArray.Create( AcoSetSize, self );
                Max2DayNrSet := TLargeIntegerArray.Create( AcoSetSize, self );
                Max3DayNrSet := TLargeIntegerArray.Create( AcoSetSize, self );
                GLGdaySumSet := TRealAdoSet.CreateF( AcoSetSize, 'GLGDAY', 0, self );
                GHGdaySumSet := TRealAdoSet.CreateF( AcoSetSize, 'GHGDAY', 0, self );

                MinSet      := TRealAdoSet.Create( AcoSetSize, 'MINNAP', self );
                MaxSet      := TRealAdoSet.Create( AcoSetSize, 'MAXNAP', self );
                GemSet      := TRealAdoSet.CreateF( AcoSetSize, 'GEMNAP', 0, self );
                GemSumSet   := TLargeRealArray.Create( AcoSetSize, self );

                Inc( SetCount ); Inc( NrSetsInYear );
                CurrentYear := YearNr; WriteToLogFile( 'YearNr: ' + IntToStr(YearNr) );
                for i:=1 to AcoSetSize do begin
                  aHead             := PHITAdoSet[ i ];
                  Min1YearSet[ i ]  := aHead;
                  Min2YearSet[ i ]  := aHead;
                  Min3YearSet[ i ]  := aHead;
                  Max1YearSet[ i ]  := aHead;
                  Max2YearSet[ i ]  := aHead;
                  Max3YearSet[ i ]  := aHead;

                  Min1DayNrSet[ i ] := DayNr;
                  Min2DayNrSet[ i ] := DayNr;
                  Min3DayNrSet[ i ] := DayNr;
                  Max1DayNrSet[ i ] := DayNr;
                  Max2DayNrSet[ i ] := DayNr;
                  Max3DayNrSet[ i ] := DayNr;

                  MinSet[ i ]       := aHead;
                  MaxSet[ i ]       := aHead;
                  GemSumSet[ i ]    := aHead;
                end; {-for NodeNr}

                if ( not Voorjaar ) then
                  GVGset := TRealAdoSet.CreateF( AcoSetSize, 'GVGNAP', 0, self )
                else begin
                  GVGset := TRealAdoSet.Create( AcoSetSize, 'GVGNAP', self );
                  // writeToLogFile( 'Time: ', aTime:6:1, ' Voorjaar' );
                  Inc( GVGCount );
                  for i:=1 to AcoSetSize do
                    GVGset[ i ] := PHITAdoSet[ i ];
                end;

              end else begin { SetCount > 0 (dus niet de eerste set in file}
                Inc( SetCount );

                if Voorjaar then begin
                  // writetologfile(  'Time: ', aTime:6:1, ' Voorjaar' );
                  Inc( GVGCount );
                  for i:=1 to AcoSetSize do
                    GVGset[ i ] := GVGset[ i ] + PHITAdoSet[ i ];
                end;

                if ( YearNr = CurrentYear ) then begin {-Geen jaarwisseling}
                  Inc( NrSetsInYear );
                  SetMinMaxGem;
                  SetYearMinMax;
                end else begin {-Wel jaarwisseling}
{$ifdef test}
                  Writeln( lf, 'YearNr, GemSumSet[1851]: ', YearNr, ' ', GemSumSet[ 1851 ]:8:2 );
{$endif}

                  IncreaseSumSets; {-Verwerk het resultaat van het jaar ervoor}
                  CurrentYear := YearNr;
                  {-Initialiseer het nieuwe jaar}
                  for i:=1 to AcoSetSize do begin
                    aHead             := PHITAdoSet[ i ];
                    Min1YearSet[ i ]  := aHead;
                    Min2YearSet[ i ]  := aHead;
                    Min3YearSet[ i ]  := aHead;
                    Max1YearSet[ i ]  := aHead;
                    Max2YearSet[ i ]  := aHead;
                    Max3YearSet[ i ]  := aHead;

                    Min1DayNrSet[ i ] := DayNr;
                    Min2DayNrSet[ i ] := DayNr;
                    Min3DayNrSet[ i ] := DayNr;
                    Max1DayNrSet[ i ] := DayNr;
                    Max2DayNrSet[ i ] := DayNr;
                    Max3DayNrSet[ i ] := DayNr;
                    GemSumSet[ i ]    := 0;
                  end;
                  SetMinMaxGem;
                  NrSetsInYear := 1;
                end; {- Year <> CurrentYear}
              end; {-SetCount > 0}

{$ifdef test}
              Writeln( h, 'aTime, YearNr, DayNr, aHead: ', aTime:8:1, ' ', YearNr, ' ', DayNr, ' ', PHITAdoSet[ 1851 ]:8:2 );
{$endif}
            end; {-if ( aTime > MinTime )}
            try {PHITAdoSet.free;} except; end;
          end; {-if Initiated}
          //showmessage('niet gevonden');
        until ( ( EOF( f ) ) or ( not Initiated ) or Finished );

        {-Verwerk de resultaten van het laatste jaar}
        Writetologfile( 'NrSetsInYear= ' + inttostr( NrSetsInYear ) );
        IncreaseSumSets;
        //Writetologfile( 'Sum sets increased. SetCount = ' + int( SetCount ) );
        if ( SetCount > 0 ) then begin
          {-Verwerk het eindresultaat tot gemiddelde grondwaterstanden}
          Try
            // Writetologfile( 'GLGCount= ' + int( GLGCount ) );
            {Min1YearSet.free;  Min2YearSet.free;  Min3YearSet.free;
            Max1YearSet.free;  Max2YearSet.free;  Max3YearSet.free;
            Min1DayNrSet.free; Min2DayNrSet.free; Min3DayNrSet.free;
            Max1DayNrSet.free; Max2DayNrSet.free; Max3DayNrSet.free;}
            for i:=1 to AcoSetSize do begin
              GLGSumSet[ i ] := GLGSumSet[ i ] / GLGCount;
              GHGSumSet[ i ] := GHGSumSet[ i ] / GLGCount;

              GLGDaySumSet[ i ] := GLGDaySumSet[ i ] / GLGCount;
              GHGDaySumSet[ i ] := GHGDaySumSet[ i ] / GLGCount;

              GemSet[ i ]    := GemSet[ i ] / ( GLGCount * 12 );
            end;
{$ifdef test}
            Writeln( lf, 'Gemiddelde knoop 1851:, GLGCount ', GemSet[ 1851 ]:8:3, ' ', GLGCount );
            Writeln( lf, 'GLG/GHG knoop 1851: ', GLGSumSet[ 1851 ]:8:3, ' ', GHGSumSet[ 1851 ]:8:3 );
{$endif}
            Writetologfile( 'GVGCount= ' + inttostr( GVGCount ) );
            if ( GVGCount > 1 ) then begin
              for i:=1 to AcoSetSize do
                GVGset[ i ] := GVGset[ i ] /  GVGCount;
            end;

            {-Schrijf de eindresultaten weg}
            GLGSumSet.ExportToOpenedTextFile( g );
            GHGSumSet.ExportToOpenedTextFile( g );

            GLGDaySumSet.ExportToOpenedTextFile( g );
            GHGDaySumSet.ExportToOpenedTextFile( g );

            MinSet.ExportToOpenedTextFile( g );
            MaxSet.ExportToOpenedTextFile( g );
            if ( GVGCount > 0 ) then
              GVGset.ExportToOpenedTextFile( g );
            GemSet.ExportToOpenedTextFile( g );

            Writetologfile(  'GxG ado sets are created.' );
            ShowMessage('GxG ado sets are created.');
            //MessageDlg( 'GxG ado sets are created.', mtInformation, [mbOk], 0);

            {GLGSumSet.free;    GHGSumSet.free;
            GLGdaySumSet.Free; GHGdaySumSet.Free;
            MinSet.free;       MaxSet.free;
            GemSet.Free; GemSumSet.Free;      GVGset.Free;}
            if not SysUtils.DirectoryExists( EditESRIgrid.Text ) then
              Raise Exception.Create( 'Directory [' + EditESRIgrid.Text + '] does not exist, so no attemt is made to initialise mv-grid.' );


            //showmessage('probeer maaiveldgrid te lezen');
            Writetologfile( 'Try to initialise mv grid ' + EditESRIgrid.Text );
            SingleESRImvGrid := TSingleESRIgrid.InitialiseFromESRIGridFile( EditESRIgrid.Text, iResult, self );
            if ( iResult <> cNoError ) then
              Raise Exception.Create( 'Cannot initialise mv grid ' + EditESRIgrid.Text );
            Writetologfile( 'mv grid [' + EditESRIgrid.Text + '] is read.' );
            //showmessage('gelukt');

{$ifdef test}
            Writeln( lf, 'Initialising triwaco grid [' + EditGridFile.text + '].' );
            AssignFile( h,  EditGridFile.text ); Reset( h );
            LineNr := 0;
            aTriwacoGrid := TTriwacoGrid.InitFromOpenedTextFile( h, lf, self, LineNr, Initiated );
            CloseFile( h );
            if Initiated then
              Writeln( lf, 'Triwaco grid [' + EditGridFile.text + '] is initialised.' )
            else
              Raise Exception.Create( 'Triwaco grid [' + EditGridFile.text + '] is NOT initialised.' );
{$endif}

            Writetologfile( 'Initialising triwaco grid [' + EditGridFile.text + '].' );
            aTriwacoGrid := TTriwacoGrid.InitFromTextFile( EditGridFile.text, self, Initiated );
            if Initiated then
              Writetologfile( 'Triwaco grid [' + EditGridFile.text + '] is initialised.' )
            else
              Raise Exception.Create( 'Triwaco grid [' + EditGridFile.text + '] is NOT initialised.' );

            Writeln( 'Initialising ESRI grid [' + EditClsNdsFltFileName.Text + '].' );
            SingleESRIgridclsndsflt := TSingleESRIgrid.InitialiseFromESRIGridFile( EditClsNdsFltFileName.Text, iResult, self );
            if ( iResult <> cNoError ) then
              Raise Exception.Create( 'Cannot initialise ClsNdsflt ESRI grid ' + EditClsNdsFltFileName.Text );
            Writetologfile( 'ClsNdsflt ESRI grid [' + EditClsNdsFltFileName.Text + '] is read.' );

            GHGmvESRIgrid := TSingleESRIgrid.InitialiseFromESRIGridFile( EditESRIgrid.Text, iResult, self );
            if ( iResult <> cNoError ) then
              Raise Exception.Create( 'GHGmvESRIgrid grid dataset is NOT initialised' );
            Writetologfile( 'GHGmvESRIgrid grid dataset is initialised' );

            GLGmvESRIgrid := TSingleESRIgrid.InitialiseFromESRIGridFile( EditESRIgrid.Text, iResult, self );
            if ( iResult <> cNoError ) then
              Raise Exception.Create( 'GLGmvESRIgrid grid dataset is NOT initialised' );
            Writetologfile( 'GLGmvESRIgrid grid dataset is initialised' );

            GVGmvESRIgrid := TSingleESRIgrid.InitialiseFromESRIGridFile( EditESRIgrid.Text, iResult, self );
            if ( iResult <> cNoError ) then
              Raise Exception.Create( 'GVGmvESRIgrid grid dataset is NOT initialised' );
            Writetologfile( 'GVGmvESRIgrid grid dataset is initialised' );

            GtESRIgrid := TSingleESRIgrid.InitialiseFromESRIGridFile( EditESRIgrid.Text, iResult, self );
            if ( iResult <> cNoError ) then
              Raise Exception.Create( 'GtESRIgrid grid dataset is NOT initialised' );
            Writetologfile( 'GtESRIgrid grid dataset is initialised' );

            iCellCount := 0;
            with SingleESRImvGrid, aTriwacoGrid do begin
              MaxNod1 := GHGSumSet.NrOfElements;
              for i:=1 to NRows do begin
                for j:=1 to NCols do begin
                  GHGmvESRIgrid[ i, j ] := MissingSingle;
                  GLGmvESRIgrid[ i, j ] := MissingSingle;
                  GVGmvESRIgrid[ i, j ] := MissingSingle;
                  Mv := GetValue( i, j );
                  if ( Mv <> MissingSingle ) then begin
                    GetCellCentre( i, j, x, y );
                    aValue := SingleESRIgridclsndsflt.GetValueXY( x, y );
                    if ( aValue <> MissingSingle ) then begin
                      Inc( iCellCount );
                      nod1 := Trunc( aValue );
                      {GetClosest3Nodes( x, y, nod1, nod2, nod3, dist1, dist2, dist3 );
                      Get3WeightsForIDWInterpolation( dist1, dist2, dist3, w1, w2, w3 );
                      aValue := w1 * GHGSumSet[ nod1 ] + w2 * GHGSumSet[ nod2 ] + w3 * GHGSumSet[ nod3 ];}
                      if ( ( nod1 < 1 ) or ( nod1 > MaxNod1 ) ) then
                        Raise Exception.Create( 'Invalid nodenr ' + IntToStr( nod1 ) + '. SingleESRIgridclsndsflt not valid.' );
                      GHGmvESRIgrid[ i, j ] := Mv - GHGSumSet[ nod1 ];
                      GLGmvESRIgrid[ i, j ] := Mv - GLGSumSet[ nod1 ];
                      GVGmvESRIgrid[ i, j ] := Mv - GVGSet[ nod1 ];
                      GtESRIgrid[ i, j ]    := GetGt( GHGmvESRIgrid[ i, j ], GLGmvESRIgrid[ i, j ] );
                    end; {-if}
                  end; {-if}
                end; {-for j}
              end; {-for i}
            end; {-with}
            Writetologfile( 'Nr of GxG cells found: ' + inttostr( iCellCount  ) );
            PlaatjesDirStr := ExtractFileDir( FileName ) + '\Plaatjes';
            if ( not SysUtils.DirectoryExists( PlaatjesDirStr ) ) then begin
              {$I-}
              MkDir(  PlaatjesDirStr );
              if ( IOResult <> 0 ) then
                Raise Exception.Create( 'Could not create dir [' + PlaatjesDirStr + '].' );
              {$I+}
            end;
            GHGmvESRIgrid.SaveAs( PlaatjesDirStr + '\GHGMV' );
            GLGmvESRIgrid.SaveAs( PlaatjesDirStr + '\GLGMV' );
            GVGmvESRIgrid.SaveAs( PlaatjesDirStr + '\GVGMV' );
            GtESRIgrid.SaveAs(    PlaatjesDirStr + '\Gt' );

            Writetologfile( 'ESRI GxG grids are created in folder [' + PlaatjesDirStr + ']' );
            MessageDlg( 'ESRI GxG grids are created in folder [' + PlaatjesDirStr + ']', mtInformation, [mbOk], 0);

            {-Probeer op peilbuislokaties de berekende GxG's en Gt's weg te schrijven naar tekstfile}
            PeilbuisFileNamStr := ExtractFileDir( EditGridFile.text ) + '\Peilbuislokaties.ung' ;
            if not fileExists( PeilbuisFileNamStr ) then
              Raise Exception.Create( 'File met peilbuislokaties [' +  PeilbuisFileNamStr + '] does not exist.' );
            Peilbuislokaties := TDbleMtrxUngPar.InitialiseFromTextFile( PeilbuisFileNamStr, self );

            GxGCalcFileNameStr := ExtractFileDir( FileName ) + '\GxGCalc_' + JustName( ExtractFileDir( FileName ) ) + '.txt';

            AssignFile( h, GxGCalcFileNameStr ); Rewrite( h );
            Writeln( h, '"ID","PbName","X","Y","GHGmvcalc","GLGmvcalc","GVGmvcalc","Gtcalc"' ); {-Header}
            with Peilbuislokaties, SingleESRImvGrid, aTriwacoGrid do begin
              for i:=1 to GetNRows do begin
                x := Getx( i ); y := Gety( i ); {-x, y van peilbuislokatie}
                Write( h, GetID( i ), ',"' + GetUngParName( i ) + '",',x:8:1,',',y:8:1,',' );
                GHGmv := -9999; GLGmv := -9999; GVGmv := -9999; Gt := -9999;
                MaxCellDepth := Trunc( cMaxDistForMvInterpolation / CellSize ); {-Zoek mv hoogte op maximaal 100 m afstand}
                GetValueNearXY( x, y, MaxCellDepth, CellDepth, Mv );
                if ( Mv <> MissingSingle ) then begin  {-Maaiveldshoogte gevonden}
                  GetClosest3Nodes( x, y, nod1, nod2, nod3, dist1, dist2, dist3 );
                  if ( dist1 < cMaxDistForGwLevelInterpolation ) then begin
                    Get3WeightsForIDWInterpolation( dist1, dist2, dist3, w1, w2, w3 );
                    GHGmv := Mv - ( w1 * GHGSumSet[ nod1 ] + w2 * GHGSumSet[ nod2 ] + w3 * GHGSumSet[ nod3 ] );
                    GLGmv := Mv - ( w1 * GLGSumSet[ nod1 ] + w2 * GLGSumSet[ nod2 ] + w3 * GLGSumSet[ nod3 ] );
                    GVGmv := Mv - ( w1 * GVGSet[ nod1 ] + w2 * GVGSet[ nod2 ] + w3 * GVGSet[ nod3 ] );
                    Gt := GetGt( GHGmv, GLGmv );
                  end;
                end; {-if}
                Writeln( h, GHGmv:8:2,',',GLGmv:8:2,',',GVGmv:8:2,',',Gt:8:2 );
              end; {-for i}
            end;
            CloseFile( h );
            MessageDlg( 'GxG''s and Gt''s op peilbuislokaties weggeschreven in ['+GxGCalcFileNameStr+'].',mtInformation, [mbOk], 0);

          except
            On E: Exception do begin
              HandleError( E.Message, ( Mode = Interactive ) );
              {MessageBeep( MB_ICONASTERISK );}
            end;
          end;
        end;
      finally
        Screen.Cursor := Save_Cursor;
        EditAdoSetRead.Visible := false;
        LabelAdoSetRead.Visible := false;
      end;

      {CloseFile( lf );} CloseFile( f ); CloseFile( g );
{$ifdef test}
      CloseFile( h );
{$endif}

      if ( GLGCount > 0 ) then
        MsgDlgType := mtInformation
      else begin
        MsgDlgType := mtError;
        if ( Mode = Batch ) then MessageBeep( MB_ICONASTERISK );
      end;

      if ( Mode = Interactive ) then
        MessageDlg( 'Nr. of hydrological years evaluated: ' + IntToStr( GLGCount div 3 ), MsgDlgType, [mbOk], 0);

    end; {-if Execute}
  end; {-With SaveDialog }
end;

procedure TOKBottomDlg1.EditESRIgridClick(Sender: TObject);
var
  Directory: string;
begin
  Directory := GetCurrentDir;
  if SelectDirectory( Directory,  [], 0 ) then begin
    EditESRIgrid.Text := ExpandFileName( Directory );
  end;
end;

procedure TOKBottomDlg1.EditGridFileClick(Sender: TObject);
begin
  with OpenGridFileDialog do begin
    If execute then begin
      EditGridFile.Text := ExpandFileName( FileName );
    end;
  end;
end;

procedure TOKBottomDlg1.FormCreate(Sender: TObject);
begin
  InitialiseLogFile;
  InitialiseGridIO;
end;

procedure TOKBottomDlg1.FormDestroy(Sender: TObject);
begin
FinaliseLogFile;
end;

procedure TOKBottomDlg1.EditClsNdsFltFileNameClick(Sender: TObject);
var
  Directory: string;
begin
  Directory := GetCurrentDir;
  if SelectDirectory( Directory,  [], 0 ) then begin
    EditClsNdsFltFileName.Text := ExpandFileName( Directory );
  end;
end;

initialization
finalization
end.
