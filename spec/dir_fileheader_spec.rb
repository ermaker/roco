require 'rspec'
require 'dir_fileheader'

describe Dir_fileheader do
  before do
    StructReader.load(File.dirname(__FILE__) + '/fixtures/structures.yml')
    @entries = Dir_fileheader.new(File.dirname(__FILE__) + '/fixtures/.DIR')
  end

  it 'should get accessed status' do
    [
      [0, true, false],
      [1, false, true],
      [2, true, false],
    ].each do |uid,read,visit|
      @entries[0].read?(uid).should == read
      @entries[0].visit?(uid).should == visit
    end
  end

end
