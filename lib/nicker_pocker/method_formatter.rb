# 各メソッドごとの処理

module NickerPocker
  class MethodFormatter
    # change_column用
    #
    # @params [Array] method_data_list
    # @params [Array] formatted_table_list
    # @return [Array]
    def change_column(method_data_list, formatted_table_list)
      change_list =
        method_data_list.map do |method_data|
          changes = {}
          changes[:column] = method_data[0]
          changes[:type] = method_data[1]

          option_list = method_data[2..]
          unless option_list
            changes
            next
          end

          changes[:null] = option_list.find { |option| option.match(/^null/) }&.match(/true|false/i)
          changes[:limit] = option_list.find { |option| option.match(/^limit/) }&.gsub(/[^\d]/, '')
          changes[:default] = option_list.find { |option| option.match(/^default/) }&.gsub(/^default:|\s/, '')
          changes[:comment] = option_list.find { |option| option.match(/^comment/) }&.gsub(/^comment:|\s/, '')
          changes
        end

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
  end
end
