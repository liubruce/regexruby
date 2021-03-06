class TreeNode < Hash
  # def initialize(label, children = [])
  #   return {:label => label, :children => children || []}
  # end
  def initialize(label, children = [])
    # @label = label
    # @children = children || []
    self[:label] = label
    self[:children] = children
  end
end

class ParseToTree
  pattern = ''
  pos = 0

  def initialize(regex)
    @pattern = regex
    @pos = 0
    #return expr()
  end

  def nextChar
    ch = peek()
    increasePos(ch)
    return ch
  end

  def expr
    puts 'enter expr'
    trm = term()
    if (hasMoreChars() && peek() == '|')
      increasePos('|')
      exp = expr()
      return TreeNode.new('Expr', [trm, TreeNode.new('|'), exp])
    end

    return TreeNode.new('Expr', [trm])
  end
  def term
    puts 'enter term'
    factr = factor()
    if (hasMoreChars() && peek() != ')' && peek() != '|')
      trm = term()
      return TreeNode.new('Term', [factr, trm])
    end

    return TreeNode.new('Term', [factr])
  end

  def factor
    puts 'enter factor'
    atm = atom()
    if (hasMoreChars() && isMetaChar(peek()))
      meta = nextChar()
      return  TreeNode.new('Factor', [atm, TreeNode.new(meta)])
    end

    return TreeNode.new('Factor', [atm])
  end

  def atom
    puts 'enter atom'
    if (peek() == '(')
      increasePos('(')
      exp = expr()
      increasePos(')')
      return TreeNode.new('Atom', [TreeNode.new('('), exp, TreeNode.new(')')])
    end

    ch = char();
    puts 'char()'
    puts ch
    return TreeNode.new('Atom', [ch])
  end

  def char
    puts 'enter char'
    return TreeNode.new('Char', [TreeNode.new(nextChar())])
  end

  def peek
    @pattern[@pos]
  end

  def isMetaChar(ch)
    ch == '*'
  end

  def hasMoreChars
    @pos < @pattern.length
  end

  def increasePos(ch)
    @pos = @pos + 1
  end
end