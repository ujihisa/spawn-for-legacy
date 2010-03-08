class SFL
  attr_reader :command, :environment, :argument, :option

  def initialize(*cmdandarg)
    raise ArgumentError if cmdandarg.size == 0
    cmdandarg = cmdandarg.dup

    tmp = cmdandarg.shift
    if Hash === tmp
      @environment = tmp
      tmp = cmdandarg.shift
    else
      @environment = {}
    end

    if String === tmp
      @command = [tmp, tmp]
    else
      @command = tmp
    end

    if Hash === cmdandarg.last
      @option = cmdandarg.pop
    else
      @option = {}
    end

    @argument = cmdandarg
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
  end
end

if RUBY_VERSION < '1.9'
  def spawn(*x)
    SFL.new(*x).run
  end

  def Process.spawn(*x)
    SFL.new(*x).run
  end
end
