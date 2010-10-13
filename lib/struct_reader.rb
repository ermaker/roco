require 'struct_helper'
require 'yaml'

class StructReader
  class << self
    def load filename
      @@structures = YAML::load(File.read(filename))
    end
    alias orig_method_missing method_missing
    def method_missing(sym, *args, &block)
      orig_method_missing sym, *args, &block unless @@structures[sym.to_s]
      make_struct sym.to_s, args[0]
    end

    TYPE_TO_PACKCHAR = {
      'char' => 'c',
      'unsigned char' => 'C',
      'int' => 'i',
      'unsigned int' => 'I',
      'unsigned' => 'I',
      'time_t' => 'L_',
    }

    def make_struct name, data
      result = {}
      @@structures[name][1..-1].each do |item|
        item[1] =~ /^(.*?)(?: \[(\d+)\])?$/
        # FIXME: bug with char [] if it is not a string.
        pack_string = if $1 == 'char' && $2
          "@#{item[0]}Z#$2"
        else

          "@#{item[0]}#{TYPE_TO_PACKCHAR[$1]}#$2"
        end
        value = data.unpack(pack_string)[0]
        result[item[2]] = value
      end
      result
    end
  end
end
