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

  # Get type of member of struct
  def typeof struct, member

    member_for_function_name = member.dup
    member_for_function_name.gsub!('[', '__square_bracket_begins__')
    member_for_function_name.gsub!(']', '__square_bracket_ends__')

    begin
      method(:"typeof_#{struct}_#{member_for_function_name}")[]
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

  def all_possible_filenames
    (include_dirs||[]).product(headers||[]).map do |dir,file|
      File.join(dir,file)
    end
  end
  private :all_possible_filenames

  # Get all struct information
  def info
    all_items = all_possible_filenames.map do |filename|
      `ctags --fields=-ft+kz -f- "#{filename}"`.split("\n").map do |line|
        items = line.split("\t")
        [items[0], *items.select do |item|
          item =~ /^kind:/ or item =~ /^struct:/
        end]
      end
    end.flatten(1)
    all_structs = all_items.select {|item| item.include?('kind:s')}
    all_members = all_items.select {|item| item.include?('kind:m')}

    result = Hash[all_structs.map do |struct|
      [struct[0],[]]
    end]

    all_members.each do |member|
      if member.any?{|item| item =~ /^struct:(.*)$/}
        result[$1] << [offsetof($1,member[0]), typeof($1,member[0]), member[0]]
      end
    end
    result 
  end
end

if __FILE__ == $0
  require 'yaml'
  StructHelper.include_dirs = %w[../loco]
  StructHelper.headers = %w[bbs.h]
  open('structures.yml','w') {|f| f << StructHelper.info.to_yaml}
end
