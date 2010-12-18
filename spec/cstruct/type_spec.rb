require 'rspec'
require 'cstruct/type'
require 'yaml'

describe CStruct::Type::StructType do
  it 'should have getters and setters with a int type member variable' do
    info = YAML::load(open(File.dirname(__FILE__) +
                           '/../fixtures/structures.yml'))
    io = StringIO.new("\x01\x00\x00\x00")
    struct = CStruct::Type::StructType.new(info["simple_struct_int"], io)
    struct.get('simple_int').should == 1
    struct.set('simple_int', 2)
    io.seek(0)
    io.read.should == "\x02\x00\x00\x00"
  end
  it 'should have getters and setters with a int array type member variable' do
    info = YAML::load(open(File.dirname(__FILE__) +
                           '/../fixtures/structures.yml'))
    io = StringIO.new("\x01\x00\x00\x00\x02\x00\x00\x00\x03\x00\x00\x00")
    struct = CStruct::Type::StructType.new(info["simple_struct_int_array"], io)
    struct.get('simple_int_array').get(0).should == 1
    struct.get('simple_int_array').get(1).should == 2
    struct.get('simple_int_array').get(2).should == 3
    struct.get('simple_int_array').set(0, 2)
    struct.get('simple_int_array').set(1, 4)
    struct.get('simple_int_array').set(2, 6)
    io.seek(0)
    io.read.should == "\x02\x00\x00\x00\x04\x00\x00\x00\x06\x00\x00\x00"
  end
end
