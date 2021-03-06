require "./parse.rb"

class RegEx
  def findBracket(array)
     left = []
     right = []
     idx = array.index('(')
    while (idx != nil)
      left.push(idx)
      idx = array.index('(', idx + 1)
      puts idx
    end

    idx = array.index(')')
    while (idx != nil)
      right.push(idx)
      idx = array.index(')', idx + 1)
    end
    if (left.length == right.length)
      if (left.length > 1 && left[1] < right[0])
        return right[right.length-1];
      else
         return array.index(')')
      end
    else
         return -1
    end
  end

  def initParseExp(pattern)
    if pattern == ")" || pattern == "*" then
      return 'SYNTAX ERROR'
    end

    if pattern.index(")") != nil || pattern.index("(") != nil
      groupEnd = findBracket(pattern)
      if groupEnd == -1
        return 'SYNTAX ERROR'
      end
    end
    starIndex = pattern.index("*")
    if starIndex == 0 then
      return 'SYNTAX ERROR'
    end
    if starIndex==0
      if pattern[starIndex-1] == '|' || pattern[starIndex-1] == ']' || pattern[starIndex-1] == '(' then
        return 'SYNTAX ERROR'
      end
    end
    if pattern.index("\\(") != nil then
      return 'SYNTAX ERROR'
    end
    return 0
  end

  def parseReg(exp, target)
    result = initParseExp(exp)
    puts result
    if result == 0 then
      puts exp
      nfa = toNFAFromInfixExp(exp)
      puts 'nfa'
      puts nfa
      return matchTarget(nfa, target)
    end
  end

  def concatExp(first, second)
    addEpsilonTransition(first[:end], second[:start])
    first[:end][:isEnd] = false
    return { start: first[:start], end: second[:end] }
  end

  def unionExp(first, second)
    start = createState(false)
    addEpsilonTransition(start, first.start)
    addEpsilonTransition(start, second.start)
    endState = createState(true)
    addEpsilonTransition(first[:end], endState)
    first[:end][:isEnd] = false
    addEpsilonTransition(second[:end], endState)
    second[:end][:isEnd] = false
    return { start: start, end: endState }
  end

  def closure(nfa)
    start = createState(false)
    endState = createState(true)
    addEpsilonTransition(start, endState)
    addEpsilonTransition(start, nfa[:start])
    addEpsilonTransition(nfa[:end], endState)
    addEpsilonTransition(nfa[:end], nfa[:start])
    nfa[:end][:isEnd] = false
    return { start: start, end: endState }
  end

  def addNextState(state, nextStates, visited)
    puts 'enter addNextState = ', nextStates
    if (state[:epsilonTransitions].length > 0)
      state[:epsilonTransitions].each do
        |st|
        if (!visited.include?(st))
          visited.push(st)
          addNextState(st, nextStates, visited)
        end
      end
    else
      nextStates.push(state)
    end
    puts 'addNextState = ', nextStates
  end


  def searchTree (nfa, word)
    currentStates = []
    addNextState(nfa[:start], currentStates, [])
    puts 'currentStates=001 ', currentStates, currentStates.length
    chars = word.split('')
    chars.each { |symbol|
      puts ' symbol ', symbol
      nextStates = []
      currentStates.each {
        |state|
        puts ' state = ', state
        nextState = state[:transition][symbol] || state[:transition]['.']
        if nextState
          addNextState(nextState, nextStates, [])
        end
      }
      currentStates = nextStates
    }
    puts 'currentStates= 002 ', currentStates, currentStates.length
    currentStates.each {
      |state|
      if state[:isEnd]
        return true
      end
    }
    return false
  end

  def matchTarget(nfa, target)
    searchTree(nfa, target)
  end

  def toNFAFromInfixExp(exp)
    if (exp == '')
      return fromEpsilon()
    end
    parseTree = ParseToTree.new(exp)
    expr = parseTree.expr()
    puts 'expr'
    puts expr
    return toNFAfromParseTree(expr)
  end

  def toNFAfromParseTree(root)
    puts 'enter toNFAfromParseTree'
    puts root
    if (root[:label] == 'Expr')
      term = toNFAfromParseTree(root[:children][0])
      if (root[:children].length == 3)
        return unionExp(term, toNFAfromParseTree(root[:children][2]));
      end
      return term #// Expr -> Term
    end

    if (root[:label] == 'Term')
      factor = toNFAfromParseTree(root[:children][0])
      if (root[:children].length == 2) then #// Term -> Factor Term
      return concatExp(factor, toNFAfromParseTree(root[:children][1]));
      end
      return factor # // Term -> Factor
    end

    if (root[:label] == 'Factor')
      atom = toNFAfromParseTree(root[:children][0]);
      if (root[:children].length == 2) #{ // Factor -> Atom MetaChar
        meta = root[:children][1][:label]
      end
      if (meta == '*')
        return closure(atom)
        #// if (meta === '?')
        #//     return zeroOrOne(atom);
      end

      return atom # // Factor -> Atom
    end

    if (root[:label] == 'Atom')
      if (root[:children].length == 3) #// Atom -> '(' Expr ')'
        return toNFAfromParseTree(root[:children][1])
      end
      return toNFAfromParseTree(root[:children][0]) #; // Atom -> Char

    end

    if (root[:label] == 'Char')
      if (root[:children].length == 2) #// Char -> '\' AnyChar
        return fromSymbol(root[:children][1][:label])
      end
      return fromSymbol(root[:children][0][:label]) # Char -> AnyCharExceptMeta
    end
    # throw new Error('Unrecognized node label ' + root.label);
  end

  def fromSymbol(symbol)
    start = createState(false)
    endState = createState(true)
    addTransition(start, endState, symbol)
    return { start: start, end: endState }
  end

  def addTransition(from, to, symbol)
    from[:transition][symbol] = to;
  end

  def fromEpsilon
    startState = createState(false)
    endState = createState(true)
    addEpsilonTransition(startState, endState)
    return { start: startState, end: endState }
  end

  def addEpsilonTransition(from = {}, to = {})
    from[:epsilonTransitions].push(to)
  end

  def createState(state)
    return {
      isEnd: state,
      transition: {},
      epsilonTransitions: []
    }
  end

end
