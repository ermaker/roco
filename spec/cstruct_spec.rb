require 'rspec'
require 'cstruct'

describe CStruct do
  before do
    StructReader.load('structures.yml')
    @userec = Userec.new('../loco/.PASSWDS')
    @users = [
      {"realname"=>"real sysop",
        "flags"=>"",
        "address"=>"",
        "lasthost"=>"",
        "username"=>"sysop",
        "termtype"=>"vt100",
        "protocol"=>0,
        "userlevel"=>4294967295,
        "numlogins"=>1,
        "userid"=>"SYSOP",
        "sex"=>"\263\262",
        "numposts"=>0,
        "lastlogin"=>nil,
        "notused"=>"",
        "passwd"=>"Ttk.wSs2SGDfQ",
        "email"=>"sysop@loco",
        "editor_kind"=>0,
      },
      {"realname"=>"real1",
        "flags"=>"",
        "address"=>"",
        "lasthost"=>"",
        "username"=>"nick1",
        "termtype"=>"vt100",
        "protocol"=>0,
        "userlevel"=>15,
        "numlogins"=>0,
        "userid"=>"user1",
        "sex"=>"\277\251",
        "numposts"=>0,
        "lastlogin"=>nil,
        "notused"=>"",
        "passwd"=>"pz2WjJfrXbKao",
        "email"=>"user1",
        "editor_kind"=>0,
      },
      {"realname"=>"real2",
        "flags"=>"",
        "address"=>"",
        "lasthost"=>"",
        "username"=>"nick2",
        "termtype"=>"vt100",
        "protocol"=>0,
        "userlevel"=>15,
        "numlogins"=>0,
        "userid"=>"user2",
        "sex"=>"\263\262",
        "numposts"=>0,
        "lastlogin"=>nil,
        "notused"=>"",
        "passwd"=>"E.pPaINDsryEw",
        "email"=>"email2",
        "editor_kind"=>0,
      },
    ]
  end

  it 'should change to array' do
    @userec.to_a.should == @users
  end
end
