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
