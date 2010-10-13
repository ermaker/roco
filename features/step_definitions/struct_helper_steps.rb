require 'struct_helper'

Then /^all struct information is correct\.$/ do
  StructHelper.include_dirs = ['spec/fixtures']
  StructHelper.headers = %w[simple_struct.h]
  StructHelper.info.sort.should == [
    ["simple_struct_char_array", [[0, "char [0]", "simple_char_array"]]],
    ["simple_struct_int", [[0, "int", "simple_int"]]],
    ["simple_struct_int2", [[0, "int", "simple_int1"], [4, "int", "simple_int2"]]],
    ["simple_struct_int_array", [[0, "int [3]", "simple_int_array"]]]
  ].sort
end
