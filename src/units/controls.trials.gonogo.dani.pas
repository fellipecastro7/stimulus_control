{
  Stimulus Control
  Copyright (C) 2014-2017 Carlos Rafael Fernandes Picanço, Universidade Federal do Pará.

  The present file is distributed under the terms of the GNU General Public License (GPL v3.0).

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>.
}
unit Controls.Trials.GoNoGo.Dani;

{$mode objfpc}{$H+}

interface

uses LCLIntf, Controls, Classes, SysUtils, LazFileUtils

  , Controls.Trials.Abstract
  , Controls.Trials.Helpers
  , Controls.Stimuli.Text
  , Controls.GoLeftGoRight
  , Stimuli.Image
  , Schedules
  {$IFDEF AUDIO}, Audio.Bass_nonfree {$ENDIF}
  ;

type

  TButtonSide = (ssNone, ssLeft, ssRight);

  { TGNG }

  TGNG = Class(TTrial)
  private
    FGoResponseFired : TButtonSide;
    FDataSupport : TDataSupport;
    FSample : TLabelStimulus;
    FComparison : TLabelStimulus;
    FOperandum : TGoLeftGoRight;

    {$IFDEF AUDIO}FSound : TBassStream;{$ENDIF}
    FSchedule : TSchedule;
    FButtonSide : TButtonSide;
    procedure ButtonLeftClick(Sender: TObject);
    procedure ButtonRightClick(Sender: TObject);
    procedure TrialPaint;
    procedure Consequence(Sender: TObject);
    procedure Response(Sender: TObject);
    procedure TrialBeforeEnd(Sender: TObject);
    procedure TrialStart(Sender: TObject);
    procedure TrialResult(Sender: TObject);
    procedure TrialKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  protected
    { TTrial }
    procedure WriteData(Sender: TObject); override;
  public
    constructor Create(AOwner: TCustomControl); override;
    destructor Destroy; override;
    procedure Play(ACorrection : Boolean); override;
    function AsString : string; override;
    //procedure DispenserPlusCall; override;

  end;

implementation

uses StdCtrls, strutils, constants, Timestamps;

{ TGNG }

constructor TGNG.Create(AOwner: TCustomControl);
begin
  inherited Create(AOwner);
  OnTrialBeforeEnd := @TrialBeforeEnd;
  OnTrialKeyUp := @TrialKeyUp;
  OnTrialStart := @TrialStart;
  OnTrialPaint := @TrialPaint;
  FGoResponseFired := ssNone;
  Header :=  Header + #9 +
             rsReportStmBeg + #9 +
             rsReportRspLat + #9 +
             rsReportStmEnd + #9 +
             rsReportRspStl;

  FDataSupport.Responses:= 0;
end;

destructor TGNG.Destroy;
begin
  {$IFDEF AUDIO} if Assigned(FSound) then FSound.Free; {$ENDIF}
  inherited Destroy;
end;

procedure TGNG.TrialResult(Sender: TObject);
begin
  if Result = T_NONE then
    case FGoResponseFired of
      ssNone: Result := T_MISS;
      ssLeft, ssRight:
        if FGoResponseFired = FButtonSide then
          Result := T_HIT
        else
          Result := T_MISS;
    end;
end;

procedure TGNG.TrialBeforeEnd(Sender: TObject);
begin
  FDataSupport.StmEnd := TickCount;
  TrialResult(Sender);
  LogEvent(Result);
  WriteData(Sender);
end;

procedure TGNG.Consequence(Sender: TObject);
begin
  TrialResult(Sender);
  if Assigned(CounterManager.OnConsequence) then CounterManager.OnConsequence(Self);
end;

procedure TGNG.TrialKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  //if FGoResponseFired = ssNone then
  //begin
  //  case Key of
  //    67,  99 :
  //      begin
  //
  //      end;
  //
  //    77, 109 :
  //      begin
  //
  //      end;
  //  end;
  //end;
end;

