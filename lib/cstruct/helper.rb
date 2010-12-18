require 'rubygems'
require 'inline'

module CStruct
  class << self
    attr_accessor :include_dirs
    attr_accessor :headers
  end
    
  # Helper to get informations of struct
  module Helper
    module_function

    # Generate a safe function name
    def to_function_name name
      result = name.dup
      result.gsub!(' ', '__space_exists__')
      result.gsub!(',', '__comma_exists__')
      result.gsub!('*', '__star_exists__')
      result.gsub!('[', '__square_bracket_begins__')
      result.gsub!(']', '__square_bracket_ends__')
      result.gsub!('(', '__brace_begins__')
      result.gsub!(')', '__brace_ends__')
      result
    end
    private :to_function_name

    # Get size of struct
    def sizeof struct
      struct_for_function_name = to_function_name struct

      begin
        method(:"sizeof_#{struct_for_function_name}")[]
      rescue NameError
        inline do |builder|
          builder.add_link_flags '-lstdc++'
          builder.add_compile_flags '-xc++'
          CStruct::include_dirs.each do |include_dir|
            builder.add_compile_flags "-I#{include_dir}"
          end
          CStruct::headers.each do |header|
            builder.include %{"#{header}"}
          end
          builder.c <<-EOC
            int sizeof_#{struct_for_function_name}()
            {
              return sizeof(#{struct});
            }
          EOC
        end
        module_function :"sizeof_#{struct_for_function_name}"
        retry
      end
    end

    # Get offset of member of struct
    def offsetof struct, member
      member_for_function_name = to_function_name member

      begin
        method(:"offsetof_#{struct}_#{member_for_function_name}")[]
      rescue NameError
        inline do |builder|
          builder.add_link_flags '-lstdc++'
          builder.add_compile_flags '-xc++'
          CStruct::include_dirs.each do |include_dir|
            builder.add_compile_flags "-I#{include_dir}"
          end
          CStruct::headers.each do |header|
            builder.include %{"#{header}"}
          end
          builder.c <<-EOC
            int offsetof_#{struct}_#{member_for_function_name}()
            {
              return offsetof(#{struct}, #{member});
            }
          EOC
        end
        module_function :"offsetof_#{struct}_#{member_for_function_name}"
        retry
      end
    end

    # Get count of member of struct
    def countof struct, member

      begin
        method(:"countof_#{struct}_#{member}")[]
      rescue NameError
        inline do |builder|
          builder.add_link_flags '-lstdc++'
          builder.add_compile_flags '-xc++'
          CStruct::include_dirs.each do |include_dir|
            builder.add_compile_flags "-I#{include_dir}"
          end
          CStruct::headers.each do |header|
            builder.include %{"#{header}"}
          end
          builder.prefix <<-EOC
#define COUNTOF_REAL(_Array) (sizeof(_Array) / sizeof(_Array[0]))

#define   COUNTOF(con,mem)  _COUNTOF(con,mem)
#define  _COUNTOF(con,mem) __COUNTOF(con,mem)
#define __COUNTOF(con,mem) COUNTOF_REAL(((con*)0)->mem)
          EOC
          builder.c <<-EOC
            int countof_#{struct}_#{member}()
            {
              return COUNTOF(#{struct}, #{member});
            }
          EOC
        end
        module_function :"countof_#{struct}_#{member}"
        retry
      end
    end

    # Get type of member of struct
    def typeof struct, member
      member_for_function_name = to_function_name member

      begin
        method(:"typeof_#{struct}_#{member_for_function_name}")[]
      rescue NameError
        inline do |builder|
          builder.add_link_flags '-lstdc++'
          builder.add_compile_flags '-xc++'
          CStruct::include_dirs.each do |include_dir|
            builder.add_compile_flags "-I#{include_dir}"
          end
          CStruct::headers.each do |header|
            builder.include %{"#{header}"}
          end
          builder.include '<typeinfo>'
          builder.include '<cxxabi.h>'
          builder.c <<-EOC
            VALUE typeof_#{struct}_#{member_for_function_name}()
            {
              char* p = abi::__cxa_demangle(typeid(((#{struct}*)0)->#{member}).name(), 0, 0, 0);
              if(!p)
                return Qnil;
              VALUE retval = rb_str_new2(p);
              free(p);
              return retval;
            }
          EOC
        end
        module_function :"typeof_#{struct}_#{member_for_function_name}"
        retry
      end
    end
  end
end
