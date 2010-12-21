require 'lib/cstruct/type'
require 'yaml'

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
  class Userec < CStruct::Type::ArrayType
    include Enumerable
    def self.as mode='r'
      path = File.join(Loco.path, '.PASSWDS')
      filesize = File.size(path)
      File.open(path, mode) do |io|
        yield new({:type => Loco.info['userec']}, io, filesize)
      end
    end
    def initialize info, io, filesize
      super(info, io)
      @filesize = filesize
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
    def login userid, passwd
      any? do |userec|
        userec.userid == userid &&
          passwd.crypt(userec.passwd) == userec.passwd
      end
    end
  end
  class Fileheader < CStruct::Type::ArrayType
    include Enumerable
    def self.as path='.', mode='r'
      path = File.join(Loco.path, 'boards', path, '.BOARDS')
      filesize = File.size(path)
      File.open(path, mode) do |io|
        yield new({:type => Loco.info['fileheader']}, io, filesize)
      end
    end
    def initialize info, io, filesize
      super(info, io)
      @filesize = filesize
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
end
