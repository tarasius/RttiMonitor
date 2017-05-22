unit uRTTIHelper;

interface

uses character, RTTI;

type
  TLocation = record
    Addr: Pointer;
    Typ: TRttiType;
    class function FromValue(C: TRttiContext; const AValue: TValue): TLocation; static;
    function GetValue: TValue;
    procedure SetValue(const AValue: TValue);
    function Follow(const APath: string): TLocation;
    procedure Dereference;
    procedure Index(n: Integer);
    procedure FieldRef(const name: string);
  end;

function GetPathLocation(const APath: string; ARoot: TLocation): TLocation; forward;

implementation

uses sysutils;

{ TLocation }

type
  PPByte = ^PByte;

procedure TLocation.Dereference;
begin
  if not (Typ is TRttiPointerType) then
    raise Exception.CreateFmt('^ applied to non-pointer type %s', [Typ.Name]);
  Addr := PPointer(Addr)^;
  Typ := TRttiPointerType(Typ).ReferredType;
end;

procedure TLocation.FieldRef(const name: string);
var
  f: TRttiField;
begin
  if Typ is TRttiRecordType then
  begin
    f := Typ.GetField(name);
    Addr := PByte(Addr) + f.Offset;
    Typ := f.FieldType;
  end
  else if Typ is TRttiInstanceType then
  begin
    f := Typ.GetField(name);
    Addr := PPByte(Addr)^ + f.Offset;
    Typ := f.FieldType;
  end
  else
    raise Exception.CreateFmt('. applied to type %s, which is not a record or class',
      [Typ.Name]);
end;

function TLocation.Follow(const APath: string): TLocation;
begin
  Result := GetPathLocation(APath, Self);
end;

class function TLocation.FromValue(C: TRttiContext; const AValue: TValue): TLocation;
begin
  Result.Typ := C.GetType(AValue.TypeInfo);
  Result.Addr := AValue.GetReferenceToRawData;
end;

function TLocation.GetValue: TValue;
begin
  TValue.Make(Addr, Typ.Handle, Result);
end;

procedure TLocation.Index(n: Integer);
var
  sa: TRttiArrayType;
  da: TRttiDynamicArrayType;
begin
  if Typ is TRttiArrayType then
  begin
    // extending this to work with multi-dimensional arrays and non-zero
    // based arrays is left as an exercise for the reader ... :)
    sa := TRttiArrayType(Typ);
    Addr := PByte(Addr) + sa.ElementType.TypeSize * n;
    Typ := sa.ElementType;
  end
  else if Typ is TRttiDynamicArrayType then
  begin
    da := TRttiDynamicArrayType(Typ);
    Addr := PPByte(Addr)^ + da.ElementType.TypeSize * n;
    Typ := da.ElementType;
  end
  else
    raise Exception.CreateFmt('[] applied to non-array type %s', [Typ.Name]);
end;

procedure TLocation.SetValue(const AValue: TValue);
begin
  AValue.Cast(Typ.Handle).ExtractRawData(Addr);
end;

function GetPathLocation(const APath: string; ARoot: TLocation): TLocation;

  { Lexer }

  function SkipWhite(p: PChar): PChar;
  begin
    while p^.IsWhiteSpace do
      Inc(p);
    Result := p;
  end;

  function ScanName(p: PChar; out s: string): PChar;
  begin
    Result := p;
    while Result^.IsLetterOrDigit do
      Inc(Result);
    SetString(s, p, Result - p);
  end;

  function ScanNumber(p: PChar; out n: Integer): PChar;
  var
    v: Integer;
  begin
    v := 0;
    while (p[0] >= '0') and (p[0] <= '9') do
    begin
      v := v * 10 + Ord(p^) - Ord('0');
      Inc(p);
    end;
    n := v;
    Result := p;
  end;

const
  tkEof = #0;
  tkNumber = #1;
  tkName = #2;
  tkDot = '.';
  tkLBracket = '[';
  tkRBracket = ']';

var
  cp: PChar;
  currToken: Char;
  nameToken: string;
  numToken: Integer;

  function NextToken: Char;
    function SetToken(p: PChar): PChar;
    begin
      currToken := p^;
      Result := p + 1;
    end;
  var
    p: PChar;
  begin
    p := cp;
    p := SkipWhite(p);
    if p^ = #0 then
    begin
      cp := p;
      currToken := tkEof;
      Exit(currToken);
    end;

    case p^ of
      '0'..'9':
      begin
        cp := ScanNumber(p, numToken);
        currToken := tkNumber;
      end;

      '^', '[', ']', '.': cp := SetToken(p);

    else
      cp := ScanName(p, nameToken);
      if nameToken = '' then
        raise Exception.Create('Invalid path - expected a name');
      currToken := tkName;
    end;

    Result := currToken;
  end;

  function Describe(tok: Char): string;
  begin
    case tok of
      tkEof: Result := 'end of string';
      tkNumber: Result := 'number';
      tkName: Result := 'name';
    else
      Result := '''' + tok + '''';
    end;
  end;

  procedure Expect(tok: Char);
  begin
    if tok <> currToken then
      raise Exception.CreateFmt('Expected %s but got %s',
        [Describe(tok), Describe(currToken)]);
  end;

  { Semantic actions are methods on TLocation }
var
  loc: TLocation;

  { Driver and parser }

begin
  cp := PChar(APath);
  NextToken;

  loc := ARoot;

  // Syntax:
  // path ::= ( '.' <name> | '[' <num> ']' | '^' )+ ;;

  // Semantics:

  // '<name>' are field names, '[]' is array indexing, '^' is pointer
  // indirection.

  // Parser continuously calculates the address of the value in question,
  // starting from the root.

  // When we see a name, we look that up as a field on the current type,
  // then add its offset to our current location if the current location is
  // a value type, or indirect (PPointer(x)^) the current location before
  // adding the offset if the current location is a reference type. If not
  // a record or class type, then it's an error.

  // When we see an indexing, we expect the current location to be an array
  // and we update the location to the address of the element inside the array.
  // All dimensions are flattened (multiplied out) and zero-based.

  // When we see indirection, we expect the current location to be a pointer,
  // and dereference it.

  while True do
  begin
    case currToken of
      tkEof: Break;

      '.':
      begin
        NextToken;
        Expect(tkName);
        loc.FieldRef(nameToken);
        NextToken;
      end;

      '[':
      begin
        NextToken;
        Expect(tkNumber);
        loc.Index(numToken);
        NextToken;
        Expect(']');
        NextToken;
      end;

      '^':
      begin
        loc.Dereference;
        NextToken;
      end;

    else
      raise Exception.Create('Invalid path syntax: expected ".", "[" or "^"');
    end;
  end;

  Result := loc;
end;

end.
