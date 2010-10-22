require 'struct_reader'

# It needs filename
module CStruct
  include Enumerable

  def initialize filename
    @filename = filename
  end
  attr_reader :filename

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

  def read_range range, &blk
    first = correct_index range.first
    last = correct_index range.last

    return nil unless 0 <= first and first < length

    new_range = range.exclude_end? ? first...last : first..last

    open(filename) do |f|
      f.seek(new_range.first*sizeof_struct, IO::SEEK_SET)
      blk.call(new_range) do
        StructReader.make_struct(structname, f.read(sizeof_struct))
      end
    end
  end
  private :read_range

  def each
    read_range((0..-1)) do |range,&blk|
      range.each {yield blk[]}
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
      read_range(idx_or_range) do |range,&blk|
        range.map {blk[]}
      end
    else
      idx = idx_or_range
      idx = correct_index idx
      if 0 <= idx && idx < length
        self[idx..idx][0]
      end
    end
  end
end
