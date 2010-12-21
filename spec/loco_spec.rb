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
    loco.login('SYSOP','1234').should == 0
    loco.login('SYSOP','4321').should == nil
    loco.login('SYSOP2','1234').should == nil
    loco.login('user1','4321').should == 1
    loco.login('user2','1234').should == 2
  end

  it 'should check permission for fileheader with SYSOP id' do
    loco = Loco.new
    loco.login('SYSOP','1234').should_not == nil
    loco.permission?('sysop').should == true
    loco.permission?('club').should == true
    loco.permission?('a').should == true
    loco.permission?('clubdir/sysopdir/normal').should == true
    loco.permission?('clubdir/clubdir/normal').should == true
  end
  it 'should check permission for fileheader with club id' do
    loco = Loco.new
    loco.login('club','1234').should_not == nil
    loco.permission?('sysop').should == false
    loco.permission?('club').should == true
    loco.permission?('a').should == true
    loco.permission?('clubdir/sysopdir/normal').should == false
    loco.permission?('clubdir/clubdir/normal').should == true
  end
  it 'should check permission for fileheader with normal id' do
    loco = Loco.new
    loco.login('user2','1234').should_not == nil
    loco.permission?('sysop').should == false
    loco.permission?('club').should == false
    loco.permission?('a').should == true
    loco.permission?('clubdir/sysopdir/normal').should == false
    loco.permission?('clubdir/clubdir/normal').should == false
  end

  it 'should check permission when it does not exist' do
    loco = Loco.new
    loco.login('SYSOP','1234').should_not == nil
    loco.permission?('notexists').should == false
    loco.permission?('notexists/notexists').should == false
  end

  it 'should traverse boards' do
    loco = Loco.new
    loco.login('user2','1234').should_not == nil

    loco.boards.should == ["./a", "./layer11", "./layer12"]
    loco.boards('./layer11').should == ["./layer11/a", "./layer11/b", "./layer11/bb", "./layer11/dir1", "./layer11/dir2"]

    usernum = loco.instance_eval('@usernum')

    loco.articles('./a') do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == [["d", "user2", false, true], ["c", "user1", false, false], ["b", "user1", true, false], ["a", "user1", false, true], ["post 1", "SYSOP", false, true]]

    loco.articles('./a', 0, 2) do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == [["d", "user2", false, true], ["c", "user1", false, false]]
    loco.articles('./a', 2, 2) do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == [["b", "user1", true, false], ["a", "user1", false, true]]
    loco.articles('./a', 4, 2) do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == [["post 1", "SYSOP", false, true]]
    loco.articles('./a', 5, 2) do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == []

    article_filename = loco.articles('./a', 1, 1) {|a|a[0].filename}
    loco.read('./a', article_filename).should == "\261\333\276\264\300\314: user1 (nick1)\n\263\257  \302\245: 2010/12/21 (\310\255) 19:30:09\n\301\246  \270\361: c\n\nc\n"

    loco.articles('./a') do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == [["d", "user2", false, true], ["c", "user1", false, true], ["b", "user1", true, false], ["a", "user1", false, true], ["post 1", "SYSOP", false, true]]
  end

  describe Loco::Userec do
    it 'should read a file' do
      Loco::Userec.as do |u|
        u.login('SYSOP','1234').should == 0
        u.login('SYSOP','4321').should == nil
        u.login('SYSOP2','1234').should == nil
        u.login('user1','4321').should == 1
        u.login('user2','1234').should == 2
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
          ["club", "SYSOP", 0],
          ["sysop", "SYSOP", 0],
          ["clubdir", "SYSOP", 1],
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
    it 'should read a bit of read or visit' do
      Loco::Dir_fileheader.as('a') do |d|
        d.map do |dd|
          Loco::Userec.as do |u|
            u.each_with_index.map do |uu,usernum|
              [dd.read[usernum], dd.visit[usernum]]
            end[0..2]
          end
        end.should == [
          [[true, false], [true, false], [true, false]],
          [[false, false], [true, false], [true, false]],
          [[false, false], [true, false], [false, true]],
          [[false, false], [true, false], [false, false]],
          [[false, false], [false, false], [true, false]],
        ]
      end
    end
    it 'should set a bit of read or visit' do
      usernum = 0
      Loco::Dir_fileheader.as('a') do |d|
        d[1].read[usernum].should == false
      end
      Loco::Dir_fileheader.as('a', 'r+') do |d|
        d[1].read[usernum] = true
      end
      Loco::Dir_fileheader.as('a') do |d|
        d[1].read[usernum].should == true
      end
      Loco::Dir_fileheader.as('a') do |d|
        d[1].visit[usernum].should == false
      end
      Loco::Dir_fileheader.as('a', 'r+') do |d|
        d[1].visit[usernum] = true
      end
      Loco::Dir_fileheader.as('a') do |d|
        d[1].visit[usernum].should == true
      end
    end
  end

end
