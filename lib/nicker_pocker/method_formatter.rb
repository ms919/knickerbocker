# 各メソッドごとの処理
module NickerPocker
  class MethodFormatter
    # change_column用
    #
    # @params [Array] method_data_list
    # @params [Array] formatted_table_list
    # @return [Array]
    def change_column(method_data_list, formatted_table_list)
      change_list = column_migrate_list(method_data_list)
      column_formatted_list = formatted_table_list[3..]

      change_list.map do |changes|
        change_row = column_formatted_list.find { |row| row[5] == changes[:column] }
        target_index = column_formatted_list.index(change_row) + 3
        change_row[4] = changes[:type]
        change_row[7] = changes[:null] || change_row[7]
        change_row[8] = changes[:limit] || change_row[8]
        change_row[9] = changes[:default] || change_row[9]
        change_row[10] = changes[:comment] || change_row[10]

        { target_index => change_row }
      end
    end

    # add_column用
    #
    # @params [Array] method_data_list
    # @params [Array] formatted_table_list
    # @return [Array]
    def add_column(method_data_list, formatted_table_list)
      add_list = column_migrate_list(method_data_list)
      index = formatted_table_list.index(formatted_table_list.last)

      counter = 0
      add_list.map do |additions|
        counter += 1
        add_row =
          %W(#{nil} #{nil} #{nil} #{nil} #{additions[:type]} #{additions[:column]} #{nil} #{additions[:null]} #{additions[:limit]} #{additions[:default]} #{additions[:comment]})

        { (index + counter) => add_row }
      end
    end

    def change_table()
    end

    private

    def column_migrate_list(method_data_list)
      method_data_list.map do |method_data|
        migrates = {}

        migrates[:column] = method_data[0]
        migrates[:type] = method_data[1]

        option_list = method_data[2..]
        unless option_list
          migrates
          next
        end

        migrates[:null] = option_list.find { |option| option.match(/^null/) }&.match(/true|false/i)
        migrates[:limit] = option_list.find { |option| option.match(/^limit/) }&.gsub(/[^\d]/, '')
        migrates[:default] = option_list.find { |option| option.match(/^default/) }&.gsub(/^default:|\s/, '')
        migrates[:comment] = option_list.find { |option| option.match(/^comment/) }&.gsub(/^comment:|\s/, '')
        migrates
      end
    end
  end
end
