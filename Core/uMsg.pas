unit uMsg;

interface

uses
  SysUtils,

  uTypes,
  uOutputInfo;

procedure ShowMessage(const MessageLevel: TMessageLevel; const ExpandedText: string); overload;

procedure ShowMessage(const MessageLevel: TMessageLevel; const Text: string; const Param: array of string); overload;

procedure Debug(const Text: string); overload;

procedure Debug(const Text: string; const Param: array of string); overload;

procedure IE(const Text: string); // Internal Error

procedure Information(const Text: string); overload;

procedure Information(const Text: string; const Param: array of string); overload;

procedure Warning(const Text: string); overload;

procedure Warning(const Text: string; const Param: array of string); overload;

procedure ErrorMsg(const Text: string); overload;

procedure ErrorMsg(const Text: string; const Param: array of string); overload;

{$ifdef MSWINDOWS}
procedure ErrorMsg(const ErrorCode: SG); overload;
{$endif}

procedure Fatal(const AException: Exception; const C: TObject = nil);

function Confirmation(const Text: string; const Buttons: TDlgButtons): TDlgBtn; overload;

function Confirmation(const Text: string; const Buttons: TDlgButtons; const Param: array of string): TDlgBtn; overload;

{$ifdef MSWINDOWS}
procedure IOError(const FileName: TFileName; const ErrorCode: U4);
{$endif}

procedure IOErrorMessage(const FileName: TFileName; const ErrorMsg: string);

implementation

uses
{$ifdef MSWINDOWS}
  uErrorCodeToStr,
{$endif}

  uStrings,
  uMainLog,
  uCommonOutput,
  uChar;

procedure ShowMessage(const MessageLevel: TMessageLevel; const ExpandedText: string); overload;
begin
  if MainLog.IsLoggerFor(MessageLevel) then
    MainLog.Add(ExpandedText, MessageLevel);

  if Assigned(CommonOutput) then
    CommonOutput.AddMessage(ExpandedText, MessageLevel);
end;

procedure ShowMessage(const MessageLevel: TMessageLevel; const Text: string; const Param: array of string); overload;
var
  ExpandedText: string;
begin
  ExpandedText := ReplaceParam(Text, Param);
  if MainLog.IsLoggerFor(MessageLevel) then
    MainLog.Add(ExpandedText, MessageLevel);

  if Assigned(CommonOutput) then
    CommonOutput.AddMessage(ExpandedText, MessageLevel);
end;

procedure Debug(const Text: string);
begin
  if IsDebug then
    ShowMessage(mlDebug, Text, []);
end;

procedure Debug(const Text: string; const Param: array of string);
begin
  if IsDebug then
    ShowMessage(mlDebug, Text, Param);
end;

procedure IE(const Text: string);
begin
  if IsDebug then
    ShowMessage(mlFatalError, 'Internal' + CharSpace + CharEnDash + CharSpace + Text);
end;

procedure Information(const Text: string); overload;
begin
  ShowMessage(mlInformation, Text, []);
end;

procedure Information(const Text: string; const Param: array of string); overload;
begin
  ShowMessage(mlInformation, Text, Param);
end;

procedure Warning(const Text: string);
begin
  ShowMessage(mlWarning, Text, []);
end;

procedure Warning(const Text: string; const Param: array of string);
begin
  ShowMessage(mlWarning, Text, Param);
end;

procedure ErrorMsg(const Text: string);
begin
  ShowMessage(mlError, Text, []);
end;

procedure ErrorMsg(const Text: string; const Param: array of string);
begin
  ShowMessage(mlError, Text, Param);
end;

{$IFDEF MSWINDOWS}
procedure ErrorMsg(const ErrorCode: SG);
begin
  if ErrorCode <> 0 then
    ErrorMsg(ErrorCodeToStr(ErrorCode));
end;
{$ENDIF}

procedure Fatal(const AException: Exception; const C: TObject = nil);
var
  ExpandedText: string;
  Ex: Exception;
begin
  if AException is EAbort then
    Exit; // EAbort is the exception class for errors that should not display an error message dialog box.

  ExpandedText := '';
  Ex := AException;
  repeat
    ExpandedText := ExpandedText + Ex.Message;
    if IsDebug then
      ExpandedText := ExpandedText + ' (' + Ex.ClassName + ')';
    ExpandedText := ExpandedText + LineSep;
    {$if CompilerVersion >= 20}
    Ex := Ex.InnerException;
    {$else}
    Ex := nil;
    {$ifend}
  until Ex = nil;

  if IsDebug and (C <> nil) then
  begin
    ExpandedText := ExpandedText + '(in class ' + C.ClassName + ')';
  end
  else
    ExpandedText := DelLastChar(ExpandedText);

  ShowMessage(mlFatalError, ExpandedText);
end;

function Confirmation(const Text: string; const Buttons: TDlgButtons): TDlgBtn;
begin
  if MainLog.IsLoggerFor(mlConfirmation) then
    MainLog.Add(Text, mlConfirmation);
  if Assigned(CommonOutput) then
    Result := CommonOutput.Confirmation(Text, Buttons)
  else
    Result := mbCancel;
end;

function Confirmation(const Text: string; const Buttons: TDlgButtons; const Param: array of string): TDlgBtn;
var
  ExpandedText: string;
begin
  ExpandedText := ReplaceParam(Text, Param);
  if MainLog.IsLoggerFor(mlConfirmation) then
    MainLog.Add(ExpandedText, mlConfirmation);
  if Assigned(CommonOutput) then
    Result := CommonOutput.Confirmation(ExpandedText, Buttons)
  else
    Result := mbCancel;
end;

{$ifdef MSWINDOWS}
procedure IOError(const FileName: TFileName; const ErrorCode: U4);
begin
  IOErrorMessage(FileName, ErrorCodeToStr(ErrorCode));
end;
{$endif}

procedure IOErrorMessage(const FileName: TFileName; const ErrorMsg: string);
const
  ErrorCodeStr = 'I/O: ';
var
  Text: string;
begin
  Text := ErrorMsg + ': ' + FileName;
  if MainLog.IsLoggerFor(mlError) then
    MainLog.Add(Text, mlError);

  if Assigned(CommonOutput) then
    CommonOutput.AddError(ErrorCodeStr + Text);
end;

end.

