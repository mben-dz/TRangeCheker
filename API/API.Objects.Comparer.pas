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
  if (GetTypeKind(T) in [tkClass, tkInterface, tkPointer]) then
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

    property Name: string read fName;
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
