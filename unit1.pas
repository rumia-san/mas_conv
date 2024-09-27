unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  LazUTF8;

type

  { TMainForm }

  TMainForm = class(TForm)
    HelpLabel: TLabel;
    StyleListBox: TListBox;
    InputMemo: TMemo;
    OutputMemo: TMemo;
    MemoPanel: TPanel;
    procedure StyleListBoxClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure InputMemoChange(Sender: TObject);
    procedure MemoPanelResize(Sender: TObject);
  private
    function Convert(c: cardinal): string;
    function IterateUTF8Codepoints(const AnUTF8String: string): string;
    procedure UpdateOutput();
    function GetUnicodeBaseForLetter(): cardinal;
    function GetUnicodeBaseForDigit(): cardinal;
  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }


function HandleLetterlikeSymbols(c: cardinal): cardinal;
begin
  case c of
    $1D455: Result := $210E;  // planck constant
    $1D49D: Result := $212C;  // script capital b
    $1D4A0: Result := $2130;  // script capital e
    $1D4A1: Result := $2131;  // script capital f
    $1D4A3: Result := $210B;  // script capital h
    $1D4A4: Result := $2110;  // script capital i
    $1D4A7: Result := $2112;  // script capital l
    $1D4A8: Result := $2133;  // script capital m
    $1D4AD: Result := $211B;  // script capital r
    $1D4BA: Result := $212F;  // script small e
    $1D4BC: Result := $210A;  // script small g
    $1D4C4: Result := $2134;  // script small o
    $1D506: Result := $212D;  // black-letter capital c
    $1D50B: Result := $210C;  // black-letter capital h
    $1D50C: Result := $2111;  // black-letter capital i
    $1D515: Result := $211C;  // black-letter capital r
    $1D51D: Result := $2128;  // black-letter capital z
    $1D53A: Result := $2102;  // double-struck capital c
    $1D53F: Result := $210D;  // double-struck capital h
    $1D545: Result := $2115;  // double-struck capital n
    $1D547: Result := $2119;  // double-struck capital p
    $1D548: Result := $211A;  // double-struck capital q
    $1D549: Result := $211D;  // double-struck capital r
    $1D551: Result := $2124;  // double-struck capital z
    else
      Result := 0;
  end;
end;

function TMainForm.GetUnicodeBaseForLetter(): cardinal;
begin
  // 检查是否有选中的项
  if StyleListBox.ItemIndex = -1 then
    Exit($1D400); // 返回默认值

  // 根据选中项返回对应的 Unicode 基础值
  case StyleListBox.ItemIndex of
    0: Result := $1D400;         // Bold
    1: Result := $1D434;         // Italic
    2: Result := $1D468;         // Bold-Italic
    3: Result := $1D49C;         // Script
    4: Result := $1D4D0;         // Bold-Script
    5: Result := $1D504;         // Fraktur
    6: Result := $1D538;         // Double-Struck
    7: Result := $1D56C;         // Bold-Fraktur
    8: Result := $1D5A0;         // Sans-Serif
    9: Result := $1D5D4;         // Sans-Serif-Bold
    10: Result := $1D608;        // Sans-Serif-Italic
    11: Result := $1D63C;        // Sans-Serif-Bold-Italic
    12: Result := $1D670;        // Monospace
    else
      Result := 0; // 如果选项超出范围
  end;
end;

function TMainForm.GetUnicodeBaseForDigit(): cardinal;
begin
  if StyleListBox.ItemIndex = -1 then
  begin
    Exit($1D7CE);
  end;

  // 根据选中项返回对应的 Unicode 基础值
  case StyleListBox.ItemIndex of
    0: Result := $1D7CE;  // Bold digits
    1: Result := 0;       // Italic (无法转换)
    2: Result := 0;       // Bold-Italic (无法转换)
    3: Result := 0;       // Script (无法转换)
    4: Result := 0;       // Bold-Script (无法转换)
    5: Result := 0;       // Fraktur (无法转换)
    6: Result := $1D7D8;  // Double-Struck digits
    7: Result := 0;       // Bold-Fraktur (无法转换)
    8: Result := $1D7E2;  // Sans-Serif
    9: Result := $1D7EC;  // Sans-Serif Bold digits
    10: Result := 0;      // Sans-Serif Italic digits (无法转换)
    11: Result := 0;      // Sans-Serif Bold Italic (无法转换)
    12: Result := $1D7F6; // Monospace digits
    else
      Result := 0; // 如果选项超出范围或没有有效转换
  end;
end;

function TMainForm.Convert(c: cardinal): string;
var
  Offset: cardinal;
  Base: cardinal;
  Code: cardinal;
  Letterlike: cardinal;
begin
  if (c >= Ord('A')) and (c <= Ord('Z')) then
  begin
    Base := GetUnicodeBaseForLetter();
    Offset := Ord(c) - Ord('A');
  end
  else if (c >= Ord('a')) and (c <= Ord('z')) then
  begin
    Base := GetUnicodeBaseForLetter() + 26;
    Offset := Ord(c) - Ord('a');
  end
  else if (c >= Ord('0')) and (c <= Ord('9')) then
  begin
    Base := GetUnicodeBaseForDigit();
    if Base = 0 then
      Exit(UnicodeToUTF8(c));
    Offset := Ord(c) - Ord('0');
  end
  else
  begin
    Exit(UnicodeToUTF8(c));
  end;

  Code := Base + Offset;
  Letterlike := HandleLetterlikeSymbols(Code);
  if Letterlike <> 0 then
  begin
    Code := Letterlike;
  end;
  Result := UnicodeToUTF8(Code);
end;

function TMainForm.IterateUTF8Codepoints(const AnUTF8String: string): string;
var
  p: PChar;
  unicode: cardinal;
  CPLen: integer;
begin
  Result := '';
  p := PChar(AnUTF8String);
  repeat
    unicode := UTF8CodepointToUnicode(p, CPLen);
    Result := Result + Convert(unicode);
    Inc(p, CPLen);
  until (CPLen = 0) or (unicode = 0);
end;

procedure TMainForm.InputMemoChange(Sender: TObject);
begin
  UpdateOutput();
end;

procedure TMainForm.MemoPanelResize(Sender: TObject);
begin
  InputMemo.Height := MemoPanel.ClientHeight div 2;
end;

procedure TMainForm.StyleListBoxClick(Sender: TObject);
begin
  UpdateOutput();
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  UpdateOutput();
end;

procedure TMainForm.UpdateOutput();
var
  inputText: string;
  outputText: string;
begin
  inputText := InputMemo.Lines.Text;
  outputText := IterateUTF8Codepoints(inputText);
  OutputMemo.Lines.Text := outputText;
end;

end.
