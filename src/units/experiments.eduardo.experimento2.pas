{
  Stimulus Control
  Copyright (C) 2014-2021 Carlos Rafael Fernandes Picanço, Universidade Federal do Pará.

  The present file is distributed under the terms of the GNU General Public License (GPL v3.0).

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>.
}
unit Experiments.Eduardo.Experimento2;

{$mode objfpc}{$H+}

interface

procedure WriteToConfigurationFile(ADesign : string);

implementation

uses Classes, SysUtils
   , Constants
   , LazFileUtils
   , StrUtils
   , Experiments.Eduardo.Comum
   , Session.Configuration.GlobalContainer
   , Session.ConfigurationFile
   , Cheats
   ;

procedure WriteTemporalBissection(ABlc : integer; AName: string;
  ASampleTime: string; AConsequence : string);
var
  i : integer;
  LConsequenceL : Boolean;
  LConsequenceR : Boolean;

  function HasConsequence(AProbability : Extended) : Boolean;
  var
    R : Extended;
  begin
    R := Random;
    if R < AProbability then
      Result := True
    else
      Result := False;
  end;

begin
  i := ConfigurationFile.TrialCount[ABlc]+1;
  with ConfigurationFile do
  begin
    WriteToTrial(i, ABlc, _Name, AName + #32 + ASampleTime + #32 + AConsequence);
    WriteToTrial(i, ABlc, _Cursor, '-1');
    WriteToTrial(i, ABlc, _Kind, T_TMB);
    WriteToTrial(i, ABlc, _ITI, ITI.ToString);
    WriteToTrial(i, ABlc, _ExpectedResponse, ASampleTime);

    LConsequenceL := HasConsequence(StrToFloat(ExtractDelimited(1, AConsequence,[#32])));
    LConsequenceR := HasConsequence(StrToFloat(ExtractDelimited(2, AConsequence,[#32])));
    WriteToTrial(i, ABlc, _Consequence, LConsequenceL.ToString + #32 + LConsequenceR.ToString);
  end;
end;

// 10, 50% left, 50% right, 100% de reforço
procedure WriteTraining1(ABlc : integer);
var
  i, r : integer;
  LStringList : TStringList;
begin
  LStringList := TStringList.Create;
  try
    LStringList.Clear;

    for i := 0 to 4 do
    begin
      LStringList.Append('Left');
      LStringList.Append('Right');
    end;

    for i := 0 to 9 do
    begin
      r := Random(10);
      LStringlist.Exchange(i, r);
    end;

    for i := 0 to 9 do
      WriteTemporalBissection(ABlc, 'Temporal Bissection '+(i+1).ToString,
        LStringlist[i], '100.0 100.0');

  finally
    LStringList.Free;
  end;
end;

// 10, 50% left, 50% right
procedure WriteTraining2(ABlc : integer; AConsequence : string);
var
  i, r : integer;
  LStringList : TStringList;
begin
  LStringList := TStringList.Create;
  try
    LStringList.Clear;
    for i := 0 to 4 do
    begin
      LStringList.Append('Left');
      LStringList.Append('Right');
    end;

    for i := 0 to 9 do
    begin
      r := Random(10);
      LStringlist.Exchange(i, r);
    end;

    for i := 0 to 9 do
      WriteTemporalBissection(ABlc, 'Temporal Bissection '+(i+1).ToString,
        LStringlist[i], AConsequence);
  finally
    LStringList.Free;
  end;
end;

// teste 10 blocos de 6 (2 treino, 4 de teste), total 20 treino, 40 teste
procedure WriteTrainingTest(ABlc : integer; AConsequence : string);
var
  j, i, r, LTrainingI, LTestingI : integer;
  LConsequence : string;
  LTraining : TStringList;
  LTesting  : TStringList;
  LStringList     : TStringList;
begin
  LStringList     := TStringList.Create;
  LTraining := TStringList.Create;
  LTesting  := TStringList.Create;
  try
    LTesting.Clear;
    LTraining.Clear;
    LStringList.Clear;

    LStringList.Append('3170');
    LStringList.Append('2520');
    LStringList.Append('2000');
    LStringList.Append('1590');
    LStringList.Append('1260');

    for i := 0 to 9 do
    begin
      LTraining.Append('Left');
      LTraining.Append('Right');
    end;

    for i := 0 to 19 do
    begin
      r := Random(20);
      LTraining.Exchange(i, r);
    end;

    for i := 0 to 7 do
    begin
      for j := 0 to 4 do
      begin
        r := Random(5);
        LStringList.Exchange(j, r);
      end;

      for j := 0 to 4 do
        LTesting.Append(LStringList[j]);
    end;

    LTrainingI := 0;
    LTestingI := 0;
    j := 0;
    repeat
      LStringlist.Clear;
      for i := 0 to 5 do
      begin
        case i of
          0, 1 :
            begin
              LStringlist.Append(LTraining[LTrainingI]);
              Inc(LTrainingI);
            end;
          else
            begin
              LStringlist.Append(LTesting[LTestingI]);
              Inc(LTestingI);
            end;
          end;
      end;

      for i := 0 to 5 do
      begin
        r := Random(6);
        LStringList.Exchange(i, r);
      end;

      for i := 0 to LStringList.Count -1 do
      begin
        case LStringList[i] of
          'Left', 'Right' : LConsequence := AConsequence;
          '3170', '2520', '2000', '1590', '1260': LConsequence := '0.0 0.0';
        end;
        Inc(j);
        WriteTemporalBissection(ABlc, 'Temporal Bissection Test '+(j).ToString + #32 + LStringList[i],
          LStringList[i], LConsequence);
      end;
    until (LTrainingI = 20) and (LTestingI = 40);
  finally
    LStringList.Free;
    LTraining.Free;
    LTesting.Free;
  end;
end;

procedure WriteToConfigurationFile(ADesign : string);
var
  LCondition : char;
  LConditionI : integer = 0;
  LNextBlocOnCriteria : string;

  procedure SetITIForBCD;
  begin
    if CheatsModeOn then begin
      ITI := TemporalBissectionITI div 10;
    end else begin
      ITI := TemporalBissectionITI;
    end;
  end;

  procedure WriteBCondition;
  var
    i : integer;
  begin
    SetITIForBCD;
    Inc(LConditionI);
    ConfigurationFile.WriteToBloc(LConditionI, _Name, 'Mensagem B');
    WriteMSG(LConditionI, 'M1', MessageE2B);

    // 10 no mínimo, sem critério
    Inc(LConditionI);
    ConfigurationFile.WriteToBloc(LConditionI, _Name, 'B1-100% reforço');
    WriteTraining1(LConditionI);

    // 60 no mínimo
    for i := 0 to 5 do
    begin
      Inc(LConditionI);
      ConfigurationFile.WriteToBloc(LConditionI, _Name, 'B2-MIN 60-50% reforço');
      WriteTraining2(LConditionI, '0.5 0.5');
    end;

    // 100 no máximo, critério de 90% de acerto
    for i := 0 to 3 do
    begin
      Inc(LConditionI);
      ConfigurationFile.WriteToBloc(LConditionI, _Name, 'B2-MAX 100-50% reforço-90% de acerto');
      ConfigurationFile.WriteToBloc(LConditionI, _CrtHitPorcentage, '90');
      ConfigurationFile.WriteToBloc(LConditionI, _NextBlocOnCriteria, LNextBlocOnCriteria);
      WriteTraining2(LConditionI, '0.5 0.5');
    end;

    // testing
    Inc(LConditionI);
    ConfigurationFile.WriteToBloc(LConditionI, _Name, 'B test');
    WriteTrainingTest(LConditionI, '0.5 0.5');
  end;


  procedure WriteCCondition;
  var
    i : integer;
  begin
    SetITIForBCD;
    Inc(LConditionI);
    ConfigurationFile.WriteToBloc(LConditionI, _Name, 'Mensagem C');
    WriteMSG(LConditionI, 'M1', MessageE2B);

    // 60 no mínimo
    for i := 0 to 5 do
    begin
      Inc(LConditionI);
      ConfigurationFile.WriteToBloc(LConditionI, _Name, 'C1-MIN 60-80%/20% reforço');
      WriteTraining2(LConditionI, '0.8 0.2');
    end;

    // 100 no máximo, critério de 90% de acerto
    for i := 0 to 3 do
    begin
      Inc(LConditionI);
      ConfigurationFile.WriteToBloc(LConditionI, _Name, 'C1-MAX 100-80%/20% reforço-90% de acerto');
      ConfigurationFile.WriteToBloc(LConditionI, _CrtHitPorcentage, '90');
      ConfigurationFile.WriteToBloc(LConditionI, _NextBlocOnCriteria, LNextBlocOnCriteria);
      WriteTraining2(LConditionI, '0.8 0.2');
    end;

    // testing
    Inc(LConditionI);
    ConfigurationFile.WriteToBloc(LConditionI, _Name, 'C test');
    WriteTrainingTest(LConditionI, '0.8 0.2');
  end;

  procedure WriteDCondition;
  var
    i : integer;
  begin
    SetITIForBCD;
    Inc(LConditionI);
    ConfigurationFile.WriteToBloc(LConditionI, _Name, 'Mensagem D');
    WriteMSG(LConditionI, 'M1', MessageE2B);

    // 60 no mínimo
    for i := 0 to 5 do
    begin
      Inc(LConditionI);
      ConfigurationFile.WriteToBloc(LConditionI, _Name, 'D1-MIN 60-20%/80% reforço');
      WriteTraining2(LConditionI, '0.2 0.8');
    end;

    // 100 no máximo, critério de 90% de acerto
    for i := 0 to 3 do
    begin
      Inc(LConditionI);
      ConfigurationFile.WriteToBloc(LConditionI, _Name, 'D1-MAX 100-20%/80% reforço-90% de acerto');
      ConfigurationFile.WriteToBloc(LConditionI, _CrtHitPorcentage, '90');
      ConfigurationFile.WriteToBloc(LConditionI, _NextBlocOnCriteria, LNextBlocOnCriteria);
      WriteTraining2(LConditionI, '0.2 0.8');
    end;

    // testing
    Inc(LConditionI);
    ConfigurationFile.WriteToBloc(LConditionI, _Name, 'D test');
    WriteTrainingTest(LConditionI, '0.2 0.8');
  end;

begin
  SetupStimuli;
  if (ADesign = 'ABA') then
  begin
    Inc(LConditionI);
    ConfigurationFile.WriteToBloc(LConditionI, _Name, 'Mensagem A0');
    WriteMSG(LConditionI, 'M0', MessageA0);
    LNextBlocOnCriteria := '13';
  end else begin
    LNextBlocOnCriteria := '12';
  end;

  for LCondition in ADesign do
  case LCondition of
    'A': WriteACondition(LConditionI);
    'B': WriteBCondition;
    'C': WriteCCondition;
    'D': WriteDCondition;
  end;
end;

end.
