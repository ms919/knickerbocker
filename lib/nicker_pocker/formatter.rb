# 整形

module NickerPocker
  class Formatter
    TABLE_HEADER_LIST = %w(table_name  table_name(jp)  created_by created_date updated_by updated_date table_memo)
    COLMN_HEADER_LIST = %w(PK FK index unique type column_name  null limit default column_name(jp)  column_memo)

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

      MIGRATE_METHODS.each do |method_name|
        groups.each do |table_data|
          formatted_list.push(format(table_data, method_name))
        end
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
        column_data_list = column.split(/\s|,/)
        column_data_list.delete('')

        column_type = column_data_list[0].sub(/^t\./, '')
        column_name = column_data_list[1]&.sub(/^:/, '')

        if column_type == 'timestamps'
          timestamps_list = add_timestamps(column_data_list)
          result_list.push(*timestamps_list)
          next
        end

        result_list.push(%W(\s \s \s \s #{column_type} #{column_name}))
      end

      result_list
    end

    def add_timestamps(timestamps_column_list)
      timestamps_list = []
      timestamps_list.push(%W(\s \s \s \s timestamp created_at))
      timestamps_list.push(%W(\s \s \s \s timestamp updated_at))
    end

    def update
    end

    def delete
    end
  end
end
