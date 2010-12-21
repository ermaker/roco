require 'rspec'
require 'loco'

describe Loco do
  before do
    require 'cstruct/crawler'
    CStruct.include_dirs=['../loco']
    CStruct.headers=['bbs.h']
    CStruct::Crawler.save('structures.yml')
    Loco::path = '../loco'
  end
  it 'should check login' do
    loco = Loco.new
    loco.login('SYSOP','1234').should == true
    loco.login('SYSOP','4321').should == false
    loco.login('SYSOP2','1234').should == false
    loco.login('user1','4321').should == true
    loco.login('user2','1234').should == true
  end
end

describe Loco::Userec do
  before do
    require 'cstruct/crawler'
    CStruct.include_dirs=['../loco']
    CStruct.headers=['bbs.h']
    CStruct::Crawler.save('structures.yml')
    Loco::path = '../loco'
  end
  it 'should have userec class' do
    Loco::Userec.as do |u|
      u.flock File::LOCK_SH
      u.login('SYSOP','1234').should == true
      u.login('SYSOP','4321').should == false
      u.login('SYSOP2','1234').should == false
      u.login('user1','4321').should == true
      u.login('user2','1234').should == true
    end
  end
end
