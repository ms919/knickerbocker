# フォーマッタ
module NickerPocker
  module Format
    class Operator
      PROTOTYPE_METHODS = %i(
        rename_table
        drop_table
        rename_column
        create_table
      ).freeze

      DETAIL_METHODS = %i(
        add_column
        change_column
        add_index
        remove_column
      ).freeze

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
        prototype_formatter = Prototype.new

        # 定義書の原型をつくる
        table_groups = prototype_formatter.format_groups(groups)
        table_list = prototype_formatter.table_list(table_groups)

        # カラム整形
        format_column(table_groups, table_list)
      end

      # 整形したカラムを返す
      #
      # @params [Hash] table_groups
      # @params [Array] table_list
      # @return [Array]
      def format_column(table_groups, table_list)
        detail_formatter = Detail.new

        table_groups.map do |table_data|
          target_table_list = table_list.find { |table| table[1].first == table_data.first }

          DETAIL_METHODS.each do |method_name|
            method_data = table_data[1][method_name]
            next unless method_data

            change_content_list =
              detail_formatter.send(method_name, method_data, target_table_list)

            change_content_list.each do |change_contents|
              index = change_contents.keys.first
              value = change_contents.values.first

              target_table_list[index] = value
            end
          end
          target_table_list.compact
        end
      end
    end
  end
end
