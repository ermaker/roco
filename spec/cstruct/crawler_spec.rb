require 'rspec'
require 'cstruct/crawler'

describe CStruct::Crawler do
  before do
    CStruct.include_dirs = [File.dirname(__FILE__) + '/../fixtures']
    CStruct.headers = %w[simple_struct.h]
  end

  it 'should crawl all struct information' do
    CStruct::Crawler.crawl.should == {
      "simple_struct_char_array" => {
        :size => 0,
        :member => {
          "simple_char_array" => {:offset => 0,
            :type => {:name => "char [0]", :size => 0, :pack => 'Z0'}},
        }
      },
      "simple_struct_int" => {
        :size => 4,
        :member => {
          "simple_int" => {:offset => 0,
            :type => {:name => "int", :size => 4, :pack => 'i'}},
        }
      },
      "simple_struct_int2" => {
        :size => 8,
        :member => {
          "simple_int1" => {:offset => 0,
            :type => {:name => "int", :size => 4, :pack => 'i'}},
          "simple_int2" => {:offset => 4,
            :type => {:name => "int", :size => 4, :pack => 'i'}},
        }
      },
      "simple_struct_int_array" => {
        :size => 12,
        :member => {
          "simple_int_array" => {:offset => 0,
            :type => {:name => "int", :size => 4, :pack => 'i'},
            :count => 3},
        }
      },
    }
  end
end
