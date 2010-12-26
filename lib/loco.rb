require 'lib/cstruct/type'
require 'yaml'

module CStruct
  module Type
    class AccessedReadType < ArrayType
      alias super_get get
      def get usernum
        (super_get(usernum/4)>>(2*(3-(usernum%4))))&1 == 1
      end
      alias super_set set
      def set usernum, value
        value = get(usernum) != value ? 1 : 0
        byte_value = super_get(usernum/4)
        byte_value ^= value << (2*(3-(usernum%4)))
        super_set(usernum/4, byte_value)
      end
    end
    class AccessedVisitType < ArrayType
      alias super_get get
      def get usernum
        (super_get(usernum/4)>>(2*(3-(usernum%4))+1))&1 == 1
      end
      alias super_set set
      def set usernum, value
        value = get(usernum) != value ? 1 : 0
        byte_value = super_get(usernum/4)
        byte_value ^= value << (2*(3-(usernum%4))+1)
        super_set(usernum/4, byte_value)
      end
    end
    class StructType
      def read
        var_info = @info[:type][:member]['accessed']
        @io.seek(@offset + var_info[:offset])
        return AccessedReadType.new var_info, @io
      end
      def visit
        var_info = @info[:type][:member]['accessed']
        @io.seek(@offset + var_info[:offset])
        return AccessedVisitType.new var_info, @io
      end
    end
  end
end

