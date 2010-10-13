require 'struct_helper'

describe StructHelper do
  before do
    StructHelper.include_dirs = [File.dirname(__FILE__) + '/fixtures']
    StructHelper.headers = %w[simple_struct.h]
  end

  it 'should get sizeof struct' do
    StructHelper.sizeof('simple_struct_int').should == 4
    StructHelper.sizeof('simple_struct_int2').should == 8
    StructHelper.sizeof('simple_struct_int_array').should == 12
  end

  it 'should get offsetof member of struct' do
    StructHelper.offsetof('simple_struct_int', 'simple_int').should == 0
    StructHelper.offsetof('simple_struct_int2', 'simple_int1').should == 0
    StructHelper.offsetof('simple_struct_int2', 'simple_int2').should == 4
    StructHelper.offsetof('simple_struct_int_array', 'simple_int_array[0]').should == 0
    StructHelper.offsetof('simple_struct_int_array', 'simple_int_array[1]').should == 4
    StructHelper.offsetof('simple_struct_int_array', 'simple_int_array[2]').should == 8
  end

  it 'should get countof member of struct' do
    StructHelper.countof('simple_struct_int_array', 'simple_int_array').should == 3
  end
end
