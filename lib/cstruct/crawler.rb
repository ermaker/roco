require 'lib/cstruct/helper'

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
        [struct[0],{:size => Helper.sizeof(struct[0]), :member => {}}]
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
          member_info[:type] = {:name => type_name,
            :size => Helper.sizeof(type_name)}
          member_info[:count] = count.to_i if count
        end
      end
      result 
    end
  end
end

if __FILE__ == $0
  require 'yaml'
  CStruct.include_dirs = %w[../loco]
  CStruct.headers = %w[bbs.h]
  open('structures.yml','w') {|f| f << CStruct::Crawler.info.to_yaml}
end
