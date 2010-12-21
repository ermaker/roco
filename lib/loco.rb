require 'lib/cstruct/type'
require 'yaml'

module CStruct
  module Type
    class StructType
      def _accessed usernum
        (accessed[usernum/4]>>(2*(3-(usernum%4))))&3
      end
      def read? usernum
        (accessed[usernum/4]>>(2*(3-(usernum%4))))&1 == 1
      end
      def visit? usernum
        (accessed[usernum/4]>>(2*(3-(usernum%4))+1))&1 == 1
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
      u.flock File::LOCK_SH
      u.login userid, passwd
    end
  end

  @info = YAML::load(open(File.dirname(__FILE__) + '/../structures.yml'))

  module CStructFile
    include Enumerable
    def initialize info, io, filesize
      super(info, io)
      @filesize = filesize
      flock File::LOCK_SH
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
        yield new({:type => Loco.info['userec']}, io, filesize)
      end
    end
    def login userid, passwd
      any? do |userec|
        userec.userid == userid &&
          passwd.crypt(userec.passwd) == userec.passwd
      end
    end
  end
  class Fileheader < CStruct::Type::ArrayType
    include CStructFile
    def self.as path='.', mode='r'
      path = File.join(Loco.path, 'boards', path, '.BOARDS')
      filesize = File.size(path)
      File.open(path, mode) do |io|
        yield new({:type => Loco.info['fileheader']}, io, filesize)
      end
    end
  end
  class Dir_fileheader < CStruct::Type::ArrayType
    include CStructFile
    def self.as path='.', mode='r'
      path = File.join(Loco.path, 'boards', path, '.DIR')
      filesize = File.size(path)
      File.open(path, mode) do |io|
        yield new({:type => Loco.info['dir_fileheader']}, io, filesize)
      end
    end
  end
end
