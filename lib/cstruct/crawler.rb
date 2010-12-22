require 'lib/cstruct/helper'
require 'yaml'

module CStruct
  class << self
    attr_accessor :include_dirs
    attr_accessor :headers
  end

  # Crawls all struct.
  module Crawler
    module_function

    def all_possible_filenames
      (CStruct::include_dirs||[]).product(CStruct::headers||[]).map do |dir,file|
        File.join(dir,file)
      end
    end
    private :all_possible_filenames

    TYPE_TO_PACK = {
      'char' => 'c',
      'unsigned char' => 'C',
      'short' => 's',
      'unsigned short' => 'S',
      'int' => 'i',
      'unsigned int' => 'I',
      'unsigned' => 'I',
      'time_t' => 'L_',
      'long' => 'l_',
    }
    # Crawl all struct information
    def crawl
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
      all_struct_names = all_structs.map {|struct| struct[0]}

      result = Hash[all_struct_names.map do |struct_name|
        [struct_name,{
          :type => {:name => struct_name,
            :size => Helper.sizeof(struct_name),
            :kind => 'struct'
          },
          :member => {}}]
      end]

      all_members.each do |member|
        if member.any?{|item| item =~ /^struct:(.*)$/}
          struct_name = $1
          member_info = result[struct_name][:member][member[0]] = {}
          member_info[:offset] = Helper.offsetof(struct_name, member[0])
          type = Helper.typeof(struct_name, member[0])
          raise Exception unless type =~ /^(.*?)(?: \[(\d+)\])?$/
          type_name = $1
          count = $2

          if type_name == 'char' and count
            member_info[:type] = {:name => type,
              :size => Helper.sizeof(type),
              :pack => "Z#{count}",
              :kind => 'primary',
            }
            next
          end

          type_info = {:name => type_name,
            :size => Helper.sizeof(type_name),
            :pack => TYPE_TO_PACK[type_name],
            :kind => all_struct_names.include?(type_name) ? 'struct' : 'primary'
          }

          unless count
            member_info[:type] = type_info
            next
          end

          member_info[:type] = {
            :type => type_info,
            :kind => 'array'
          }
          member_info[:count] = count.to_i
        end
      end
      result 
    end

    # Save all crawled struct information
    def save filename
      open(filename,'w') {|f| f << crawl.to_yaml}
    end
  end
end

if __FILE__ == $0
  CStruct.include_dirs = %w[../loco]
  CStruct.headers = %w[bbs.h]
  CStruct::Crawler.save('structures.yml')
end
