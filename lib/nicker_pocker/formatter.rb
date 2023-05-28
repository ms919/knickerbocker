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
      formatted_list = []

      groups.each do |table_data|
        formatted_table_list = []
        MIGRATE_METHODS.each do |method_name|
          temp_formatted_table_list =
            if method_name == :create_table
              create_table_format(table_data)
            # else
              # column_data = table_data[1][method_name]
              # format(column_data, method_name, formatted_table_list) if column_data
            end

          formatted_table_list.push(temp_formatted_table_list).compact!
        end
        formatted_list.push(formatted_table_list)
      end

      formatted_list
    end

    # テーブル作成用に整形した配列を返す
    #
    # @params [Array] table_data
    # @return [Array]
    def create_table_format(table_data)
      formatted_table_list = []
      # テーブル情報
      formatted_table_list.push(TABLE_HEADER_LIST)
      formatted_table_list.push([table_data[0]])

      # カラムヘッダー追加
      formatted_table_list.push(COLMN_HEADER_LIST)

      methods = table_data[1]
      formatted_column_list = create_table(methods[:create_table].first)

      formatted_table_list.push(*formatted_column_list)
    end

    # テーブル作成処理
    #
    # @params [Array] columns_list
    # @return [Array]
    def create_table(columns_list)
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

    # 作成・更新日時カラム追加処理
    #
    # @params [Array] timestamps_left_list
    # @return [Array]
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

    # 整形処理
    #
    # @params [Array] column_data
    # @params [Symbol] method_name
    # @params [Array] formatted_table_list
    # @return [Array]
    def format(column_data, method_name, formatted_table_list)
      if ADD_METHODS_LIST.include?(method_name)
        add(column_data, formatted_table_list)
      elsif UPDATE_METHODS_LIST.include?(method_name)
        update(column_data, formatted_table_list)
      elsif DELETE_METHODS_LIST.include?(method_name)
        delete(column_data, formatted_table_list)
      end
    end

    def add
    end

    def update(column_data, formatted_table_list)
      # p column_data
      # p formatted_table_list
    end

    def delete
    end
  end
end
