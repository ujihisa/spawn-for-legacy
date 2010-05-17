class SFL
  attr_reader :command, :environment, :argument, :option

  # SFL.new('ls', '-a') becomes
  #   @environment = {}
  #   @command = ['ls', 'ls']
  #   @argument = ['-a']
  #   @option = {}
  def initialize(*cmdandarg)
    raise ArgumentError if cmdandarg.size == 0
    cmdandarg = cmdandarg.dup

    @environment =
      if Hash === cmdandarg.first
        cmdandarg.shift
      else
        {}
      end

    @option =
      if Hash === cmdandarg.last
        cmdandarg.pop
      else
        {}
      end

    if cmdandarg.size == 1
      cmdandarg = cmdandarg.first
      if String === cmdandarg
        cmd, *arg = self.class.parse_command_with_arg(cmdandarg)
        @command = [cmd, cmd]
        @argument = arg
      else
        @command = cmdandarg
        @argument = []
      end
    else
      # 'ls', '.' -> [['ls', 'ls'], '.']
      cmd = cmdandarg.shift
      cmd = (String === cmd) ? [cmd, cmd] : cmd
      @command = cmd
      @argument = cmdandarg
    end
  end

  def run
    fork {
      @environment.each do |k, v|
        ENV[k] = v
      end
      self.class.option_parser(@option).each do |ast|
        self.class.eval_ast ast
      end
      exec(@command, *@argument)
    }
  end

  def ==(o) # Mostly for rspec
    instance_variables.all? do |i|
      i = i[1..-1] # '@a' -> 'a'
      eval "self.#{i} == o.#{i}"
    end
  end

  class << self
    def option_parser(hash)
      mapping = {
        :out => STDOUT,
        :err => STDERR,
      }
      result = []
      chdir = hash.delete(:chdir)
      if chdir
        result[0] = [Dir, :chdir, chdir]
      end
      result += hash.map {|k, v|
        right =
          case v
          when Symbol # :out or :err
            mapping[v]
          when String # filename
            [File, :open, v, 'w']
          when Array # filename with option
            [File, :open, v[0], v[1]]
          when IO
            v
          end

        if Symbol === k
          [[mapping[k], :reopen, right]]
        else
          # assuming k is like [:out, :err]
          raise if k.size > 2
          left1, left2 = *k.map {|i| mapping[i] }
          [
            [left1, :reopen, right],
            [left2, :reopen, left1],
          ]
        end
      }.flatten(1)
      result
    end

    def eval_ast(ast)
      case ast
      when Array
        if ast.size > 2
          eval_ast(ast[0]).send(ast[1], *ast[2..-1].map {|i| eval_ast(i) })
        else
          eval_ast(ast[0]).send(ast[1])
        end
      else
        ast
      end
    end

    def parse_command_with_arg(x)
      in_squote = false
      in_dquote = false
      tmp = ''
      cmdargs = []
      x.strip.split(//).each do |c|
        case c
        when '"'
          if in_dquote
            in_dquote = false
          else
            in_dquote = true
          end
        when "'"
          if in_squote
            in_squote = false
          else
            in_squote = true
          end
        when ' '
          if in_dquote || in_squote
            tmp << ' '
          else
            cmdargs << tmp
            tmp = ''
          end
        else
          tmp << c
        end
      end
      cmdargs << tmp
    end
  end
end

def spawn(*x)
  SFL.new(*x).run
end

def Process.spawn(*x)
  SFL.new(*x).run
end

if RUBY_VERSION <= '1.8.6'
  class Array
    alias orig_flatten flatten

    def flatten(depth = -1)
      if depth < 0
        orig_flatten
      elsif depth == 0
        self
      else
        inject([]) {|m, i|
          Array === i ? m + i : m << i
        }.flatten(depth - 1)
      end
    end
  end
end
