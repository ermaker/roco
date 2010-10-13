require 'struct_reader'

# It needs filename
module CStruct
  include Enumerable

  def structname
    self.class.name.downcase
  end

  def size
    @size ||= StructReader.structures[structname][0]
  end

  def each
    open(filename) do |f|
      while data = f.read(size)
        yield StructReader.make_struct(structname, data)
      end
    end
  end
end

class Userec
  include CStruct
  def initialize filename
    @filename = filename
  end
  attr_reader :filename
end
