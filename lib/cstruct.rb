require 'struct_reader'

# It needs filename
module CStruct
  include Enumerable

  def structname
    self.class.name.downcase
  end

  def sizeof_struct
    @sizeof_struct ||= StructReader.structures[structname][0]
  end

  def length
    @length ||= File.size(filename) / sizeof_struct
  end

  alias size length

  def each
    open(filename) do |f|
      while data = f.read(sizeof_struct)
        yield StructReader.make_struct(structname, data)
      end
    end
  end

  def correct_index idx
    if idx < 0
      idx = length + idx
    end
    return idx
  end
  private :correct_index

  def [] idx_or_range
    if idx_or_range.class == Range
      range = idx_or_range
      first = correct_index range.first
      last = correct_index range.last
      new_range = range.exclude_end? ? first...last : first..last
      new_range.map do |idx|
        self[idx]
      end
    else
      idx = idx_or_range
      idx = correct_index idx
      if 0 <= idx && idx < length
        open(filename) do |f|
          f.seek(idx*sizeof_struct, IO::SEEK_SET)
          StructReader.make_struct(structname, f.read(sizeof_struct))
        end
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
