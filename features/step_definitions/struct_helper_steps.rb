require 'struct_helper'

Then /^all struct information is correct\.$/ do
  StructHelper.include_dirs = ['spec/fixtures']
  StructHelper.headers = %w[simple_struct.h]
  StructHelper.info.sort.should == [
    ["simple_struct_char_array", [["char [0]", "simple_char_array"]]],
    ["simple_struct_int", [["int", "simple_int"]]],
    ["simple_struct_int2", [["int", "simple_int1"], ["int", "simple_int2"]]],
    ["simple_struct_int_array", [["int [3]", "simple_int_array"]]]
  ].sort
end
