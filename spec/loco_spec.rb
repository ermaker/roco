require 'rspec'
require 'loco'
require 'cstruct/crawler'
require 'fileutils'

describe Loco do
  before do
    CStruct.include_dirs=['../loco']
    CStruct.headers=['bbs.h']
    CStruct::Crawler.save('structures.yml')
    FileUtils.rm_r('tmp') rescue nil
    FileUtils.cp_r(File.dirname(__FILE__) + '/fixtures/loco', 'tmp')
    Loco::path = 'tmp'
  end

  after do
    FileUtils.rm_r('tmp') rescue nil
  end

  it 'should check login' do
    loco = Loco.new
    loco.login('SYSOP','1234').should == true
    loco.login('SYSOP','4321').should == false
    loco.login('SYSOP2','1234').should == false
    loco.login('user1','4321').should == true
    loco.login('user2','1234').should == true
  end

  describe Loco::Userec do
    it 'should read a file' do
      Loco::Userec.as do |u|
        u.login('SYSOP','1234').should == true
        u.login('SYSOP','4321').should == false
        u.login('SYSOP2','1234').should == false
        u.login('user1','4321').should == true
        u.login('user2','1234').should == true
      end
    end
  end

  describe Loco::Fileheader do
    it 'should read a file' do
      Loco::Fileheader.as do |d|
        d.map do |dd|
          [dd.filename, dd.owner, dd.isdirectory]
        end.should == [
          ["a", "SYSOP", 0],
          ["layer11", "SYSOP", 1],
          ["layer12", "SYSOP", 1],
        ]
      end
    end
  end

  describe Loco::Dir_fileheader do
    it 'should read a file' do
      Loco::Dir_fileheader.as('a') do |d|
        d.map do |dd|
          [dd.filename, dd.owner, dd.title]
        end.should == [
          ["M.1287734548.A", "SYSOP", "post 1"],
          ["M.1292927388.A", "user1", "a"],
          ["M.1292927397.A", "user1", "b"],
          ["M.1292927405.A", "user1", "c"],
          ["M.1292927432.A", "user2", "d"],
        ]
      end
    end
  end

end
