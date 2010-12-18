module CStruct
  module Type
    class StructType
      def initialize info, io
        @info = info
        @io = io
        @offset = io.tell
      end
      def get var_name
        var_info = @info[:member][var_name]
        @io.seek(@offset + var_info[:offset])
        @io.read(var_info[:type][:size]).unpack(var_info[:type][:pack])[0]
      end
      def set var_name, value
        var_info = @info[:member][var_name]
        @io.seek(@offset + var_info[:offset])
        @io.write([value].pack(var_info[:type][:pack]))
      end
    end
  end
end
