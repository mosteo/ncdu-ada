with GNAT.IO;

package body Ncdu is

   package Adirs renames Ada.Directories;

   Current_Sorting : Sorting := Is_Larger'Access;

   ---------
   -- "<" --
   ---------

   function "<" (L, R : Base_Item'Class) return Boolean
   is (Current_Sorting (Item (L), Item (R)));

   ---------------
   -- Is_Larger --
   ---------------

   function Is_Larger (This, Than : Item) return Boolean
   is (This.Tree_Size > Than.Tree_Size
       or else
         (This.Tree_Size = Than.Tree_Size
          and then This.Path < Than.Path));

   ----------
   -- List --
   ----------

   function List (Path     : Paths;
                  Sort     : Sorting := Is_Larger'Access;
                  Progress : access procedure (Exploring : String) := null)
                  return Tree
   is
      use all type Adirs.File_Kind;

      -------------------
      -- List_Internal --
      -------------------

      function List_Internal (Path : Paths) return Tree is
      begin
         if Progress /= null then
            Progress (Path);
         end if;

         return Result : Tree do
            declare

               ---------------
               -- List_Item --
               ---------------

               procedure List_Item (Item : Adirs.Directory_Entry_Type) is
                  Children      : Tree;
                  Children_Size : Sizes := 0;
               begin
                  if Adirs.Simple_Name (Item) in "." | ".." then
                     return;
                  end if;

                  if Kind (Item) = Directory then
                     Children := List_Internal (Adirs.Full_Name (Item));
                     for Child of Children loop
                        Children_Size := Children_Size + Child.Tree_Size;
                     end loop;
                  end if;

                  Result.Insert
                    (Ncdu.Item'
                       (Path_Length   => Adirs.Full_Name (Item)'Length,
                        Kind          => Adirs.Kind (Item),
                        Path          => Adirs.Full_Name (Item),
                        Size          => Adirs.Size (Item),
                        Children_Size => Children_Size,
                        Children      => Children));
               end List_Item;

            begin
               Adirs.Search (Path,
                             Pattern => "",
                             Process => List_Item'Access);
            end;
         end return;
      end List_Internal;

   begin
      Current_Sorting := Sort;

      return Root : Tree do
         if not Adirs.Exists (Path) then
            return;
         end if;

         declare
            Children : constant Tree := List_Internal (Path);
            Size     : Sizes := 0;
         begin
            for Child of Children loop
               Size := Size + Child.Tree_Size;
            end loop;

            Root.Insert
              (Item'
                 (Path_Length   => Adirs.Full_Name (Path)'Length,
                  Kind          => Adirs.Kind (Path),
                  Path          => Adirs.Full_Name (Path),
                  Size          => (if Adirs.Kind (Path) = Directory
                                    then 0
                                    else Adirs.Size (Path)),
                  Children_Size => Size,
                  Children      => Children));
         end;
      end return;
   end List;

   -----------
   -- Print --
   -----------

   procedure Print (This : Tree) is

      -----------
      -- Print --
      -----------

      procedure Print (Prefix : String; This : Tree) is
         use GNAT.IO;
      begin
         for Item of This loop
            Put_Line (Prefix
                      & Item.Element.Path
                      & ":"
                      & Sizes'(Item.Element.Children_Size
                             + Item.Element.Size)'Image
                      & " tree bytes,"
                      & Item.Element.Size'Image & " self bytes");
            if not Item.Element.Children.Is_Empty then
               Print (Prefix & "   ", Item.Element.Children);
            end if;
         end loop;
      end Print;

   begin
      Print ("", This);
   end Print;

end Ncdu;