procedure TGNG.TrialPaint;
var
  R : TRect;
begin
  if FSample.Visible then
    begin
      R := FSample.BoundsRect;
      if InflateRect(R,50,50) then
      case FButtonSide of
        ssLeft : Canvas.Pen.Width := 5;
        ssRight : Canvas.Pen.Width := 15;
      end;
      Canvas.Rectangle(R);
    end;
end;

procedure TGNG.ButtonLeftClick(Sender: TObject);
begin
  FGoResponseFired := ssLeft;
  LogEvent('Verdadeiro');
  if FButtonSide = ssLeft then
    FSchedule.DoResponse;
end;

procedure TGNG.ButtonRightClick(Sender: TObject);
begin
  FGoResponseFired := ssRight;
  LogEvent('Falso');
  if FButtonSide = ssRight then
    FSchedule.DoResponse;
end;

procedure TGNG.Play(ACorrection: Boolean);
var
  s1, LName : string;
  LConfiguration : TStringList;
begin
  inherited Play(ACorrection);
  LConfiguration := Configurations.SList;

  s1:= LConfiguration.Values[_Samp +_cStm] + #32;
  LName := RootMedia + ExtractDelimited(1,s1,[#32]);
  FSample := TLabelStimulus.Create(Self, Self.Parent);
  with FSample do
    begin
      LoadFromFile(LName);
      CentralizeLeft;
    end;

  s1:= LConfiguration.Values[_Comp + IntToStr(1) +_cStm] + #32;
  LName := RootMedia + ExtractDelimited(1,s1,[#32]);

  FComparison := TLabelStimulus.Create(Self, Self.Parent);
  with FComparison do
    begin
      LoadFromFile(LName);
      CentralizeMiddleRight;
    end;

  with TLabelStimulus.Create(Self, Self.Parent) do
  begin
    Caption := 'O computador disse:';
    Font.Bold := True;;
    CentralizeOnTopOfControl(FComparison);
  end;

  FOperandum := TGoLeftGoRight.Create(Self, FComparison);
  FOperandum.OnButtonRightClick:=@ButtonRightClick;
  FOperandum.OnButtonLeftClick:=@ButtonLeftClick;
  FOperandum.Parent := Self.Parent;
  FSchedule := TSchedule.Create(Self);
  with FSchedule do
    begin
      OnConsequence := @Consequence;
      OnResponse:= @Response;
      Load(CRF);
    end;

  case UpperCase(LConfiguration.Values[_ResponseStyle]) of
    'GO'   : FButtonSide := ssLeft;
    'NOGO' : FButtonSide := ssRight;
  end;

  if Self.ClassType = TGNG then Config(Self);
end;

function TGNG.AsString: string;
begin
  Result := '';
end;

procedure TGNG.TrialStart(Sender: TObject);
begin
  FSample.Show;
  FComparison.Show;
  FDataSupport.Latency := TimeStart;
  FDataSupport.StmBegin := TickCount;
  FSchedule.Start;
end;

procedure TGNG.WriteData(Sender: TObject);
var
  LLatency : string;
  LButtonSide : string;
begin
  inherited WriteData(Sender);

  if FDataSupport.Latency = TimeStart then
    LLatency := 'NA'
  else LLatency := TimestampToStr(FDataSupport.Latency - TimeStart);

  WriteStr(LButtonSide, FButtonSide);

  Data :=  Data +
           TimestampToStr(FDataSupport.StmBegin - TimeStart) + #9 +
           LLatency + #9 +
           TimestampToStr(FDataSupport.StmEnd - TimeStart) + #9 +
           LButtonSide;
end;

procedure TGNG.Response(Sender: TObject);
begin
  Inc(FDataSupport.Responses);
  if FDataSupport.Latency = TimeStart then
    FDataSupport.Latency := TickCount;

  if Assigned(CounterManager.OnStmResponse) then CounterManager.OnStmResponse(Sender);
  if Assigned(OnStmResponse) then OnStmResponse (Self);
end;

end.