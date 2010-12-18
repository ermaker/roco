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
end
