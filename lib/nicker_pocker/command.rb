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
      output(*read_data)
    end

    private

    # 既存のテーブル定義書のバージョンを取得
    #
    # @return [Integer]
    def existing_version
      return 0 if Dir.glob("#{@options[:output]}*\.#{@options[:format]}").empty?

      str = nil
      r = /^version.*\d{4}_\d{2}_\d{2}_\d{6}/

      begin
        File.open("#{@options[:output]}table_definition.csv") do |f|
          while str.nil? do
            str = r.match(f.readline(chomp: true))
          end
        end
      rescue EOFError
        return 0 if str.nil?
        return str.to_s.slice(/\d{4}_\d{2}_\d{2}_\d{6}/).gsub('_', '').to_i
      end
    end

    # 対象マイグレーションファイルを読み込み
    #
    # @return [Array]
    def read_data
      arr = []
      version = 0
      Dir::foreach(@options[:input]) do |file_name|
        next if skip_files?(file_name)
        file_version = file_name.to_i
        version = file_version if version < file_version

        File.open(@options[:input] + file_name) do |f|
          arr.push(f.readlines.each(&:strip!))
        end
      end

      [
        version.to_s,
        arr.flatten.map do |row|
          row if /^t\..*|^def\s.*/.match(row)
        end.compact
      ]
    end

    # 読み込みスキップ対象のファイル判定
    #
    # @params [String] file_name
    # @return [Boolean]
    def skip_files?(file_name)
      ['.', '..'].include?(file_name) || file_name.to_i <= @options[:existing_version].to_i
    end

    # 出力
    #
    # @params [String] version
    # @params [Array] data_list
    def output(version, data_list)
      # ディレクトリ作成（なければ）
      FileUtils.mkdir_p(@options[:output])

      # csv作成
      CSV.open("#{@options[:output]}table_definition.csv", 'w') do |csv|
        csv << output_version(version)
        csv << data_list
      end
    end

    # 出力用バージョン取得
    #
    # @params [String]
    # @return [Array]
    def output_version(version)
      ["version: #{version[0..3]}_#{version[4..5]}_#{version[6..7]}_#{version.split(/^\d{8}/).last}"]
    end
  end
end
