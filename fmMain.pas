unit fmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm4 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

uses rtti, uGlobal, uRTTIHelper;

{$R *.dfm}

procedure TForm4.Button1Click(Sender: TObject);
var loc: TLocation;
    ctx: TRttiContext;
    LType: TRttiType;
    f,f1: TRttiField;
    s,v: string;
    a:TRttiArrayType;
    i:integer;
begin
  InitGlobal;

  ctx := TRttiContext.Create;

  loc := TLocation.FromValue(ctx, g);

  LType:= ctx.GetType(TGlobal);
  for f in LType.GetFields do begin
    v:='.'+f.name;
    s:= f.Name+ ': '+f.FieldType.Name+' ';
    case f.FieldType.TypeKind of
     tkArray   : begin
       a:=TRttiArrayType(f.FieldType);
       s:=s+'('+a.ElementType.Name
         + '['+a.TotalElementCount.ToString+'])';
       memo1.lines.add(s);
       for I := 0 to a.TotalElementCount-1 do
       begin
         s:='  ['+i.ToString+']';
         v:='.'+f.name+'['+i.ToString+'].x';
         s:=s+loc.Follow(v).GetValue.ToString;
         memo1.lines.add(s);
       end;
     end;
     tkDynArray:
       begin
          s:=s+'('+TRttiDynamicArrayType(f.FieldType).ElementType.Name+')';
          memo1.lines.add(s);
       end;
     tkRecord:
       begin
         memo1.lines.add(s);
         for f1 in TRttiRecordType(f.FieldType).GetDeclaredFields do
         begin
           s:='  '+f1.name+' = ';
           v:='.'+f.name+'.'+f1.name;
           memo1.lines.add(s+loc.Follow(v).GetValue.ToString);
         end;
       end
     else
       begin
         v:=loc.Follow(v).GetValue.ToString;
         memo1.lines.add(s+' = ' + v);
       end;
    end;

  end;

end;

end.
