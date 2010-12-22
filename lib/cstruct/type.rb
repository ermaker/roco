module CStruct
  module Type
    class ArrayType
      def initialize info, io
        @info = info
        @io = io
        @offset = io.tell
      end
      def get index
        @io.seek(@offset + @info[:type][:type][:size] * index)
        case @info[:type][:type][:kind]
        when 'struct'
          return StructType.new @info[:type], @io
        when 'primary'
          buf = @io.read(@info[:type][:type][:size])
          return buf.unpack(@info[:type][:type][:pack])[0]
        else
          raise Exception
        end
      end
      def [] *args, &blk
        get *args, &blk
      end
      def set index, value
        @io.seek(@offset + @info[:type][:type][:size] * index)
        @io.write([value].pack(@info[:type][:type][:pack]))
      end
      def []= *args, &blk
        set *args, &blk
      end
    end
    class StructType
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

        case var_info[:type][:kind]
        when 'struct'
          return StructType.new var_info, @io
        when 'array'
          return ArrayType.new var_info, @io
        when 'primary'
          buf = @io.read(var_info[:type][:size])
          return buf.unpack(var_info[:type][:pack])[0]
        else
          raise Exception
        end
      end
      def set var_name, value
        var_info = @info[:type][:member][var_name]
        @io.seek(@offset + var_info[:offset])
        @io.write([value].pack(var_info[:type][:pack]))
      end
    end
  end
end
