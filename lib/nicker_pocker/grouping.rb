# テーブルごとにグループ化
module NickerPocker
  class Grouping
    class << self
      def exec(data_list, options = {})
        new(options).run(data_list)
      end
    end

    # options[:target_tables]
    # options[:target_files]
    def initialize(options)
      @options = options
    end

    # 実行
    #
    # @params [Array] data_list
    # @return [Hash]
    def run(data_list)
      return {} if data_list.length == 0

      # テーブルごとにまとめる
      grouping(data_list)
    end

    private

    # テーブルごと・メソッドごとにグルーピング
    #
    # @params [Array] data_list
    # @return [Hash]
    def grouping(data_list)
      temp_group_list = data_list.map { |data| data.map { |row| format_raw_data(row) } }.flatten

      groups = {}
      temp_group_list.each do |temp_group|
        table_name = temp_group.first.first
        methods = temp_group.first[1]
        method_name = methods.keys.first

        groups[table_name] = {} unless groups[table_name]
        groups[table_name][method_name] = [] unless groups[table_name][method_name]

        groups[table_name][method_name].push(methods.values.first)
      end

      # 出力対象を絞る
      groups.each do |group|
        group.delete(group[0]) unless target_table?(group[1].keys)
      end

      groups
    end

    # データを整形
    def format_raw_data(data)
      # メソッド・対象テーブルを取得
      tables = {}
      methods = {}

      target_method = target_method(data.first).to_sym
      return unless target_method

      method_row = data.first.split(/,/)
      table_name = method_row[0].split(/\s/)[1].sub(/^:/, '').to_sym

      method_contents = data.length > 1 ? data[1..] : method_row[1..]
      method_contents = method_contents.map { |content| content.strip.sub(/^:/, '') }.reject(&:empty?)

      methods[target_method] = method_contents

      tables[table_name] = methods
      tables
    end

    def target_method(str)
      MIGRATE_METHODS.each do |method_name|
        return method_name if /#{method_name.to_s}/.match(str)
      end

      return
    end

    # 出力対象のテーブル判定
    #
    # @params [Array] methods_list
    # @return [Boolean]
    def target_table?(methods_list)
      # drop_table がない・create_table がある
      # TODO: rename_talbe をcrate_tableに変換する処理を入れておく（じゃないとcreate_table処理がなくてここで除外されるから）
      !methods_list.include?(:drop_table) || methods_list.include?(:create_table)
    end
  end
end