class Loco
  class << self
    attr_accessor :path
    attr_accessor :info
  end

  def login userid, passwd
    Loco::Userec.as do |u|
      @usernum = u.login userid, passwd
    end
  end

  def boards path='.', idx=0, count=25
    return false unless permission?(path)
    Fileheader.as(:path => path) do |d|
      d = d.select {|v| permission_once?(path, v.filename)}[idx, count]||[]
      if block_given?
        yield d
      else
        d.map do |v|
          {
            :filename => path == '.' ? v.filename : File.join(path, v.filename),
            :owner => v.owner,
            :isdirectory => v.isdirectory,
          }
        end
      end
    end
  end

  def articles path, idx=0, count=25
    return false unless permission?(path)
    Dir_fileheader.as(:path => path) do |a|
      a = a.to_a.reverse[idx, count]||[]
      if block_given?
        yield a
      else
        a.map do |v|
          {
            :title => v.title,
            :owner => v.owner,
            :read => v.read[@usernum],
            :visit => v.visit[@usernum],
            :hightlight => v.highlight,
            :readcnt => v.readcnt,
            :filename => v.filename,
          }
        end
      end
    end
  end

  def read path, article_filename
    return false unless permission?(path)
    # TODO: Update abuse data
    Dir_fileheader.as(:path => path, :mode => 'r+') do |a|
      aa = a.find {|v| v.filename == article_filename}
      aa.readcnt += 1
      aa.visit[@usernum] = false
      aa.read[@usernum] = true
    end
    filename = File.join(self.class.path, 'boards', path, article_filename)
    return open(filename) do |f|
      f.flock(File::LOCK_SH)
      f.read
    end
  end

  ARTICLE_CLASS = Struct.new(:title, :content)

  def write path
    return false unless permission?(path)
    article = ARTICLE_CLASS.new
    yield article

    # Make a article file
    userid, username = Userec.as {|u| [u[@usernum].userid, u[@usernum].username]}
    time = nil
    article_filename = nil
    begin
      time = Time.now
      article_filename = "M.#{time.to_i}.A"
      open(File.join(Loco.path, 'boards', path, article_filename),
          File::CREAT|File::EXCL|File::WRONLY) do |f|
        f.puts "글쓴이: #{userid} (#{username})"
        f.puts "날  짜: #{time.strftime("%Y/%m/%d (#{%w[일 월 화 수 목 금 토][time.wday]}) %T")}"
        f.puts "제  목 : #{article.title}"
        f.puts
        f.puts article.content
        # append signature
        if Userec.as {|u| u[@usernum].flags[0]} & 0x8 == 0
          # if user's signature setting is turned on
          begin
            f.puts File.read(File.join(Loco.path, 'signatures', userid))
          rescue Errno::ENOENT
          end
        end
      end
    rescue Errno::EEXIST
      sleep 0.1
      retry
    end

    # Append information to Dir_fileheader
    Dir_fileheader.as(:path => path, :mode => 'r+') do |d|
      d.append do |dd|
        dd.filename = article_filename
        dd.owner = userid
        dd.title = article.title
        dd.tm_year = time.year - 1900
        dd.tm_mon = time.mon - 1
        dd.tm_mday = time.day
        dd.read[@usernum] = true
      end
    end

    # TODO: Update abuse_data

    # Update .BOARD_TIMESTAMP
    real_path = File.join(Loco.path, 'boards', path)
    real_path = File.readlink(real_path) while File.symlink?(real_path)
    hash = Loco::Cache.as do |c|
      c.select do |cc|
        File.identical?(real_path, File.join(Loco.path, 'boards', cc.board.filename))
      end.map(&:board_hash_val)
    end
    Loco::Board_timestamp.as(:mode => 'r+') do |b|
      hash.each do |h|
        3.times do |idx|
          h = (h / 52**idx) * 52**idx
          b[h] = time.to_i
        end
      end
    end

    # Update Userec
    Userec.as(:mode => 'r+') do |u|
      u[@usernum].numposts += 1
    end
    return true
  end

  def permission_once? dirname, basename
    return if basename == '.'
    Fileheader.as(:path => dirname) do |d|
      dd = d.find {|v| v.filename == basename}
      return false unless dd
      Userec.as do |u|
        return dd.level == 0 || dd.level & u[@usernum].userlevel != 0
      end
    end
  end
  def permission? path
    until path == '.'
      return false unless permission_once?(
        File.dirname(path), File.basename(path))
      path = File.dirname(path)
    end
    return true
  rescue Errno::ENOENT
    return false
  end

  @info = YAML::load(open(File.dirname(__FILE__) + '/../structures.yml'))

  module CStructFileInclude
    include Enumerable
    def initialize info, io, mode
      super(info, io)
      if mode == 'r'
        flock File::LOCK_SH
      else
        flock File::LOCK_EX
      end
    end
    def flock lock
      @io.flock lock
    end
    def length
      File.size(@io.path)/@info[:type][:type][:size]
    end
    alias size length
    def each
      (0...length).each do |i|
        yield get(i)
      end
    end
    def append
      ret = get(length)
      @io.truncate((length+1) * @info[:type][:type][:size])
      yield ret
    end
  end

  module CStructFileExtend
    def default_opt opt
      {:path => '.', :mode => 'r'}.merge(opt)
    end
    def type
      Loco.info[name.split('::').last.downcase]
    end
    def as opt={}
      opt = default_opt opt
      File.open(self.path(opt[:path]), opt[:mode]) do |io|
        yield new({:type => type}, io, opt[:mode])
      end
    end
  end

  class Userec < CStruct::Type::ArrayType
    extend CStructFileExtend
    include CStructFileInclude
    def self.path path
      return File.join(Loco.path, '.PASSWDS')
    end
    def login userid, passwd
      found = each_with_index.find do |userec,index|
        userec.userid == userid &&
          passwd.crypt(userec.passwd) == userec.passwd
      end
      return found && found[1]
    end
  end
  class Fileheader < CStruct::Type::ArrayType
    extend CStructFileExtend
    include CStructFileInclude
    def self.path path
      return File.join(Loco.path, 'boards', path, '.BOARDS')
    end
  end
  class Dir_fileheader < CStruct::Type::ArrayType
    extend CStructFileExtend
    include CStructFileInclude
    def self.path path
      return File.join(Loco.path, 'boards', path, '.DIR')
    end
  end
  class Cache < CStruct::Type::ArrayType
    extend CStructFileExtend
    include CStructFileInclude
    def self.path path
      return File.join(Loco.path, '.BCACHE')
    end
  end
  class Board_timestamp < CStruct::Type::ArrayType
    extend CStructFileExtend
    include CStructFileInclude
    def self.path path
      return File.join(Loco.path, '.BOARD_TIMESTAMP')
    end
    def self.type
      {:type => {
        :pack => 'l_',
        :size => 8,
        :name => 'long',
        :kind => 'primary',
      }}
    end
  end
end
