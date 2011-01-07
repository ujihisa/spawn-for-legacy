$: << File.dirname(__FILE__) + '/../lib'
require 'sfl'
require 'tempfile'

describe 'SFL.new' do
  context 'with argument "ls", "."' do
    subject { SFL.new('ls', '.') }
    it { should == SFL.new('ls', '.') }
    it { should == SFL.new(['ls', 'ls'], '.') }
    it { should_not == SFL.new('ls', 'aaaaa') }
    it { should == SFL.new({}, 'ls', '.') }
    it { should == SFL.new({}, 'ls', '.', {}) }
    it { should_not == SFL.new({1=>2}, 'ls', '.', {}) }
  end

  context 'with argument {"A" => "1"}, ["ls", "dir"]' do
    subject { SFL.new({"A" => "1"}, ['ls', 'dir']) }
    it { should == SFL.new({"A" => "1"}, ['ls', 'dir']) }
    it { should == SFL.new({"A" => "1"}, ['ls', 'dir'], {}) }
    it { should_not == SFL.new({"A" => "1"}, 'ls', 'dir', {}) }
    it { should_not == SFL.new(['ls', 'ls']) }
  end

  context 'with argument {"A" => "a"}, "ls", ".", {:out => :err}' do
    subject { SFL.new({"A" => "a"}, "ls", ".", {:out => :err}) }
    it { should == SFL.new({"A" => "a"}, ['ls', 'ls'], '.', {:out => :err}) }
  end

  context 'with argument "ls ."' do
    subject { SFL.new('ls .') }
    it { should == SFL.new('ls .') }
    it { should == SFL.new('ls', '.') }
    it { should == SFL.new(['ls', 'ls'], '.') }
  end
end

describe 'SFL#run' do
  def mocker(code)
    sfl_expanded = File.expand_path('../../lib/sfl', __FILE__)
    rubyfile = Tempfile.new('-').path
    File.open(rubyfile, 'w') {|io| io.puts <<-"EOF"
        require '#{sfl_expanded}'
      #{code}
      EOF
    }
    resultfile = Tempfile.new('-').path
    system "ruby #{rubyfile} > #{resultfile}"
    File.read(resultfile)
  end

  context 'with command "ls", "."' do
    it 'outputs the result of "ls ." on stdout' do
      mocker(%q|
        pid = SFL.new('ls', '.').run
        Process.wait(pid)
        |).should == `ls`
    end
  end

  it 'is asynchronous' do
    mocker(%q|
      SFL.new('sh', '-c', 'echo 1; sleep 1; echo 2').run
      sleep 0.1
      |).should == "1\n"
  end

  context 'with environment {"A" => "1"}' do
    it 'outputs with given ENV "1"' do
      mocker(%q|
        pid = SFL.new({'A' => 'a'}, 'ruby', '-e', 'p ENV["A"]').run
        Process.wait(pid)
        |).should == "a".inspect + "\n"
    end
  end

  context 'with option {:err => :out}' do
    it 'outputs with given ENV "1"' do
      mocker(
        %q|
        pid = SFL.new('ls', 'nonexistfile', {:err => :out}).run
        Process.wait(pid)
        |).should == "ls: nonexistfile: No such file or directory\n"
    end
  end

  context 'with option {:out => "/tmp/aaaaaaa.txt"}' do
    it 'outputs with given ENV "1"' do
      mocker(
        %q|
        pid = SFL.new('echo', '123', {:out => "/tmp/aaaaaaa.txt"}).run
        Process.wait(pid)
        |).should == ""
      File.read('/tmp/aaaaaaa.txt').should == "123\n"
    end
  end
end

describe 'SFL.option_parser' do
  it 'with symbol arguments' do
    SFL.option_parser({:err => :out}).
      should == [[STDERR, :reopen, STDOUT]]

    SFL.option_parser({:err => 'filename'}).
      should == [[STDERR, :reopen, [File, :open, 'filename', 'w']]]

    o = File.open('/dev/null', 'w')
    SFL.option_parser({:out => o}).
      should == [[STDOUT, :reopen, o]]

    SFL.option_parser({[:out, :err] => 'filename'}).
      should == [
        [STDOUT, :reopen, [File, :open, 'filename', 'w'] ],
        [STDERR, :reopen, STDOUT]
      ]

    SFL.option_parser({:chdir => 'aaa'}).
      should == [[Dir, :chdir, 'aaa']]

    SFL.option_parser({:err => :out, :chdir => 'aaa'}).
      should == [
        [Dir, :chdir, 'aaa'],
        [STDERR, :reopen, STDOUT]
      ]
  end
end

describe 'SFL.parse_command_with_arg' do
  context 'ls .' do
    subject { SFL.parse_command_with_arg('ls .') }
    it { should == ['ls', '.'] }
  end

  context 'ls " "' do
    subject { SFL.parse_command_with_arg('ls " "') }
    it { should == ['ls', ' '] }
  end
end

describe 'spawn()' do
  it 'exists' do
    Kernel.should be_respond_to(:spawn, true)
    Process.should be_respond_to(:spawn, true)
  end
end
