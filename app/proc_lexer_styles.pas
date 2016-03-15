(*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

Copyright (c) Alexey Torgashin
*)
unit proc_lexer_styles;

interface

uses
  SysUtils, Classes, Graphics, IniFiles,
  jsonConf,
  ecSyntAnal,
  ATStringProc;

procedure DoSaveLexerStyleToFile(st: TecSyntaxFormat; cfg: TJSONConfig; skey: string);
procedure DoSaveLexerStyleToFile(st: TecSyntaxFormat; ini: TIniFile; const section, skey: string);
procedure DoSaveLexerStylesToFile(an: TecSyntAnalyzer; const fn: string);

procedure DoLoadLexerStyleFromFile(st: TecSyntaxFormat; cfg: TJSONConfig; skey: string);
procedure DoLoadLexerStyleFromFile(st: TecSyntaxFormat; ini: TIniFile; const section, skey: string);
procedure DoLoadLexerStylesFromFile(an: TecSyntAnalyzer; const fn: string);


implementation

function FontStylesToString(const f: TFontStyles): string;
begin
  Result:= '';
  if fsBold in f then Result:= Result+'b';
  if fsItalic in f then Result:= Result+'i';
  if fsUnderline in f then Result:= Result+'u';
  if fsStrikeout in f then Result:= Result+'s';
end;

function StringToFontStyles(const s: string): TFontStyles;
var
  i: Integer;
begin
  Result:= [];
  for i:= 1 to Length(s) do
    case s[i] of
      'b': Include(Result, fsBold);
      'i': Include(Result, fsItalic);
      'u': Include(Result, fsUnderline);
      's': Include(Result, fsStrikeout);
    end;
end;


function FormatFlagsToStr(const f: TecFormatFlags): string;
begin
  Result:= '';
  if ffBold in f then Result:= Result+'b';
  if ffItalic in f then Result:= Result+'i';
  if ffUnderline in f then Result:= Result+'u';
  if ffStrikeOut in f then Result:= Result+'s';
  if ffReadOnly in f then Result:= Result+'r';
  if ffHidden in f then Result:= Result+'h';
  if ffFontName in f then Result:= Result+'N';
  if ffFontSize in f then Result:= Result+'S';
  if ffFontCharset in f then Result:= Result+'C';
  if ffVertAlign in f then Result:= Result+'v';
end;

function StrToFormatFlags(const s: string): TecFormatFlags;
var i:Integer;
begin
  Result:= [];
  for i:= 1 to Length(s) do
    case s[i] of
      'b': Include(Result, ffBold);
      'i': Include(Result, ffItalic);
      'u': Include(Result, ffUnderline);
      's': Include(Result, ffStrikeOut);
      'r': Include(Result, ffReadOnly);
      'h': Include(Result, ffHidden);
      'N': Include(Result, ffFontName);
      'S': Include(Result, ffFontSize);
      'C': Include(Result, ffFontCharset);
      'v': Include(Result, ffVertAlign);
    end;
end;


procedure DoSaveLexerStyleToFile(st: TecSyntaxFormat; cfg: TJSONConfig;
  skey: string);
begin
  if not SEndsWith(skey, '/') then skey:= skey+'/';

  cfg.SetValue(skey+'Name', st.DisplayName);
  cfg.SetValue(skey+'FontName', st.Font.Name);
  cfg.SetValue(skey+'FontSize', st.Font.Size);
  cfg.SetValue(skey+'FontColor', ColorToString(st.Font.Color));
  cfg.SetValue(skey+'FontStyles', FontStylesToString(st.Font.Style));
  cfg.SetValue(skey+'BgColor', ColorToString(st.BgColor));

  cfg.SetValue(skey+'BoColorB', ColorToString(st.BorderColorBottom));
  cfg.SetValue(skey+'BoColorL', ColorToString(st.BorderColorLeft));
  cfg.SetValue(skey+'BoColorR', ColorToString(st.BorderColorRight));
  cfg.SetValue(skey+'BoColorT', ColorToString(st.BorderColorTop));

  cfg.SetValue(skey+'BoTypeB', Integer(st.BorderTypeBottom));
  cfg.SetValue(skey+'BoTypeL', Integer(st.BorderTypeLeft));
  cfg.SetValue(skey+'BoTypeR', Integer(st.BorderTypeRight));
  cfg.SetValue(skey+'BoTypeT', Integer(st.BorderTypeTop));

  cfg.SetValue(skey+'FormatFlags', FormatFlagsToStr(st.FormatFlags));
  cfg.SetValue(skey+'FormatType', Integer(st.FormatType));
