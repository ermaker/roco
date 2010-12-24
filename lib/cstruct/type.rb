module CStruct
  module Type
    class SuperType
      def get info
        case info[:type][:kind]
        when 'struct'
          return StructType.new info, @io
        when 'array'
          return ArrayType.new info, @io
        when 'primary'
          buf = @io.read(info[:type][:size])
          return buf.unpack(info[:type][:pack])[0]
        else
          raise Exception
        end
      end
      def set info, value
        @io.write([value].pack(info[:type][:pack]))
      end
    end
    class ArrayType < SuperType
      def initialize info, io
        @info = info
        @io = io
        @offset = io.tell
      end
      def get index
        @io.seek(@offset + @info[:type][:type][:size] * index)
        return super(@info[:type])
      end
      def [] *args, &blk
        get *args, &blk
      end
      def set index, value
        @io.seek(@offset + @info[:type][:type][:size] * index)
        super(@info[:type], value)
      end
      def []= *args, &blk
        set *args, &blk
      end
    end
    class StructType < SuperType
      def initialize info, io
        @info = info
        @io = io
        @offset = io.tell
      end
      alias method_missing_orig method_missing
      def method_missing symbol, *args, &blk
        return get(symbol.to_s) if @info[:type][:member][symbol.to_s]
        return set(symbol.to_s[0..-2], *args) if symbol.to_s =~ /=$/ and @info[:type][:member][symbol.to_s[0..-2]]
        return method_missing_orig symbol, *args, &blk
      end
      def get var_name
        var_info = @info[:type][:member][var_name]
        @io.seek(@offset + var_info[:offset])
        return super(var_info)
      end
      def set var_name, value
        var_info = @info[:type][:member][var_name]
        @io.seek(@offset + var_info[:offset])
        super(var_info, value)
      end
    end
  end
end
