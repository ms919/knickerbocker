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
      @options[:output] = './nicker_pocker/outputs/'
      @options[:format] = :csv
    end

    # 実行
    def run
      # ディレクトリ作成（なければ）
      FileUtils.mkdir_p(@options[:output])
      # csv作成
      now = Time.now.strftime('%Y%m%d%H%M%S')

      CSV.open("#{@options[:output]}#{now}.csv", 'w') do |csv|
        csv << ['output time']
        csv << [now]
      end
    end
  end
end
