with Ncdu;

procedure Example is
   package Du is new Ncdu;
begin
   Du.Print (Du.List ("."));
end Example;
