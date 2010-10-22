require 'cstruct'

module Dir_fileheader_item
  def accessed uid
    n1 = uid/4
    n2 = uid%4
    (self['accessed'][n1]>>(2*(3-n2)))&3
  end

  def read? uid
    (accessed(uid)&1) == 1
  end

  def visit? uid
    ((accessed(uid)>>1)&1) == 1
  end
end

class StructReader
  class << self
    alias make_struct_orig_for_dir_fileheader make_struct
    def make_struct name, data
      result = make_struct_orig_for_dir_fileheader name, data

      result.extend(Dir_fileheader_item) if name == 'dir_fileheader'

      return result
    end
  end
end

class Dir_fileheader
  include CStruct
end