end;

procedure DoSaveLexerStyleToFile(st: TecSyntaxFormat; ini: TIniFile; const section, skey: string);
begin
  with st do
  begin
    ini.WriteString(section, skey+'_Name', '"'+DisplayName+'"');
    ini.WriteString(section, skey+'_FontName', Font.Name);
    ini.WriteInteger(section, skey+'_FontSize', Font.Size);
    ini.WriteString(section, skey+'_FontColor', ColorToString(Font.Color));
    ini.WriteString(section, skey+'_FontStyles', FontStylesToString(Font.Style));
    ini.WriteString(section, skey+'_BgColor', ColorToString(BgColor));

    ini.WriteString(section, skey+'_BorderColorBottom', ColorToString(BorderColorBottom));
    ini.WriteString(section, skey+'_BorderColorLeft', ColorToString(BorderColorLeft));
    ini.WriteString(section, skey+'_BorderColorRight', ColorToString(BorderColorRight));
    ini.WriteString(section, skey+'_BorderColorTop', ColorToString(BorderColorTop));

    ini.WriteInteger(section, skey+'_BorderTypeBottom', Integer(BorderTypeBottom));
    ini.WriteInteger(section, skey+'_BorderTypeLeft', Integer(BorderTypeLeft));
    ini.WriteInteger(section, skey+'_BorderTypeRight', Integer(BorderTypeRight));
    ini.WriteInteger(section, skey+'_BorderTypeTop', Integer(BorderTypeTop));

    ini.WriteString(section, skey+'_FormatFlags', FormatFlagsToStr(FormatFlags));
    ini.WriteInteger(section, skey+'_FormatType', Integer(FormatType));
  end;
end;

procedure DoSaveLexerStylesToFile(an: TecSyntAnalyzer; const fn: string);
var
  ini: TIniFile;
  section: string;
  i: integer;
begin
  section:= an.LexerName;
  if section='' then Exit;
  ini:= TIniFile.Create(fn);
  try
    ini.EraseSection(section);
    ini.WriteString(section, 'Ext', an.Extentions);
    ini.WriteInteger(section, 'Num', an.Formats.Count);
    for i:= 0 to an.Formats.Count-1 do
      DoSaveLexerStyleToFile(an.Formats[i], ini, section, IntToStr(i));
  finally
    ini.Free;
  end;
end;


procedure DoLoadLexerStyleFromFile(st: TecSyntaxFormat; cfg: TJSONConfig;
  skey: string);
