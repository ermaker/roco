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
        value = value ? 1 : 0
        byte_value = super_get(usernum/4)
        byte_value |= value << (2*(3-(usernum%4)))
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
        value = value ? 1 : 0
        byte_value = super_get(usernum/4)
        byte_value |= value << (2*(3-(usernum%4))+1)
        super_set(usernum/4, byte_value)
      end
    end
    class StructType
      def read
        var_info = @info[:member]['accessed']
        @io.seek(@offset + var_info[:offset])
        return AccessedReadType.new var_info, @io
      end
      def visit
        var_info = @info[:member]['accessed']
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

  def boards path='.'
    return false unless permission?(path)
    Fileheader.as(path) do |d|
      d.select {|v| permission_once?(path, v.filename)}.map do |v|
        path == '.' ? v.filename : File.join(path, v.filename)
      end
    end
  end

  def articles path, last_idx=0, count=25
    return false unless permission?(path)
    Dir_fileheader.as(path) do |a|
      reversed = a.to_a.reverse
      yield reversed[last_idx, count]||[]
    end
  end

  def read path, article_filename
    return false unless permission?(path)
    Dir_fileheader.as(path,'r+') do |a|
      aa = a.find {|v| v.filename == article_filename}
      aa.read[@usernum] = true
    end
    filename = File.join(self.class.path, 'boards', path, article_filename)
    return open(filename) do |f|
      f.flock(File::LOCK_SH)
      f.read
    end
  end

  def permission_once? dirname, basename
    return if basename == '.'
    Fileheader.as(dirname) do |d|
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

  module CStructFile
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
  end

  class Userec < CStruct::Type::ArrayType
    include CStructFile
    def self.as mode='r'
      path = File.join(Loco.path, '.PASSWDS')
      File.open(path, mode) do |io|
        yield new({:type => Loco.info['userec']}, io, mode)
      end
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
    include CStructFile
    def self.as path='.', mode='r'
      path = File.join(Loco.path, 'boards', path, '.BOARDS')
      File.open(path, mode) do |io|
        yield new({:type => Loco.info['fileheader']}, io, mode)
      end
    end
  end
  class Dir_fileheader < CStruct::Type::ArrayType
    include CStructFile
    def self.as path='.', mode='r'
      path = File.join(Loco.path, 'boards', path, '.DIR')
      File.open(path, mode) do |io|
        yield new({:type => Loco.info['dir_fileheader']}, io, mode)
      end
    end
  end
end
