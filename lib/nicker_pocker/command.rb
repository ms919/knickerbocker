# 指定オプションに基づいて処理実行

require 'fileutils'
require 'csv'

module NickerPocker
  class Command
    class << self
      def exec(options = {})
        new(options).run
      end
    end

    # 各設定をセット
    def initialize(options = {})
      @options = options

      # 初期値設定
      @options[:input] = './db/migrate/'
      @options[:output] = './nicker_pocker/'
      @options[:format] = :csv
    end

    # 実行
    def run
      return if Dir.glob("#{@options[:input]}*\.rb").empty?

      @options[:existing_version] = existing_version
      output(read_data)
    end

    private

    # 既存のテーブル定義書のバージョンを取得
    #
    # @return [Integer]
    def existing_version
      return if Dir.glob("#{@options[:output]}*\.#{@options[:format]}").empty?

      str = nil
      File.open("#{@options[:output]}table_definition.csv") do |f|
        r = /^version.*\d{4}_\d{2}_\d{2}_\d{6}/
        while str.nil? do
          str = r.match(f.readline(chomp: true))
        end
      end

      return if str.nil?
      str.to_s.slice(/\d{4}_\d{2}_\d{2}_\d{6}/).gsub('_', '').to_i
    end

    # 対象マイグレーションファイルを読み込み
    #
    # @return [Array]
    def read_data
      arr = []
      Dir::foreach(@options[:input]) do |file_name|
        next if skip_files?(file_name)

        File.open(@options[:input] + file_name) do |f|
          arr.push(f.readlines.each(&:strip!))
        end
      end

      arr.flatten.map do |row|
        row if /^t\..*|^def\s.*/.match(row)
      end.compact
    end

    # 読み込みスキップ対象のファイル判定
    #
    # @params [String] file_name
    # @return [Boolean]
    def skip_files?(file_name)
      ['.', '..'].include?(file_name) || file_name.to_i <= @options[:existing_version]
    end

    # 出力
    #
    # @params [Array] data_list
    def output(data_list)
      # ディレクトリ作成（なければ）
      FileUtils.mkdir_p(@options[:output])
      # csv作成
      now = Time.now.strftime('%Y%m%d%H%M%S')

      CSV.open("#{@options[:output]}table_definition.csv", 'w') do |csv|
        csv << ['output time']
        csv << [now]
        csv << data_list
      end
    end
  end
end
