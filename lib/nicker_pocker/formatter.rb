# 整形
module NickerPocker
  class Formatter
    TABLE_HEADER_LIST = %W(table_name #{nil} #{nil} table_name(jp) #{nil} #{nil} created_by created_date updated_by updated_date table_memo)
    COLMN_HEADER_LIST = %W(PK FK index unique type column_name #{nil} null limit default column_name(jp) #{nil} column_memo)

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
      migrate_method = MethodFormatter.new

      # リネームテーブル処理
      rename_table_list = rename_table_list(groups)
      rename_table_list.each do |rename_table|
        old_val = groups[rename_table[1]]
        # リネーム後のテーブル名に対するmigrateの有無
        if old_val
          groups[rename_table[1]] =
            old_val.merge(groups.delete(rename_table[0])) { |key, old_v, new_v| old_v + new_v }
        else
          groups[rename_table[1]] = groups.delete(rename_table[0])
        end
      end

      groups.each do |table_data|
        formatted_table_list = []
        MIGRATE_METHODS.each do |method_name|
          next if method_name == :rename_table

          if method_name == :create_table
            create_table_formatted_list = create_table_format(table_data)

            formatted_table_list.push(*create_table_formatted_list)
          else
            # create_table, rename_table以外の処理
            method_data = table_data[1][method_name]
            next unless method_data

            change_content_list =
              migrate_method.send(method_name, method_data, formatted_table_list)

            change_content_list.each do |change_contents|
              index = change_contents.keys.first
              value = change_contents.values.first

              formatted_table_list[index] = value
            end
          end
        end
        formatted_list.push(formatted_table_list.compact)
      end

      formatted_list
    end

    # テーブルのリネーム配列を返す
    #
    # @params [Hash] groups
    # @return [Array]
    def rename_table_list(groups)
      temp_list =
        groups.map do |table_data|
          if table_data[1][:rename_table]
            new_table_name = table_data[1][:rename_table].first.first.to_sym
            [table_data[0], new_table_name]
          end
        end.compact
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
      columns_list = methods[:create_table].join.split(/t\./).reject(&:empty?)
      formatted_column_list = create_table(columns_list)

      formatted_table_list.push(*formatted_column_list)
    end

    # テーブル作成処理
    #
    # @params [Array] columns_list
    # @return [Array]
    def create_table(columns_list)
      result_list = []

      # Pキー追加
      result_list.push(%W(* #{nil} #{nil} #{nil} integer id #{nil} false #{nil} #{nil} ID))

      columns_list.each do |column|
        column_data_list = column.split(/\s|,|=>/)
        column_data_list.delete('')

        column_type = column_data_list[0]

        if column_type == 'timestamps'
          timestamps_list = timestamps(column_data_list[1..])
          result_list.push(*timestamps_list)
          next
        end

        column_name = column_data_list[1]&.sub(/^:/, '')
        column_null, column_limit, column_default, column_comment = constraints(column_data_list[2..])

        result_list.push(%W(#{nil} #{nil} #{nil} #{nil} #{column_type} #{column_name} #{nil} #{column_null} #{column_limit} #{column_default} #{column_comment}))
      end

      result_list
    end

    # 作成・更新日時カラム追加処理
    #
    # @params [Array] timestamps_left_list
    # @return [Array]
    def timestamps(timestamps_left_list)
      timestamps_list = []

      column_null, column_limit, column_default, column_comment = constraints(timestamps_left_list)

      timestamps_list.push(%W(#{nil} #{nil} #{nil} #{nil} timestamp created_at #{nil} #{column_null} #{column_limit} #{column_default} #{column_comment}))
      timestamps_list.push(%W(#{nil} #{nil} #{nil} #{nil} timestamp updated_at #{nil} #{column_null} #{column_limit} #{column_default} #{column_comment}))
    end

    # 各制約
    #
    # @params [Array] left_list
    def constraints(left_list)
      return if left_list.nil? || left_list.empty?

      temp_constraint_list = left_list.map { |column_data| column_data.gsub(/:|'/, '') }
      constraints = temp_constraint_list.each_slice(2).to_h

      %W(#{constraints['null']} #{constraints['limit']} #{constraints['default']} #{constraints['comment']})
    end
  end
end
