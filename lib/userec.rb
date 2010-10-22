require 'cstruct'

class Userec
  include CStruct
  def userid uid
    (self[uid]||{})['userid']
  end
  def uid userid
    result = nil
    if self.find.with_index do |item,idx|
        item['userid'] == userid && result = idx
      end
      return result
    end
  end
end
