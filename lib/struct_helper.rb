# StructHelper class
require 'rubygems'
require 'inline'

# Helper to get informations of struct
module StructHelper

  class << self
    attr_accessor :include_dirs
    attr_accessor :headers
  end
  
  module_function

  # Get size of struct
  def sizeof struct

    begin
      method(:"sizeof_#{struct}")[]
    rescue NameError
      inline do |builder|
        builder.add_link_flags '-lstdc++'
        builder.add_compile_flags '-xc++'
        include_dirs.each do |include_dir|
          builder.add_compile_flags "-I#{include_dir}"
        end
        headers.each do |header|
          builder.include %{"#{header}"}
        end
        builder.c <<-EOC
          int sizeof_#{struct}()
          {
            return sizeof(#{struct});
          }
        EOC
      end
      module_function :"sizeof_#{struct}"
      retry
    end
  end

  # Get offset of member of struct
  def offsetof struct, member

    member_for_function_name = member.dup
    member_for_function_name.gsub!('[', '__square_bracket_begins__')
    member_for_function_name.gsub!(']', '__square_bracket_ends__')

    begin
      method(:"offsetof_#{struct}_#{member_for_function_name}")[]
    rescue NameError
      inline do |builder|
        builder.add_link_flags '-lstdc++'
        builder.add_compile_flags '-xc++'
        include_dirs.each do |include_dir|
          builder.add_compile_flags "-I#{include_dir}"
        end
        headers.each do |header|
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
        include_dirs.each do |include_dir|
          builder.add_compile_flags "-I#{include_dir}"
        end
        headers.each do |header|
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

end
