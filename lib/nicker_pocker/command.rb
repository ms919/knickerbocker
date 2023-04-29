# 指定オプションに基づいて処理実行

require 'fileutils'
require 'csv'

module NickerPocker

  MIGRATE_METHODS = %w(create_table)

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

      # TODO：NickerPocker::MigrateMethodsに渡して整形
    end

    # 対象データ判定
    #
    # @params [String] row
    # @return [Boolean]
    def target_data?(row)
      return true if /^t\..*|^def\s.*/.match(row)

      MIGRATE_METHODS.each do |method_name|
        return true if /#{method_name}/.match(row)
      end

      false
    end

    # 必要なデータを抽出
    #
    # @params [Array] data_list
    # @return [Array]
    def necessary_data(temp_data_list)
      data_list = []
      methods_contents = []

      # 使いやすく整形
      temp_data_list.each do |data|
       if /^def\s.*/.match(data)
          data_list << methods_contents if methods_contents.any?
          methods_contents = []
       end

       methods_contents << data
      end
      data_list << methods_contents if methods_contents.any?

      # 不要データを除外
      data_list.reject! { |data| data.include?('def down') }
      data_list.map { |data| data.reject { |x| /^def\s.*/.match(x) } }.reject(&:empty?)
    end

    # 出力
    #
    # @params [Array] data_list
    def output(data_list)
      # ディレクトリ作成（なければ）
      FileUtils.mkdir_p(@options[:output])

      # csv作成
      CSV.open("#{@options[:output]}table_definition.csv", 'w') do |csv|
        csv << data_list
      end
    end
  end
end
