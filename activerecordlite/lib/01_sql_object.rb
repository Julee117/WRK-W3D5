require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @column ||= (DBConnection.execute2(<<-SQL).first.map(&:to_sym)
  SELECT
    *
  FROM
    #{self.table_name}
SQL
)
@column
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end

      define_method((col.to_s + "=").to_sym) do |val|
        self.attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
     @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    results = (DBConnection.execute(<<-SQL)
    SELECT
      #{self.table_name}.*
    FROM
      #{self.table_name}
    SQL
  )
  parse_all(results)
  end

  def self.parse_all(results)
    results.map { |res| self.new(res) }
  end

  def self.find(id)

    result = (DBConnection.execute(<<-SQL, id)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE
      #{table_name}.id = ?
    SQL
  )
  parse_all(result).first
  end

  def initialize(params = {})
    params.each do |key, val|
      set = key.to_s + "="
      unless self.class.columns.include?(key.to_sym)
        raise "unknown attribute '#{key}'"
      else
       send(set.to_sym, val)
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |x| self.send(x) }
  end

  def insert
    dropped_column = self.class.columns.drop(1)
    col_names = dropped_column.map(&:to_s).join(", ")
    question_marks = (["?"] * dropped_column.count).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    DBConnection.execute(<<-SQL)
    UPDATE
      #{self.class.table_name}
    SET
      
  end

  def save
    # ...
  end
end
