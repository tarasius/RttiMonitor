unit uGlobal;

interface

type
  TPoint = record
    X, Y: Integer;
  end;
  TArr = array[-19..-10] of TPoint;

  {$M+}  {$RTTI EXPLICIT FIELDS ([vcPublic]) PROPERTIES ([vcPublic])}
  TGlobal = class
  public
    int1, int2: integer;
    str1, str2: string;
    flt1, flt2: Single;
    rec1, rec2: TPoint;
    arr1, arr2: TArr;
    function ToStr: string;
  end;
  {$M-}

  procedure InitGlobal;

var g: TGlobal;

implementation

procedure InitGlobal;
var i: integer;
begin
  g:= TGlobal.create;
  g.int1:=1;
  g.int2:=2;
  g.str1:='abc';
  g.str2:='def';
  g.flt1:=3.4;
  g.flt2:=5.6;
  g.rec1.x:=7;
  g.rec1.y:=8;
  g.rec2.x:=9;
  g.rec2.y:=10;

  for I := -19 to -10 do
  begin
    g.arr1[i].X:=119+i;
    g.arr1[i].y:=219+i;

    g.arr2[i].x:=319+i;
    g.arr2[i].y:=419+i;
  end;

end;

{ TGlobal }

function TGlobal.ToStr: string;
//var loc: TLocation;
//    ctx: TRttiContext;
//    LType: TRttiType;
//    f: TRttiField;
begin
//  ctx := TRttiContext.Create;
//  LType:= ctx.GetType(TGlobal);
//  for f in LType.GetFields do begin
//    (f.Name);
//  end;
end;

end.
