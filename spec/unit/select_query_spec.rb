require "#{File.dirname(__FILE__)}/../spec_helper"

describe SQLTree::Node::Source do

  it "should parse the table name correctly" do
    SQLTree::Node::Source['table AS a'].table.should == 'table'
  end

  it "should parse the alias correctly when using the AS keyword" do
    SQLTree::Node::Source['table AS a'].table_alias.should == 'a'
  end

  it "should not require the AS keyword for a table alias" do
    SQLTree::Node::Source['table AS a'].should == SQLTree::Node::Source['table a']
  end

  it "should parse a table name without alias" do
    SQLTree::Node::Source['table'].table.should == "table"
    SQLTree::Node::Source['table'].table_alias.should be_nil
  end

  it "should have no joins" do
    SQLTree::Node::Source['table'].joins.should be_empty
  end
end

describe SQLTree::Node::Join do

  it "should parse a join table" do
    SQLTree::Node::Join['LEFT JOIN table ON other.field = table.field'].table.should == 'table'
  end
  
  it "should parse the join type" do
    SQLTree::Node::Join['LEFT JOIN table ON other.field = table.field'].join_type.should == :left
  end
  
  it "should parse the join expression" do
    SQLTree::Node::Join['LEFT JOIN table ON other.field = table.field'].join_expression.should be_kind_of(SQLTree::Node::Expression)
  end
  
  it "should not parse a table alias" do
    SQLTree::Node::Join['LEFT JOIN table ON other.field = table.field'].table_alias.should be_nil
  end  
  
  it "should parse a table alias with AS" do
    SQLTree::Node::Join['LEFT JOIN table AS t ON other.field = table.field'].table_alias.should == 't'
  end
  
  it "should parse a table alias without AS" do
    SQLTree::Node::Join['LEFT JOIN table t ON other.field = table.field'].table_alias.should == 't'
  end
end

describe SQLTree::Node::Ordering do
  it "should parse an ordering with direction" do
    ordering = SQLTree::Node::Ordering["table.field ASC"]
    ordering.expression.table.should == 'table'
    ordering.expression.name.should  == 'field'
    ordering.direction.should == :asc
  end
  
  it "should parse an ordering without direction" do
    ordering = SQLTree::Node::Ordering["table.field"]
    ordering.expression.table.should == 'table'
    ordering.expression.name.should  == 'field'
    ordering.direction.should be_nil
  end
  
  it "should parse an ordering without direction" do
    ordering = SQLTree::Node::Ordering["MD5(3 + 6) DESC"]
    ordering.expression.should be_kind_of(SQLTree::Node::FunctionExpression)
    ordering.direction.should == :desc
  end
  
  it "shoulde parse multiple orderings" do
    tree = SQLTree['SELECT * FROM table ORDER BY field1 ASC, field2 DESC']
    tree.order_by.should have(2).items
    tree.order_by[0].direction.should == :asc
    tree.order_by[1].direction.should == :desc
  end
end
