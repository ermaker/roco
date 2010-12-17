require 'rspec'
require 'cstruct/crawler'

describe CStruct::Crawler do
  before do
    CStruct::Helper.include_dirs = [File.dirname(__FILE__) + '/../fixtures']
    CStruct::Helper.headers = %w[simple_struct.h]
    CStruct::Crawler.include_dirs = [File.dirname(__FILE__) + '/../fixtures']
    CStruct::Crawler.headers = %w[simple_struct.h]
  end

  it 'should get all struct information' do
    CStruct::Crawler.info.sort.should == [
      ["simple_struct_char_array", [0, [0, "char [0]", "simple_char_array"]]],
      ["simple_struct_int", [4, [0, "int", "simple_int"]]],
      ["simple_struct_int2", [8, [0, "int", "simple_int1"], [4, "int", "simple_int2"]]],
      ["simple_struct_int_array", [12, [0, "int [3]", "simple_int_array"]]]
    ].sort
  end
end
