module SQLTree::Node

  # The SQLTree::Node::Base class is the superclass for all node
  # types that are used to represent SQL queries.
  #
  # This class implements some helper methods, and enables the
  # SQLTree::Node::NodeType['SQL fragment'] construct to parse SQL
  # queries.
  class Base
    
    def initialize(attributes = {}) # :nodoc:
      attributes.each { |key, value| send(:"#{key}=", value) }
    end

    # Pretty prints this instance for inspection
    def inspect
      "#{self.class.name}[#{self.to_sql}]"
    end

    # Quotes a variable name so that it can be safely used within
    # SQL queries.
    # <tt>name</tt>:: The name of the variable to quote.
    def quote_var(name)
      "#{SQLTree.identifier_quote_char}#{name}#{SQLTree.identifier_quote_char}" # TODO: MySQL style variable quoting
    end

    # Quotes a string so that it can be used safey within an SQL query.
    # <tt>str</tt>:: The string to quote.
    def quote_str(str)
      "'#{str.gsub("'", "''")}'"
    end

    # Registers the children and leafs attributes in the subclass
    def self.inherited(subclass)
      class << subclass; attr_accessor :children, :leafs; end
      subclass.children = []
      subclass.leafs    = []
    end
    
    # Adds another leaf to this node class.
    def self.leaf(name)
      self.leafs << name
      self.send(:attr_accessor, name)
    end
    
    # Adds another child to this node class.
    def self.child(name)
      self.children << name
      self.send(:attr_accessor, name)
    end
    
    # Compares this node with another node, returns true if the nodes are equal.
    def ==(other)
      other.kind_of?(self.class) && equal_children?(other) && equal_leafs?(other)
    end
    
    # Returns true if all children of the current object and the other object are equal.
    def equal_children?(other)
      self.class.children.all? { |child| send(child) == other.send(child) }
    end

    # Returns true if all leaf values of the current object and the other object are equal.
    def equal_leafs?(other)
      self.class.leafs.all? { |leaf| send(leaf) == other.send(leaf) }
    end
    
    # Parses an SQL fragment tree from a stream of tokens.
    #
    # This method should be implemented by each subclass.
    # This method should not be called directly, but the
    # <tt>SQLTree::Node::Subclass#[]</tt> should be called to
    # parse an SQL fragment provided as a string.
    #
    # <tt>tokens</tt>:: the token stream to use for parsing.
    def self.parse(tokens)
      raise 'Only implemented in subclasses!'
    end
    
    def self.parse_list(tokens, item_class = SQLTree::Node::Expression)
      items = [item_class.parse(tokens)]
      while SQLTree::Token::COMMA === tokens.peek
        tokens.consume(SQLTree::Token::COMMA)
        items << item_class.parse(tokens)
      end
      return items
    end

    # Parses a string, expecting it to be parsable to an instance of
    # the current class.
    #
    # This method will construct a new parser that will tokenize the 
    # string, and will then present the stream of tokens to the 
    # <tt>self.parse</tt> method of the current class.
    #
    # <tt>sql</tt>:: The SQL string to parse
    # <tt>options</tt>:: A Hash of options to send to the parser.
    def self.[](sql, options = {})
      parser = SQLTree::Parser.new(sql, options)
      self.parse(parser)
    end
  end
end

require 'sql_tree/node/expression'

require 'sql_tree/node/select_query'
require 'sql_tree/node/select_declaration'
require 'sql_tree/node/table_reference'
require 'sql_tree/node/source'
require 'sql_tree/node/join'
require 'sql_tree/node/ordering'

require 'sql_tree/node/insert_query'
require 'sql_tree/node/update_query'
require 'sql_tree/node/delete_query'
require 'sql_tree/node/set_query'

require 'sql_tree/node/begin_statement'
require 'sql_tree/node/commit_statement'
require 'sql_tree/node/rollback_statement'
