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
      temp_group_list = data_list.map { |data| format_raw_data(data) }

      groups = {}
      temp_group_list.each do |temp_group|
        groups[temp_group.keys.first] = {} unless groups[temp_group.keys.first]
        groups[temp_group.keys.first].merge!(temp_group.values.first)
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

      arr = data.first.split(/\(|,|\s/)
      table_name = arr[1].sub(/^:/, '').to_sym

      methods[target_method.to_sym] = data[1..]

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
