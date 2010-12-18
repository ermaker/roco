module CStruct
  module Type
    class ArrayType
      def initialize info, io
        @info = info
        @io = io
        @offset = io.tell
      end
      def get index
        @io.seek(@offset + @info[:type][:size] * index)
        buf = @io.read(@info[:type][:size])
        buf.unpack(@info[:type][:pack])[0]
      end
      def set index, value
        @io.seek(@offset + @info[:type][:size] * index)
        @io.write([value].pack(@info[:type][:pack]))
      end
    end
    class StructType
      def initialize info, io
        @info = info
        @io = io
        @offset = io.tell
      end
      def get var_name
        var_info = @info[:member][var_name]
        @io.seek(@offset + var_info[:offset])
        if var_info[:count]
          return ArrayType.new var_info, @io
        end
        buf = @io.read(var_info[:type][:size])
        buf.unpack(var_info[:type][:pack])[0]
      end
      def set var_name, value
        var_info = @info[:member][var_name]
        @io.seek(@offset + var_info[:offset])
        @io.write([value].pack(var_info[:type][:pack]))
      end
    end
  end
end
