require 'lib/cstruct/helper'

module CStruct
  # Crawls all struct.
  module Crawler

    class << self
      attr_accessor :include_dirs
      attr_accessor :headers
    end
    
    module_function

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
        [struct[0],[Helper.sizeof(struct[0])]]
      end]

      all_members.each do |member|
        if member.any?{|item| item =~ /^struct:(.*)$/}
          result[$1] << [Helper.offsetof($1,member[0]), Helper.typeof($1,member[0]), member[0]]
        end
      end
      result 
    end
  end
end

if __FILE__ == $0
  require 'yaml'
  CStruct::Helper.include_dirs = %w[../loco]
  CStruct::Helper.headers = %w[bbs.h]
  CStruct::Crawler.include_dirs = %w[../loco]
  CStruct::Crawler.headers = %w[bbs.h]
  open('structures.yml','w') {|f| f << CStruct::Crawler.info.to_yaml}
end
