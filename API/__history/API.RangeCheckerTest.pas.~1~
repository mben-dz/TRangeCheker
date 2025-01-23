unit API.RangeCheckerTest;

interface
uses
  System.SysUtils,
  System.Rtti, System.TypInfo,
  System.Types,
  DateUtils,
//
  API.Objects.Comparer,
  System.RegularExpressions,
  System.Generics.Collections,
  System.Generics.Defaults;

type
  TRangeTester<T> = class
  strict private
    class var fVariableNames: TDictionary<Pointer, string>;
    class constructor Create;
    class destructor Destroy;
    class procedure GetVariableNames(const aValue, aMin, aMax: T;
                                     out aValueStr, aMiniStr, aMaxStr: string); inline;
  public
    class procedure RegisterVariable(var aVarPtr: T; const aName: string); static;

    class function Test(const aValue, aMin, aMax: T): string; overload; static;
    class function Test(const aValue, aMin, aMax: T; const aComparer: IComparer<T>): string; overload; static;
  end;

var
  gPoint1, gPoint2, gPoint3: TPoint;

  gRec1, gRec2, gRec3: ICustomRecord;
  gRecordComparer: IComparer<ICustomRecord>;

  gProduct1, gProduct2, gProduct3: IProduct;
  gProductComparer: IComparer<IProduct>;

  gClient1, gClient2, gClient3: IClient;
  gClientComparer: IComparer<IClient>;

implementation
uses
  API.Utils;


{ TRangTester }
class constructor TRangeTester<T>.Create;
begin
  fVariableNames := TDictionary<Pointer, string>.Create;
end;

class destructor TRangeTester<T>.Destroy;
begin
  fVariableNames.Free;
end;


class procedure TRangeTester<T>.RegisterVariable(var aVarPtr: T; const aName: string);
var
  LPointer: Pointer;
begin
  case GetTypeKind(T) of
    tkInterface:
      LPointer := Pointer(TValue.From<T>(aVarPtr).AsInterface);
    tkClass:
      LPointer := Pointer(TValue.From<T>(aVarPtr).AsObject);
  else
    LPointer := Pointer(@aVarPtr);
  end;

  if not fVariableNames.ContainsKey(LPointer) then
    fVariableNames.Add(LPointer, aName)
  else
    Writeln(Format('Warning: Variable "%s" is already registered.', [aName]));
end;

class procedure TRangeTester<T>.GetVariableNames(const aValue, aMin, aMax: T;
  out aValueStr, aMiniStr, aMaxStr: string);
var
  LValuePtr, LMinPtr, LMaxPtr: Pointer;
begin

  case GetTypeKind(T) of
    tkInterface:
    begin
      LValuePtr := Pointer(TValue.From<T>(aValue).AsInterface);
      LMinPtr   := Pointer(TValue.From<T>(aMin).AsInterface);
      LMaxPtr   := Pointer(TValue.From<T>(aMax).AsInterface);

      if not fVariableNames.TryGetValue(LValuePtr, aValueStr) then begin
        if Assigned(LValuePtr) then
          aValueStr := '<Interface>One' else
          aValueStr := '<Interface>One<IsNIL>';
      end;
      if not fVariableNames.TryGetValue(LMinPtr, aMiniStr) then begin
        if Assigned(LMinPtr) then
          aMiniStr := '<Interface>Two' else
          aMiniStr := '<Interface>Two<IsNIL>';
      end;

      if not fVariableNames.TryGetValue(LMaxPtr, aMaxStr) then begin
        if Assigned(LMaxPtr) then
          aMaxStr := '<Interface>Three' else
          aMaxStr := '<Interface>Three<IsNIL>';
      end;

    end;
    tkClass:
    begin
      LValuePtr := Pointer(TValue.From<T>(aValue).AsObject);
      LMinPtr   := Pointer(TValue.From<T>(aMin).AsObject);
      LMaxPtr   := Pointer(TValue.From<T>(aMax).AsObject);

      if not fVariableNames.TryGetValue(LValuePtr, aValueStr) then begin
        if Assigned(LValuePtr) then
          aValueStr := '<Class>One' else
          aValueStr := '<Class>One<IsNIL>';
      end;

      if not fVariableNames.TryGetValue(LMinPtr, aMiniStr) then begin
        if Assigned(LMinPtr) then
          aMiniStr := '<Class>Two' else
          aMiniStr := '<Class>Two<IsNIL>';
      end;

      if not fVariableNames.TryGetValue(LMaxPtr, aMaxStr) then begin
        if Assigned(LMaxPtr) then
          aMaxStr := '<Class>Three' else
          aMaxStr := '<Class>Three<IsNIL>';
      end;

    end;
    tkRecord:
    begin
      LValuePtr := Pointer(@aValue);
      LMinPtr   := Pointer(@aMin);
      LMaxPtr   := Pointer(@aMax);

      if not fVariableNames.TryGetValue(LValuePtr, aValueStr) then begin
        if Assigned(LValuePtr) then
          aValueStr := '<Record>One' else
          aValueStr := '<Record>One<IsNIL>';
      end;

      if not fVariableNames.TryGetValue(LMinPtr, aMiniStr) then begin
        if Assigned(LMinPtr) then
          aMiniStr := '<Record>Two' else
          aMiniStr := '<Record>Two<IsNIL>';
      end;

      if not fVariableNames.TryGetValue(LMaxPtr, aMaxStr) then begin
        if Assigned(LMaxPtr) then
          aMaxStr := '<Record>Three' else
          aMaxStr := '<Record>Three<IsNIL>';
      end;

    end;
  else
    begin
      // Default string conversion for simple types
      aValueStr := TValue.From<T>(aValue).ToString;
      aMiniStr   := TValue.From<T>(aMin).ToString;
      aMaxStr   := TValue.From<T>(aMax).ToString;
    end;
  end;

