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
    lambda do
      loco.permission?('notexists/notexists')
    end.should raise_error(Errno::ENOENT)
  end

  it 'should traverse boards' do
    loco = Loco.new
    loco.login('user2','1234').should_not == nil

    loco.boards.should == [{:isdirectory=>0, :filename=>"a", :owner=>"SYSOP"}, {:isdirectory=>1, :filename=>"layer11", :owner=>"SYSOP"}, {:isdirectory=>1, :filename=>"layer12", :owner=>"SYSOP"}]
    loco.boards('layer11').should == [{:isdirectory=>0, :filename=>"a", :owner=>"user1"}, {:isdirectory=>0, :filename=>"b", :owner=>"user2"}, {:isdirectory=>0, :filename=>"bb", :owner=>"user1"}, {:isdirectory=>1, :filename=>"dir1", :owner=>"SYSOP"}, {:isdirectory=>1, :filename=>"dir2", :owner=>"SYSOP"}]

    usernum = loco.instance_eval('@usernum')

    loco.articles('a') do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == [["d", "user2", false, true], ["c", "user1", false, false], ["b", "user1", true, false], ["a", "user1", false, true], ["post 1", "SYSOP", false, true]]

    loco.articles('a', 0, 2) do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == [["d", "user2", false, true], ["c", "user1", false, false]]
    loco.articles('a', 2, 2) do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == [["b", "user1", true, false], ["a", "user1", false, true]]
    loco.articles('a', 4, 2) do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == [["post 1", "SYSOP", false, true]]
    loco.articles('a', 5, 2) do |a|
      a.map {|v| [v.title, v.owner, v.visit[usernum], v.read[usernum]]}
    end.should == []
  end

  it 'should read a article' do
    loco = Loco.new
    loco.login('user2','1234').should_not == nil
    usernum = loco.instance_eval('@usernum')

    loco.articles('a') do |a|
      [a[1].title, a[1].owner, a[1].readcnt, a[1].visit[usernum], a[1].read[usernum]]
    end.should == ["c", "user1", 0, false, false]
    article_filename = loco.articles('a', 1, 1) {|a|a[0].filename}
    loco.read('a', article_filename).should == "\261\333\276\264\300\314: user1 (nick1)\n\263\257  \302\245: 2010/12/21 (\310\255) 19:30:09\n\301\246  \270\361: c\n\nc\n"
    loco.articles('a') do |a|
      [a[1].title, a[1].owner, a[1].readcnt, a[1].visit[usernum], a[1].read[usernum]]
    end.should == ["c", "user1", 1, false, true]
  end

  it 'should write a article' do
    loco = Loco.new
    loco.login('club','1234').should_not == nil
    usernum = loco.instance_eval('@usernum')
    Time.stub!(:now).and_return{Time.at(0)}

    loco.articles('club') do |a|
      a.map do |v|
        [v.filename,v.owner,v.title,
          v.tm_year,v.tm_mon,v.tm_mday,v.read[usernum]]
      end
    end.should == []
    Loco::Userec.as {|u|u[usernum].numposts}.should == 0
    loco.write('club') do |a|
      a.title = 'title'
      a.content = 'content'
    end.should == true
    ret = loco.articles('club') do |a|
      a.map do |v|
        [v.filename,v.owner,v.title,
          v.tm_year,v.tm_mon,v.tm_mday,v.read[usernum]]
      end
    end
    ret.should == [["M.0.A", "club", "title", 70, 0, 1, true]]
    loco.read('club', ret[0][0]).should == "\261\333\276\264\300\314: club (club)\n\263\257  \302\245: 1970/01/01 (\270\361) 09:00:00\n\301\246  \270\361 : title\n\ncontent\nclub sig\n"
    loco.articles('club') do |a|
      a.map do |v|
        [v.filename,v.owner,v.title,
          v.tm_year,v.tm_mon,v.tm_mday,v.read[usernum]]
      end
    end.should == [["M.0.A", "club", "title", 70, 0, 1, true]]
    Loco::Userec.as {|u|u[usernum].numposts}.should == 1
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
      Loco::Dir_fileheader.as(:path => 'a') do |d|
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
      Loco::Dir_fileheader.as(:path => 'a') do |d|
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
      Loco::Dir_fileheader.as(:path => 'a') do |d|
        d[1].read[usernum].should == false
      end
      Loco::Dir_fileheader.as(:path => 'a', :mode => 'r+') do |d|
        d[1].read[usernum] = true
      end
      Loco::Dir_fileheader.as(:path => 'a') do |d|
        d[1].read[usernum].should == true
      end
      Loco::Dir_fileheader.as(:path => 'a') do |d|
        d[1].visit[usernum].should == false
      end
      Loco::Dir_fileheader.as(:path => 'a', :mode => 'r+') do |d|
        d[1].visit[usernum] = true
      end
      Loco::Dir_fileheader.as(:path => 'a') do |d|
        d[1].visit[usernum].should == true
      end
    end
  end

  describe Loco::Cache do
    it'should read a file' do
      Loco::Cache.as do |c|
        c.map do |cc|
          [cc.board.filename, cc.board_hash_val]
        end
      end.should == [["a", 5408], ["layer11/", 0], ["layer12/", 0], ["club", 27040], ["sysop", 13520], ["clubdir/", 27040], ["layer11/a", 1352], ["layer11/b", 1404], ["layer11/bb", 1404], ["layer11/dir1/", 1508], ["layer11/dir2/", 1508], ["layer11/dir1/b1", 1535], ["layer11/dir1/b2", 1535], ["layer11/dir2/a", 1534], ["layer11/dir2/b", 1535], ["clubdir/clubdir/", 28496], ["clubdir/sysopdir/", 29328], ["clubdir/clubdir/normal", 28535], ["clubdir/sysopdir/normal", 29367], ["..", 1535]]
    end
  end
end
