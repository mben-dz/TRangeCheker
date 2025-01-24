# TRange<T> Checker:  

Delphi **TRange<T>** Checker (clean design, easy to extend comparers)  
 ----  
 ![TRangeOutput](https://github.com/user-attachments/assets/16133793-624c-410e-bec2-d3f388270bf7)
  ---  
# TRange<T> for Delphi

A simple, generic, and extensible range checker for Delphi, supporting numeric, date, and other types. This class allows you to check whether a given value lies within a specified range, with support for both inclusive and exclusive ranges.

## Features
- **Generic class** supporting multiple types (`Integer`, `Double`, `TDateTime`, etc.).
- Configurable for **inclusive** or **exclusive** ranges.
- Easy to extend for custom types or comparison logic.
- Clean and readable API.

## Installation
Clone or download the `API.Utils.pas` file and add it to your Delphi project.

```bash
git clone https://github.com/mben-dz/TRangeCheker.git
```
## Usage Example

Here’s how to use `TRange<T>` to check values in different types of ranges:

### TRange<T> Static Class
```pascal
unit API.Utils;

interface

uses
  System.SysUtils,           // [Exceptions]
  System.Generics.Defaults;  // [IComparer, TComparer]

type
  TRange<T> = class
  public
    // Check if a value is within the range [aMin, aMax] using a custom comparer
    class function IsIn(const aValue, aMin, aMax: T; const aComparer: IComparer<T>): Boolean; overload; static;

    // Check if a value is within the range [aMin, aMax] using the default comparer
    class function IsIn(const aValue, aMin, aMax: T): Boolean; overload; static;
  end;

implementation

{ TRange<T> }

class function TRange<T>.IsIn(const aValue, aMin, aMax: T; const aComparer: IComparer<T>): Boolean;
begin
  case GetTypeKind(T) of
    tkString, tkClass, tkLString, tkWString, tkInterface, tkDynArray, tkUString:
    begin
      if PPointer(@aValue)^ = nil then
        Exit(False);
    end;
    tkMethod:
    begin
      if (PMethod(@aValue)^.Data = nil) or (PMethod(@aValue)^.Code = nil) then
        Exit(False);
    end;
    tkPointer:
      if PPointer(@aValue)^ = nil then
        Exit(False);
  end;

  if not Assigned(aComparer) then
    raise EArgumentNilException.Create('Comparer is not assigned.');

  Result := (aComparer.Compare(aValue, aMin) >= 0) and (aComparer.Compare(aValue, aMax) <= 0);
end;

class function TRange<T>.IsIn(const aValue, aMin, aMax: T): Boolean;
begin
  Result := IsIn(aValue, aMin, aMax, TComparer<T>.Default);
end;

end.
```
to put this  Super class in test i build a new console project:  
this unit here act as my objects:  
```pascal
unit API.Objects.Comparer;

interface
uses
  System.Types,
  System.Generics.Defaults;

type
  ICustomRecord = interface; // Forward
  ICustomRecordUpdate = interface
    function Edit(const aName: string; const aValue: Integer): ICustomRecord;
  end;
  ICustomRecord = interface(IInterface)
    function GetName: string;
    function GetValue: Integer;
    function GetCustomRecordUpdate: ICustomRecordUpdate;

    property Name: string read GetName;
    property Value: Integer read GetValue;

    property New: ICustomRecordUpdate read GetCustomRecordUpdate;
  end;

  IProduct = interface; // Forward
  IProductUpdate = interface
    function Edit(const aID: Integer; const aPrice: Currency): IProduct;
  end;
  IProduct = interface
    function GetID: Integer;
    function GetPrice: Currency;
    function GetIProductUpdate: IProductUpdate;

    property ID: Integer read GetID;
    property Price: Currency read GetPrice;

    property New: IProductUpdate read GetIProductUpdate;
  end;

  IClient = interface; // Forward
  IClientUpdate = interface
    function Edit(const aName: string; const aAge: Integer): IClient;
  end;
  IClient = interface
    function GetName: string;
    function GetAge: Integer;
    function GetIClientUpdate: IClientUpdate;

    property Name: string read GetName;
    property Age: Integer read GetAge;

    property New: IClientUpdate read GetIClientUpdate;
  end;

// Compare Custom Records <Helper function>
function CompareCustomRecord(const R1, R2: ICustomRecord): Integer;

// Compare Products by thier Prices <Helper function>
function CompareProductByPrice(const P1, P2: IProduct): Integer;

// Compare Clients by thier Ages <Helper function>
function CompareClientByAge(const C1, C2: IClient): Integer;

// points comparison <Helper functions>
function ComparePoints(const P1, P2: TPoint): Integer; overload;
function ComparePoints(const P1, P2: TPointF): Integer; overload;

// Returns a custom comparer for TPoint
function PointComparer: IComparer<TPoint>;

function GetTCustomRecord(const aName: string; aValue: Integer): ICustomRecord;
function GetTProduct(aID: Integer; aPrice: Currency): IProduct;
function GetTClient(const aName: string; aAge: Integer): IClient;

implementation
uses
  System.SysUtils,
  System.Rtti,
  System.Math;

type
  TcFunc<T, TResult> = reference to function (const aArg1: T): TResult;
  TCompareValues<T> = class
  strict private
  public
    class function
      CompareValues(aValue1, aValue2: T; aExtractor: TcFunc<T, Integer>): Integer; overload; static;
    class function
      CompareValues(aValue1, aValue2: T; aExtractor: TcFunc<T, Currency>): Integer; overload; static;
  end;


class function TCompareValues<T>.CompareValues(aValue1, aValue2: T; aExtractor: TcFunc<T, Integer>): Integer;
begin
  if (GetTypeKind(T) in [tkClass, tkInterface, tkRecord, tkPointer]) then
    if (PPointer(@aValue1)^ = nil) or (PPointer(@aValue2)^ = nil) then
      Exit(1);

  if (GetTypeKind(T) = tkRecord) then
  begin
    // Handle TPoint specifically
    if TypeInfo(T) = TypeInfo(TPoint) then
    begin
      var P1 := TPoint(Pointer(@aValue1)^);
      var P2 := TPoint(Pointer(@aValue2)^);

      if P1.X <> P2.X then
        Exit(Sign(P1.X - P2.X));
      if P1.Y <> P2.Y then
        Exit(Sign(P1.Y - P2.Y));
      Exit(0);
    end;

    // Handle TPointF specifically
    if TypeInfo(T) = TypeInfo(TPointF) then
    begin
      var P1 := TPointF(Pointer(@aValue1)^);
      var P2 := TPointF(Pointer(@aValue2)^);

      if not SameValue(P1.X, P2.X) then
        Exit(Sign(P1.X - P2.X));
      if not SameValue(P1.Y, P2.Y) then
        Exit(Sign(P1.Y - P2.Y));
      Exit(0);
    end;
  end;

  // Fallback for other types using aExtractor
  var V1 := aExtractor(aValue1);
  var V2 := aExtractor(aValue2);

  Result := Sign(V1 - V2);
end;

class function TCompareValues<T>
  .CompareValues(aValue1, aValue2: T; aExtractor: TcFunc<T, Currency>): Integer;
begin
  if aExtractor(aValue1) < aExtractor(aValue2) then
    Result := -1
  else if aExtractor(aValue1) > aExtractor(aValue2) then
    Result := 1
  else
    Result := 0;
end;

type
  TCustomRecord = class(TInterfacedObject, ICustomRecord, ICustomRecordUpdate)
  strict private
    fName: string;
    fValue: Integer;
    function GetName: string;
    function GetValue: Integer;
    function GetCustomRecordupdate: ICustomRecordUpdate;
    function Edit(const aName: string; const aValue: Integer): ICustomRecord;
  public
    constructor Create(const aName: string; aValue: Integer);
  end;

  TProduct = class(TInterfacedObject, IProduct, IProductUpdate)
  private
    fID: Integer;
    fPrice: Currency;
    function GetID: Integer;
    function GetPrice: Currency;
    function GetIProductUpdate: IProductUpdate;
    function Edit(const aID: Integer; const aPrice: Currency): IProduct;
  public
    constructor Create(aID: Integer; aPrice: Currency);
  end;

  TClient = class(TInterfacedObject, IClient, IClientUpdate)
  private
    fName: string;
    fAge: Integer;
    function GetName: string;
    function GetAge: Integer;
    function GetIClientUpdate: IClientUpdate;
    function Edit(const aName: string; const aAge: Integer): IClient;
  public
    constructor Create(const aName: string; aAge: Integer);
  end;

function GetTCustomRecord(const aName: string; aValue: Integer): ICustomRecord;
begin
  Result := TCustomRecord.Create(aName, aValue);
end;

function GetTProduct(aID: Integer; aPrice: Currency): IProduct;
begin
  Result := TProduct.Create(aID, aPrice);
end;

function GetTClient(const aName: string; aAge: Integer): IClient;
begin
  Result := TClient.Create(aName, aAge);
end;

{$REGION '  Points Comparer & Helper Functions .. '}
function ComparePoints(const P1, P2: TPoint): Integer;
begin
  Result := TCompareValues<TPoint>.CompareValues(P1, P2,
    function(const aPoint: TPoint): Integer
    begin
      // Combine X and Y into a single Integer for comparison, prioritizing X
      Result := (aPoint.X shl 16) or (aPoint.Y and $FFFF);
    end);
end;

function ComparePoints(const P1, P2: TPointF): Integer;
begin
  Result := TCompareValues<TPointF>.CompareValues(P1, P2,
    function(const aPoint: TPointF): Integer
    begin
      // Scale X to an integer to maintain precision
      Result := Trunc(aPoint.X * 1000);
    end);

  // If X is equal, compare Y
  if Result = 0 then
    Result := TCompareValues<TPointF>.CompareValues(P1, P2,
      function(const aPoint: TPointF): Integer
      begin
        // Scale Y to an integer to maintain precision
        Result := Trunc(aPoint.Y * 1000);
      end);
end;

function PointComparer: IComparer<TPoint>;
begin
  Result := TComparer<TPoint>.Construct(
    function(const P1, P2: TPoint): Integer
    begin
      Result := ComparePoints(P1, P2);
    end
  );
end;
{$ENDREGION}

{ Helper CustomRecord function }

function CompareCustomRecord(const R1, R2: ICustomRecord): Integer;
begin
  Result := TCompareValues<ICustomRecord>.CompareValues(R1, R2,
    function(const aRec: ICustomRecord): Integer
    begin
      Result := aRec.Value;
    end);
end;

{ Helper ProductByPrice function }

function CompareProductByPrice(const P1, P2: IProduct): Integer;
begin
  Result := TCompareValues<IProduct>.CompareValues(P1, P2,
    function(const aProduct: IProduct): Currency
    begin
      Result := aProduct.Price;
    end);
end;

{ Helper ClientByAge function }

function CompareClientByAge(const C1, C2: IClient): Integer;
begin
  Result := TCompareValues<IClient>.CompareValues(C1, C2,
    function(const aClient: IClient): Integer
    begin
      Result := aClient.Age;
    end);
end;

{ TCustomRecord }

{$REGION '  TCustomRecord .. '}
constructor TCustomRecord.Create(const aName: string; aValue: Integer);
begin
  fName  := aName;
  fValue := aValue;
end;

function TCustomRecord.GetName: string;
begin
  Result := fName;
end;

function TCustomRecord.GetValue: Integer;
begin
  Result := fValue;
end;

function TCustomRecord.GetCustomRecordupdate: ICustomRecordUpdate;
begin
  Result := Self as ICustomRecordUpdate;
end;

function TCustomRecord.Edit(const aName: string;
  const aValue: Integer): ICustomRecord;
begin
  fName  := aName;
  fValue := aValue;
end;
{$ENDREGION}

{ TProduct }

{$REGION '  TProduct .. '}
constructor TProduct.Create(aID: Integer; aPrice: Currency);
begin
  fID    := aID;
  fPrice := aPrice;
end;

function TProduct.GetID: Integer;
begin
  Result := fID;
end;

function TProduct.GetPrice: Currency;
begin
  Result := fPrice;
end;

function TProduct.GetIProductUpdate: IProductUpdate;
begin
  Result := Self as IProductUpdate;
end;

function TProduct.Edit(const aID: Integer; const aPrice: Currency): IProduct;
begin
  fID    := aID;
  fPrice := aPrice;
end;
{$ENDREGION}

{ TClient }

{$REGION '  TClient .. '}
constructor TClient.Create(const aName: string; aAge: Integer);
begin
  fName := aName;
  fAge  := aAge;
end;

function TClient.GetName: string;
begin
  Result := fName;
end;

function TClient.GetAge: Integer;
begin
  Result := fAge;
end;

function TClient.GetIClientUpdate: IClientUpdate;
begin
  Result := Self as IClientUpdate;
end;

function TClient.Edit(const aName: string; const aAge: Integer): IClient;
begin
  fName := aName;
  fAge  := aAge;
end;
{$ENDREGION}

end.
```
## Extensibility

You can easily extend `TRange<T>` to support:
1. **String ranges** using `AnsiCompareStr` or `AnsiCompareText`.
2. **Custom comparators** by adding a comparator function to the class.

This allows you to handle complex types or special ordering logic. 

## TesterClass:  
i build a new class to test all together <`API.RangeCheckerTest`>  
```Pascal
unit API.RangeCheckerTest;

interface
uses
  System.SysUtils,
  System.Rtti, System.TypInfo,
  System.Types,
  DateUtils,
//
  API.Objects.Comparer,
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

  // Register variables (NB: Registering variables must be done After variables is Assigned!!)
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
```
## finally the dpr console code:
```Pascal
program RangeCheckerPrj;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  DateUtils,
  System.Types,
  System.Generics.Defaults,
  API.Utils in 'API\API.Utils.pas',
  API.Objects.Comparer in 'API\API.Objects.Comparer.pas',
  API.RangeCheckerTest in 'API\API.RangeCheckerTest.pas';

begin

  try
    Writeln('-----------------<< Integer Tests >>--------------------------------');
    Writeln(TRangeTester<Integer>.Test(5, 1, 10)); // "5 is within the range [1, 10]"
    Writeln(TRangeTester<Integer>.Test(15, 1, 10)); // "15 is outside the range [1, 10]"

    Writeln('-----------------<< Int64 Tests >>--------------------------------');
    Writeln(TRangeTester<Int64>.Test(5_000_000_000_000_000_001, 5_000_000_000_000_000_000, 5_000_000_000_000_000_010));
    Writeln(TRangeTester<Int64>.Test(5_000_000_000_000_000_000, 5_000_000_000_000_000_001, 5_000_000_000_000_000_010));


    Writeln('-----------------<< Float Tests >>----------------------------------');
    Writeln(TRangeTester<Double>.Test(7.5, 5.0, 10.0));
    Writeln(TRangeTester<Double>.Test(7.5, 7.6, 10.0));


    Writeln('-----------------<< DateTime Tests >>------------------------------');
    Writeln(TRangeTester<TDateTime>.Test(Today, Today, Today +10));
    Writeln(TRangeTester<TDateTime>.Test(Yesterday, Today, Today +10));

    Writeln('-----------------<< String Tests >>--------------------------------');
    Writeln(TRangeTester<string>.Test('hello', 'alpha', 'zulu'));
    Writeln(TRangeTester<string>.Test('zulu', 'alpha', 'omega'));
    Writeln(TRangeTester<string>.Test('b', 'a', 'c')); // "'b' is within the range ['a', 'c']"
    Writeln(TRangeTester<string>.Test('A', 'b', 'c'));
    Writeln(TRangeTester<string>.Test('B', 'a', 'c'));

    Writeln('-----------------<< TPoint Tests >>-----------------------------');
    Writeln(TRangeTester<TPoint>.Test(gPoint1, gPoint2, gPoint3, PointComparer));
    Writeln(TRangeTester<TPoint>.Test(Point(5, 5), Point(0, 0), Point(3, 4), PointComparer));

    Writeln('-----------------<< TCustomRecord Tests >>-----------------------------');
    Writeln(TRangeTester<ICustomRecord>.Test(gRec1, gRec2, gRec3, gRecordComparer));
      gRec1.New.Edit('Mid', 40);
    Writeln(TRangeTester<ICustomRecord>.Test(gRec1, gRec2, gRec3, gRecordComparer));

    Writeln('-----------------<< TProduct Tests >>-----------------------------');
    Writeln(TRangeTester<IProduct>.Test(gProduct1, gProduct2, gProduct3, gProductComparer));
      gProduct1.New.Edit(1, 40);
    Writeln(TRangeTester<IProduct>.Test(gProduct1, gProduct2, gProduct3, gProductComparer));

    Writeln('-----------------<< TClient Tests >>-----------------------------');
    Writeln(TRangeTester<IClient>.Test(gClient1, gClient2, gClient3, gClientComparer));
      gClient1.New.Edit('Alice', 40);
    Writeln(TRangeTester<IClient>.Test(gClient1, gClient2, nil, gClientComparer));

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  Readln;
end.
```

