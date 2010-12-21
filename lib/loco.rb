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

  def permission? path
    until path == '.'
      Fileheader.as(File.dirname(path)) do |d|
        dd = d.find {|v| v.filename == File.basename(path)}
        Userec.as do |u|
          return false unless dd.level == 0 || dd.level & u[@usernum].userlevel != 0
        end
      end
      path = File.dirname(path)
    end
    return true
  end

  @info = YAML::load(open(File.dirname(__FILE__) + '/../structures.yml'))

  module CStructFile
    include Enumerable
    def initialize info, io, filesize, mode
      super(info, io)
      @filesize = filesize
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
      @filesize/@info[:type][:type][:size]
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
      filesize = File.size(path)
      File.open(path, mode) do |io|
        yield new({:type => Loco.info['userec']}, io, filesize, mode)
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
      filesize = File.size(path)
      File.open(path, mode) do |io|
        yield new({:type => Loco.info['fileheader']}, io, filesize, mode)
      end
    end
  end
  class Dir_fileheader < CStruct::Type::ArrayType
    include CStructFile
    def self.as path='.', mode='r'
      path = File.join(Loco.path, 'boards', path, '.DIR')
      filesize = File.size(path)
      File.open(path, mode) do |io|
        yield new({:type => Loco.info['dir_fileheader']}, io, filesize, mode)
      end
    end
  end
end
