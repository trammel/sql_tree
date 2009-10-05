module SQLTree::Node

  # Base class for all SQL expressions.
  #
  # This is an asbtract class and should not be used directly. Use
  # one of the subclasses instead.
  class Expression < Base
  
    def self.parse(parser)
      SQLTree::Node::LogicalExpression.parse(parser)
    end
    
    def self.parse_single(parser)
      if SQLTree::Token::LPAREN == parser.peek_token
        parser.consume(SQLTree::Token::LPAREN)
        expr = self.parse(parser)
        parser.consume(SQLTree::Token::RPAREN)
        return expr
      elsif SQLTree::Token::Variable === parser.peek_token(1)  && parser.peek_token(2) == SQLTree::Token::LPAREN
        return SQLTree::Node::FunctionExpression.parse(parser)  
      elsif SQLTree::Token::Variable === parser.peek_token
        return SQLTree::Node::Variable.parse(parser)
      else
        return SQLTree::Node::Value.parse(parser)
      end      
    end
  end

  class LogicalExpression < Expression
    attr_accessor :operator, :expressions

    def initialize(operator, expressions)
      @expressions = expressions
      @operator    = operator.to_s.downcase.to_sym
    end

    def to_sql
      "(" + @expressions.map { |e| e.to_sql }.join(" #{@operator.to_s.upcase} ") + ")"
    end

    def to_tree
      [@operator] + @expressions.map { |e| e.to_tree }
    end
    
    def self.parse(parser)
      expr = ComparisonExpression.parse(parser)
      while [SQLTree::Token::AND, SQLTree::Token::OR].include?(parser.peek_token)
        expr = SQLTree::Node::LogicalExpression.new(parser.next_token.literal, [expr, ComparisonExpression.parse(parser)])
      end 
      return expr      
    end
  end

  class ComparisonExpression < Expression
    attr_accessor :lhs, :rhs, :operator
    
    def initialize(operator, lhs, rhs)
      @lhs = lhs
      @rhs = rhs
      @operator = operator
    end
    
    def to_sql
      "(#{@lhs.to_sql} #{@operator} #{@rhs.to_sql})"
    end
    
    def to_tree
      [SQLTree::Token::OPERATORS[@operator], @lhs.to_tree, @rhs.to_tree]
    end
    
    def self.parse(parser)
      expr = SQLTree::Node::ArithmeticExpression.parse(parser)
      while SQLTree::Token::LOGICAL_OPERATORS.include?(parser.peek_token)
        expr = self.new(parser.next_token.literal, expr, SQLTree::Node::ArithmeticExpression.parse(parser))
      end
      return expr      
    end
  end
  
  class FunctionExpression < Expression
    attr_accessor :function, :arguments
    
    def initialize(function, arguments = [])
      @function = function
      @arguments = arguments
    end
    
    def to_sql
      "#{@function}(" + @arguments.map { |e| e.to_sql }.join(', ') + ")"
    end
    
    def to_tree
      [@function.to_sym] + @arguments.map { |e| e.to_tree }
    end
    
    def self.parse(parser)
      expr = self.new(parser.next_token.literal)
      parser.consume(SQLTree::Token::LPAREN)
      until parser.peek_token == SQLTree::Token::RPAREN
        expr.arguments << SQLTree::Node::Expression.parse(parser)
        parser.consume(SQLTree::Token::COMMA) if parser.peek_token == SQLTree::Token::COMMA
      end
      parser.consume(SQLTree::Token::RPAREN)
      return expr      
    end
  end
  
  class ArithmeticExpression < Expression
    attr_accessor :lhs, :rhs, :operator
    
    def initialize(operator, lhs, rhs)
      @lhs = lhs
      @rhs = rhs
      @operator = operator
    end
    
    def to_sql
      "(#{@lhs.to_sql} #{@operator} #{@rhs.to_sql})"
    end
    
    def to_tree
      [SQLTree::Token::OPERATORS[@operator], @lhs.to_tree, @rhs.to_tree]
    end
    
    def self.parse(parser)
      self.parse_primary(parser)
    end
    
    def self.parse_primary(parser)
      expr = self.parse_secondary(parser)
      while [SQLTree::Token::PLUS, SQLTree::Token::MINUS].include?(parser.peek_token)
        expr = self.new(parser.next_token.literal, expr, self.parse_secondary(parser))
      end
      return expr
    end
    
    def self.parse_secondary(parser)
      expr = Expression.parse_single(parser)
      while [SQLTree::Token::PLUS, SQLTree::Token::MINUS].include?(parser.peek_token)
        expr = self.new(parser.next_token.literal, expr, SQLTree::Node::Expression.parse_single(parser))
      end
      return expr
    end
  end
end