begin
  if not SEndsWith(skey, '/') then skey:= skey+'/';

  st.DisplayName:= cfg.GetValue(skey+'Name', '');
  st.Font.Name:= cfg.GetValue(skey+'FontName', '');
  st.Font.Size:= cfg.GetValue(skey+'FontSize', 10);
  st.Font.Color:= StringToColor(cfg.GetValue(skey+'FontColor', ''));
  st.Font.Style:= StringToFontStyles(cfg.GetValue(skey+'FontStyles', ''));
  st.BgColor:= StringToColor(cfg.GetValue(skey+'BgColor', ''));

  st.BorderColorBottom:= StringToColor(cfg.GetValue(skey+'BoColorB', ''));
  st.BorderColorLeft:= StringToColor(cfg.GetValue(skey+'BoColorL', ''));
  st.BorderColorRight:= StringToColor(cfg.GetValue(skey+'BoColorR', ''));
  st.BorderColorTop:= StringToColor(cfg.GetValue(skey+'BoColorT', ''));

  st.BorderTypeBottom:= TecBorderLineType(cfg.GetValue(skey+'BoTypeB', 0));
  st.BorderTypeLeft:= TecBorderLineType(cfg.GetValue(skey+'BoTypeL', 0));
  st.BorderTypeRight:= TecBorderLineType(cfg.GetValue(skey+'BoTypeR', 0));
  st.BorderTypeTop:= TecBorderLineType(cfg.GetValue(skey+'BoTypeT', 0));

  st.FormatFlags:= StrToFormatFlags(cfg.GetValue(skey+'FormatFlags', ''));
  st.FormatType:= TecFormatType(cfg.GetValue(skey+'FormatType', 0));
end;


procedure DoLoadLexerStyleFromFile(st: TecSyntaxFormat; ini: TIniFile; const section, skey: string);
begin
  st.DisplayName:= ini.ReadString(section, skey+'_Name', '');
  st.Font.Name:= ini.ReadString(section, skey+'_FontName', '');
  st.Font.Size:= ini.ReadInteger(section, skey+'_FontSize', 10);
  st.Font.Color:= StringToColor(ini.ReadString(section, skey+'_FontColor', ''));
  st.Font.Style:= StringToFontStyles(ini.ReadString(section, skey+'_FontStyles', ''));
  st.BgColor:= StringToColor(ini.ReadString(section, skey+'_BgColor', ''));

  st.BorderColorBottom:= StringToColor(ini.ReadString(section, skey+'_BorderColorBottom', ''));
  st.BorderColorLeft:= StringToColor(ini.ReadString(section, skey+'_BorderColorLeft', ''));
  st.BorderColorRight:= StringToColor(ini.ReadString(section, skey+'_BorderColorRight', ''));
  st.BorderColorTop:= StringToColor(ini.ReadString(section, skey+'_BorderColorTop', ''));

  st.BorderTypeBottom:= TecBorderLineType(ini.ReadInteger(section, skey+'_BorderTypeBottom', 0));
  st.BorderTypeLeft:= TecBorderLineType(ini.ReadInteger(section, skey+'_BorderTypeLeft', 0));
  st.BorderTypeRight:= TecBorderLineType(ini.ReadInteger(section, skey+'_BorderTypeRight', 0));
  st.BorderTypeTop:= TecBorderLineType(ini.ReadInteger(section, skey+'_BorderTypeTop', 0));

  st.FormatFlags:= StrToFormatFlags(ini.ReadString(section, skey+'_FormatFlags', ''));
  st.FormatType:= TecFormatType(ini.ReadInteger(section, skey+'_FormatType', 0));
end;


procedure DoLoadLexerStylesFromFile(an: TecSyntAnalyzer; const fn: string);
var
  ini: TIniFile;
  i, j:Integer;
  section: string;
  fm: TecSyntaxFormat;
begin
  if an=nil then Exit;
  section:= an.LexerName;
  fm:= TecSyntaxFormat.Create(nil);
  ini:= TIniFile.Create(fn);
  try
    an.Extentions:= ini.ReadString(section, 'Ext', an.Extentions);
    for i:= 0 to ini.ReadInteger(section, 'Num', 0)-1 do
    begin
      DoLoadLexerStyleFromFile(fm, ini, section, IntToStr(i));
      //Apply fm to matched style
      for j:= 0 to an.Formats.Count-1 do
        if an.Formats[j].DisplayName = fm.DisplayName then
        begin
          an.Formats[j].Assign(fm);
          Break
        end;
    end;
  finally
    ini.Free;
    fm.Free;
  end;
end;


end.
