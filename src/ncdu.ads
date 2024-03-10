with Ada.Containers.Indefinite_Ordered_Multisets;
with Ada.Directories;

generic
   --  Since ordering is stored in a package-global function pointer, by making
   --  the library generic we avoid any concurrency troubles
package Ncdu is

   subtype Kinds is Ada.Directories.File_Kind;

   subtype Paths is String; -- Platform-specific-encoded path

   subtype Sizes is Ada.Directories.File_Size;

   type Base_Item is abstract tagged null record;

   function "<" (L, R : Base_Item'Class) return Boolean;

   package Item_Sets is
     new Ada.Containers.Indefinite_Ordered_Multisets (Base_Item'Class);
   --  In practice, all elements are Items (see below)

   subtype Tree is Item_Sets.Set;

   type Item (Path_Length : Natural) is new Base_Item with record
      Kind          : Kinds;
      Path          : Paths (1 .. Path_Length); -- Full absolute path
      Size          : Sizes;
      --  For directories and special files this is impl defined
      Children_Size : Sizes; -- Cummulative size of children
      Children      : Tree;
   end record;

   function Element (Base : Base_Item'Class) return Item is (Item (Base));

   type Sorting is access function (This, Than : Item) return Boolean;

   function Is_Larger (This, Than : Item) return Boolean;

   function List (Path : Paths;
                  Sort : Sorting := Is_Larger'Access)
                  return Tree;
   --  Default size is by decreasing size, alphabetical if same size

   procedure Print (This : Tree);
   --  Basic dump for debugging purposes mostly

end Ncdu;
