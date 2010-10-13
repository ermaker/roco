require 'struct_helper'

Then /^struct information of (\w+) is (.*).$/ do |name,expected|
  StructHelper.info(name).to_s.should == expected
end
