class ParseAs
  
  def initialize(expected_tree)
    @expected_tree = expected_tree
  end 
  
  def matches?(found_tree)
    @found_tree = found_tree.to_tree
    return @found_tree == @expected_tree
  end
  
  def description
    "expected to parse to #{@expected_tree.inspect}"
  end
  
  def failure_message
    " #{@expected_tree.inspect} expected, but found #{@found_tree.inspect}"
  end
  
  def negative_failure_message
    " expected not to be tokenized to #{@expected_tree.inspect}"
  end  
end

def parse_as(tree)
  ParseAs.new(tree)
end

class TokenizeTo
  
  def initialize(expected_tokens)
    @expected_tokens = expected_tokens.map do |t|
      case t
        when SQLTree::Token then t
        when String         then SQLTree::Token::String.new(t)
        when Numeric        then SQLTree::Token::Number.new(t)
        when Symbol         then SQLTree::Token.const_get(t.to_s.upcase)
        else "Cannot check for this token: #{t.inspect}!"
      end
    end
  end
  
  def matches?(found_tokens)
    @found_tokens = found_tokens
    return @found_tokens == @expected_tokens
  end
  
  def description
    "expected to tokenized to #{@expected_tokens.inspect}"
  end
  
  def failure_message
    " #{@expected_tokens.inspect} expected, but found #{@found_tokens.inspect}"
  end
  
  def negative_failure_message
    " expected not to be tokenized to #{@expected_tokens.inspect}"
  end  
  
end

def tokenize_to(*expected_tokens)
  TokenizeTo.new(expected_tokens)
end

def sql_var(name)
  SQLTree::Token::Variable.new(name.to_s)
end

def dot
  SQLTree::Token::DOT
end

def comma
  SQLTree::Token::COMMA
end

def lparen
  SQLTree::Token::LPAREN
end

def rparen
  SQLTree::Token::RPAREN
end