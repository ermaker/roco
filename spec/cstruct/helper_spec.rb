require 'rspec'
require 'cstruct/helper'

describe CStruct::Helper do
  before do
    CStruct::Helper.include_dirs = [File.dirname(__FILE__) + '/../fixtures']
    CStruct::Helper.headers = %w[simple_struct.h]
  end

  it 'should get sizeof struct' do
    CStruct::Helper.sizeof('simple_struct_int').should == 4
    CStruct::Helper.sizeof('simple_struct_int2').should == 8
    CStruct::Helper.sizeof('simple_struct_int_array').should == 12
  end

  it 'should get offsetof member of struct' do
    CStruct::Helper.offsetof('simple_struct_int', 'simple_int').should == 0
    CStruct::Helper.offsetof('simple_struct_int2', 'simple_int1').should == 0
    CStruct::Helper.offsetof('simple_struct_int2', 'simple_int2').should == 4
    CStruct::Helper.offsetof('simple_struct_int_array', 'simple_int_array[0]').should == 0
    CStruct::Helper.offsetof('simple_struct_int_array', 'simple_int_array[1]').should == 4
    CStruct::Helper.offsetof('simple_struct_int_array', 'simple_int_array[2]').should == 8
  end

  it 'should get countof member of struct' do
    CStruct::Helper.countof('simple_struct_int_array', 'simple_int_array').should == 3
  end

  it 'should get typeof memeber of struct' do
    CStruct::Helper.typeof('simple_struct_int', 'simple_int').should == 'int'
    CStruct::Helper.typeof('simple_struct_int2', 'simple_int1').should == 'int'
    CStruct::Helper.typeof('simple_struct_int2', 'simple_int2').should == 'int'
    CStruct::Helper.typeof('simple_struct_int_array', 'simple_int_array').should == 'int [3]'
    CStruct::Helper.typeof('simple_struct_int_array', 'simple_int_array[0]').should == 'int'
    CStruct::Helper.typeof('simple_struct_int_array', 'simple_int_array[1]').should == 'int'
    CStruct::Helper.typeof('simple_struct_int_array', 'simple_int_array[2]').should == 'int'
    CStruct::Helper.typeof('simple_struct_char_array', 'simple_char_array').should == 'char [0]'
    CStruct::Helper.typeof('simple_struct_char_array', 'simple_char_array[0]').should == 'char'
  end
end
