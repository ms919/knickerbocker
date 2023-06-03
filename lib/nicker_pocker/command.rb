# 指定オプションに基づいて処理実行

require 'fileutils'
require 'csv'

module NickerPocker

  MIGRATE_METHODS = %i(create_table change_column add_column remove_column)

  class Command
    class << self
      def exec(options = {})
        new(options).run
      end
    end

    # 各設定をセット
    def initialize(options)
      @options = options

      # 初期値設定
      @options[:input]  ||= './db/migrate/'
      @options[:output] ||= './nicker_pocker/'
      @options[:format] ||= :csv
    end

    # 実行
    def run
      return if Dir.glob("#{@options[:input]}*\.rb").empty?

      output(read_data)
    end

    private

    # 対象マイグレーションファイルを読み込み
    #
    # @return [Array]
    def read_data
      temp_data_list = []

      Dir::foreach(@options[:input]) do |file_name|
        next if ['.', '..'].include?(file_name)

        File.open(@options[:input] + file_name) do |f|
          temp_data_list.push(f.readlines.each(&:strip!))
        end
      end

      temp_data_list.flatten!.select! { |row| target_data?(row) }.compact!
      data_list = necessary_data(temp_data_list)

      groups = Grouping.exec(data_list)
      Formatter.exec(groups)
    end

    # 対象データ判定
    #
    # @params [String] row
    # @return [Boolean]
    def target_data?(row)
      return true if /^t\..*|^def\s.*/.match(row)

      MIGRATE_METHODS.each do |method_name|
        return true if /#{method_name.to_s}\s/.match(row)
      end

      false
    end

    # 必要なデータを抽出
    #
    # @params [Array] data_list
    # @return [Array]
    def necessary_data(temp_data_list)
      pattern = Regexp.new(".*?[#{MIGRATE_METHODS.map(&:to_s).join('|')}].*")
      data_list = data_list(temp_data_list)
      delete_val_list = []

      # グルーピングしやすいように整形
      data_list.each_with_index do |data, index|
        pattern_match_list = data.map { |content| content.scan(pattern).join.split(',') }.reject(&:empty?)

        if pattern_match_list.first.length > 1
          delete_val_list.push(data)
          data_list.push(*pattern_match_list)
        end
      end

      delete_val_list.each { |val| data_list.delete(val)}

      data_list
    end

    def data_list(temp_data_list)
      data_list = []
      methods_contents_list = []

      # 使いやすく整形
      temp_data_list.each do |data|
       if /^def\s.*/.match(data)
          data_list.push(methods_contents_list) if methods_contents_list.any?
          methods_contents_list = []
       end

       methods_contents_list.push(data)
      end

      # 不要データを除外
      data_list.reject! { |data| data.include?('def down') }
      data_list.map { |data| data.reject { |x| /^def\s.*/.match(x) } }.reject(&:empty?)
    end

    # 出力
    #
    # @params [Array] formatted_list
    def output(formatted_list)
      # ディレクトリ作成（なければ）
      FileUtils.mkdir_p(@options[:output])

      # csv作成
      CSV.open("#{@options[:output]}table_definition.csv", 'w') do |csv|
        formatted_list.each do |formatted_table|
          formatted_table.each do |formatted_row|
            csv << formatted_row
          end
          csv << []
        end
      end
    end
  end
end