end;

class function TRangeTester<T>.Test(const aValue, aMin, aMax: T): string;
var
  LValueStr, LMiniStr, LMaxStr: string;
begin
  GetVariableNames(aValue, aMin, aMax, LValueStr, LMiniStr, LMaxStr);
  // Perform the range check
  try
    if TRange<T>.IsIn(aValue, aMin, aMax) then
      Result := Format('%s is within the range [%s, %s]', [LValueStr, LMiniStr, LMaxStr])
    else
      Result := Format('%s is outside the range [%s, %s]', [LValueStr, LMiniStr, LMaxStr]);
  except
    on E: Exception do begin
      Result := 'Error: ' + E.Message;
    end;
  end;
end;

class function TRangeTester<T>.Test(const aValue, aMin, aMax: T;
  const aComparer: IComparer<T>): string;
var
  LValueStr, LMiniStr, LMaxStr: string;
begin
  GetVariableNames(aValue, aMin, aMax, LValueStr, LMiniStr, LMaxStr);

  // Perform the range check
  try
    if TRange<T>.IsIn(aValue, aMin, aMax, aComparer) then
      Result := Format('%s is within the range [%s, %s]', [LValueStr, LMiniStr, LMaxStr])
    else
      Result := Format('%s is outside the range [%s, %s]', [LValueStr, LMiniStr, LMaxStr]);
  except
    on E: Exception do
      Result := 'Error: ' + E.Message;
  end;
end;

initialization
  gPoint1 := TPoint.Create(1, 2);
  gPoint2 := TPoint.Create(0, 0);
  gPoint3 := TPoint.Create(3, 4);

  gRec1 := GetTCustomRecord('Mid', 20);
  gRec2 := GetTCustomRecord('Low', 10);
  gRec3 := GetTCustomRecord('High', 30);
  gRecordComparer := TComparer<ICustomRecord>.Construct(CompareCustomRecord);

  gProduct1 := GetTProduct(1, 20.0);
  gProduct2 := GetTProduct(2, 10.0);
  gProduct3 := GetTProduct(3, 30.0);
  gProductComparer := TComparer<IProduct>.Construct(CompareProductByPrice);

  gClient1 := GetTClient('Alice', 30);
  gClient2 := GetTClient('Bob', 25);
  gClient3 := GetTClient('Charlie', 35);
  gClientComparer := TComparer<IClient>.Construct(CompareClientByAge);

  with FormatSettings do begin
    ShortDateFormat := 'DD MMMM YYYY';
    CurrencyString := 'DA';
    DecimalSeparator := ',';
    ThousandSeparator := '.';
  end;

  // Register variables
  TRangeTester<TPoint>.RegisterVariable(gPoint1, 'Point1');
  TRangeTester<TPoint>.RegisterVariable(gPoint2, 'Mini-Point2');
  TRangeTester<TPoint>.RegisterVariable(gPoint3, 'Max-Point3');

  TRangeTester<ICustomRecord>.RegisterVariable(gRec1, 'CustomRecord1');
  TRangeTester<ICustomRecord>.RegisterVariable(gRec2, 'Mini-CustomRecord2');
  TRangeTester<ICustomRecord>.RegisterVariable(gRec3, 'Max-CustomRecord3');

  TRangeTester<IProduct>.RegisterVariable(gProduct1, 'Product1');
  TRangeTester<IProduct>.RegisterVariable(gProduct2, 'Mini-Product2');
  TRangeTester<IProduct>.RegisterVariable(gProduct3, 'Max-Product3');

  TRangeTester<IClient>.RegisterVariable(gClient1, 'Client1');
  TRangeTester<IClient>.RegisterVariable(gClient2, 'Mini-Client2');
  TRangeTester<IClient>.RegisterVariable(gClient3, 'Max-Client3');

end.
