require 'rspec'
require 'struct_reader'

describe StructReader do
  before do
    StructReader.load('structures.yml')
  end

  it 'should read userec' do
    data = File.read(File.dirname(__FILE__) + '/fixtures/.PASSWDS')
    userec = StructReader.userec(data)
    userec.sort.should == [
      ["address", ""],
      ["editor_kind", 0],
      ["email", "sysop@loco"],
      ["flags", ""],
      ["lasthost", ""],
      ["lastlogin", nil],
      ["notused", ""],
      ["numlogins", 0],
      ["numposts", 0],
      ["passwd", "Ttk.wSs2SGDfQ"],
      ["protocol", 0],
      ["realname", "real sysop"],
      ["sex", "\263\262"],
      ["termtype", "vt100"],
      ["userid", "SYSOP"],
      ["userlevel", 4294967295],
      ["username", "sysop"]
    ].sort
  end
end
