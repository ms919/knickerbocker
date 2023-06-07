# テーブル整形
module NickerPocker
  module Format
    class Table
      TABLE_HEADER_LIST = %W(
        table_name
        #{nil}
        #{nil}
        table_name(jp)
        #{nil}
        #{nil}
        created_by
        created_date
        updated_by
        updated_date
        table_memo
      ).freeze

      COLMN_HEADER_LIST = %W(
        PK
        FK
        index
        unique
        type
        column_name
        #{nil}
        null
        limit
        default
        column_name(jp)
        #{nil}
        column_memo
      ).freeze

      # グループ整形
      #
      # @params [Hash] groups
      # @return [Hash]
      def format_groups(groups)
        return [] if groups.length == 0

        # リネームテーブル処理
        renamed_groups = rename_table(groups)

        # テーブル削除処理
        drop_table(renamed_groups)
      end

      # テーブル作成用配列
      #
      # @params [Hash] groups
      # @return [Hash]
      def table_list(table_groups)
        table_groups.map { |table_data| create_table_format(table_data) }
      end

      private

      # テーブルリネーム処理
      #
      # @params [Hash] groups
      # @return [Hash]
      def rename_table(groups)
        temp_list =
          groups.map do |table_data|
            if table_data[1][:rename_table]
              new_table_name = table_data[1][:rename_table].first.first.to_sym
              [table_data[0], new_table_name]
            end
          end.compact

        temp_list.each do |rename_table|
          old_val = groups[rename_table[1]]
          # リネーム後のテーブル名に対するmigrateの有無
          if old_val
            groups[rename_table[1]] =
              old_val.merge(groups.delete(rename_table[0])) { |key, old_v, new_v| old_v + new_v }
          else
            groups[rename_table[1]] = groups.delete(rename_table[0])
          end
        end

        groups
      end

      # テーブル削除処理
      #
      # @params [Hash] groups
      # @return [Hash]
      def drop_table(groups)
        # 削除対象tableリスト
        drop_table_list = []
        groups.each do |table_data|
          next unless table_data[1][:drop_table]
          drop_table_list.push(table_data[0])
        end

        return groups if drop_table_list.empty?

        drop_table_list.each do |drop_table_name|
          groups.delete(drop_table_name)
        end

        groups
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

          type = column_data_list[0]

          if type == 'timestamps'
            timestamps_list = timestamps(column_data_list[1..])
            result_list.push(*timestamps_list)
            next
          end

          name = column_data_list[1]&.sub(/^:/, '')
          null, limit, default, comment = constraints(column_data_list[2..])

          result_list.push(%W(#{nil} #{nil} #{nil} #{nil} #{type} #{name} #{nil} #{null} #{limit} #{default} #{comment}))
        end

        result_list
      end

      # 作成・更新日時カラム追加処理
      #
      # @params [Array] timestamps_left_list
      # @return [Array]
      def timestamps(timestamps_left_list)
        timestamps_list = []

        null, limit, default, comment = constraints(timestamps_left_list)

        timestamps_list.push(%W(#{nil} #{nil} #{nil} #{nil} timestamp created_at #{nil} #{null} #{limit} #{default} #{comment}))
        timestamps_list.push(%W(#{nil} #{nil} #{nil} #{nil} timestamp updated_at #{nil} #{null} #{limit} #{default} #{comment}))
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
end
