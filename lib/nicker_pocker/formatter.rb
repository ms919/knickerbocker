# 整形

module NickerPocker
  class Formatter
    TABLE_HEADER_LIST = %W(table_name #{nil} #{nil} table_name(jp) #{nil} #{nil} created_by created_date updated_by updated_date table_memo)
    COLMN_HEADER_LIST = %W(PK FK index unique type column_name #{nil} null limit default column_name(jp) #{nil} column_memo)

    ADD_METHODS_LIST = %i(create_table)
    UPDATE_METHODS_LIST = %i()
    DELETE_METHODS_LIST = %i()

    class << self
      def exec(groups, options = {})
        new(options).run(groups)
      end
    end

    # options[:target_format]
    def initialize(options)
      @options = options
    end

    # 実行
    #
    # @params [Hash] groups
    # @return [Array]
    def run(groups)
      return [] if groups.length == 0

      # 各関数の処理をする
      formatted_list(groups)
    end

    private

    # 整形した配列を返す
    #
    # @params [Hash] groups
    # @return [Array]
    def formatted_list(groups)
      # temp_formatted_list = []
      formatted_list = []

      MIGRATE_METHODS.each do |method_name|
        groups.each do |table_data|
          formatted_list.push(format(table_data, method_name))
        end
        # formatted_list.push(temp_formatted_list)
      end

      formatted_list
    end

    # 整形処理
    #
    # @params [Array] table_data
    # @params [Symbol] method_name
    # @return [String]
    def format(table_data, method_name)
      formatted_table_list = []
      # テーブル情報
      formatted_table_list.push(TABLE_HEADER_LIST)
      formatted_table_list.push([table_data[0]])

      # カラムヘッダー追加
      formatted_table_list.push(COLMN_HEADER_LIST)

      # メソッドごとの処理
      methods = table_data[1]

      formatted_column_list = add(methods[method_name]) if ADD_METHODS_LIST.include?(method_name)
      # update
      # formatted_column_list = update(formatted_column_list) if UPDATE_METHODS_LIST.include?(method_name)
      # delete
      # delete(formatted_column_list) if DELETE_METHODS_LIST.include?(method_name)
      formatted_table_list.push(*formatted_column_list)
    end

    def add(columns_list)
      result_list = []

      columns_list.each do |column|
        column_data_list = column.split(/\s|,|=>/)
        column_data_list.delete('')

        column_type = column_data_list[0].sub(/^t\./, '')

        if column_type == 'timestamps'
          timestamps_list = get_timestamps(column_data_list[1..])
          result_list.push(*timestamps_list)
          next
        end

        column_name = column_data_list[1]&.sub(/^:/, '')
        column_null, column_limit, column_default, column_comment = get_constraints(column_data_list[2..])

        result_list.push(%W(#{nil} #{nil} #{nil} #{nil} #{column_type} #{column_name} #{nil} #{column_null} #{column_limit} #{column_default} #{column_comment}))
      end

      result_list
    end

    def get_timestamps(timestamps_left_list)
      timestamps_list = []

      column_null, column_limit, column_default, column_comment = get_constraints(timestamps_left_list)

      timestamps_list.push(%W(#{nil} #{nil} #{nil} #{nil} timestamp created_at #{nil} #{column_null} #{column_limit} #{column_default} #{column_comment}))
      timestamps_list.push(%W(#{nil} #{nil} #{nil} #{nil} timestamp updated_at #{nil} #{column_null} #{column_limit} #{column_default} #{column_comment}))
    end

    # 各制約
    #
    # @params [Array] left_list
    def get_constraints(left_list)
      return if left_list.nil? || left_list.empty?

      temp_constraint_list = left_list.map { |column_data| column_data.gsub(/:|'/, '') }
      constraints = temp_constraint_list.each_slice(2).to_h

      %W(#{constraints['null']} #{constraints['limit']} #{constraints['default']} #{constraints['comment']})
    end

    def update
    end

    def delete
    end
  end
end
