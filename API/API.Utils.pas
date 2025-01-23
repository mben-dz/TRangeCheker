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
