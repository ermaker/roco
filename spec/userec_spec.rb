require 'rspec'
require 'userec'

describe Userec do
  before do
    StructReader.load(File.dirname(__FILE__) + '/fixtures/structures.yml')
    @userec = Userec.new(File.dirname(__FILE__) + '/fixtures/.PASSWDS')
  end

  it 'should get userid' do
    (0..2).each do |idx|
      @userec.userid(idx).should == @userec[idx]['userid']
    end
  end

  it 'should get uid' do
    [
      [0, 'SYSOP'],
      [1, 'user1'],
      [2, 'user2'],
    ].each do |idx,userid|
      @userec.uid(userid).should == idx
    end
  end
end
