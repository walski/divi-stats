require 'csv'

class DiviStats
  class ParseCsvs
    class CsvRow
      KEY_STATE = 'bundesland'
      KEY_COUNTY = 'gemeindeschluessel'
      KEY_CASES_OVERALL = 'faelle_covid_aktuell'
      KEY_CASES_VENTILATED = 'faelle_covid_aktuell_beatmet'
      KEY_ICUS_AVAILABLE = 'betten_frei'
      KEY_ICUS_OCCUPIED = 'betten_belegt'
      KEY_DATE = 'daten_stand'

      PATTERN_DATE_SPLIT = /[-\s]/

      def initialize(row:)
        @row = row
      end

      def bundesland
        @row[KEY_STATE]
      end

      def gemeinde
        @row[KEY_COUNTY]
      end

      def cases_overall
        @row[KEY_CASES_OVERALL]&.to_i
      end

      def cases_ventilated
        @row[KEY_CASES_VENTILATED]&.to_i
      end

      def icus_available
        @row[KEY_ICUS_AVAILABLE]&.to_i
      end

      def icus_occupied
        @row[KEY_ICUS_OCCUPIED]
      end

      def icus_total
        icus_available + icus_occupied
      end

      def icus_availability
        icus_availability.to_f / icus_total
      end

      def date
        return @date if @date
        return nil if !@row[KEY_DATE]

        year, month, date = @row[KEY_DATE]&.split(PATTERN_DATE_SPLIT)

        @date = Date.new(year.to_i, month.to_i, date.to_i)
      end
    end

    class CsvFile
      def initialize(path:)
        @path = path
      end

      def data
        @data = CSV.parse(file_contents, headers: true)
      end

      protected
      def file_contents
        @file_contents ||= File.read(@path)
      end
    end

    def build_db
      csvs_path = File.expand_path('../csvs', __FILE__)
      csvs_path = File.join(csvs_path, '*')
      rows = []

      Dir[csvs_path].each do |path|
        csv_file = CsvFile.new(path: path)
        csv_file.data.each do |row|
          rows << CsvRow.new(row: row)
        end
      end

      rows
    end
  end
end