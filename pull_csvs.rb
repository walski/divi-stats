require "net/https"
require "uri"
require "base64"

require "nokogiri"

class DiviStats
  class CsvPuller
    module BasePage
      def body
        response&.body
      end

      def parsed_body
        Nokogiri::HTML(body)
      end

      protected

      def uri
        return unless url
        @uri ||= URI.parse(url)
      end

      def http
        return @http if @http

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        @http = http
      end

      def request
        return unless uri
        @request ||= Net::HTTP::Get.new(uri.request_uri)
      end

      def response
        return unless request
        @response ||= http.request(request)
      end
    end

    class OverviewPage
      URL = 'https://edoc.rki.de/handle/176904/7011/recent-submissions?offset=%{offset}'

      include BasePage

      def initialize(offset:)
        @offset = offset
      end

      def url
        URL % { offset: @offset }
      end

      def pages
        parsed_body.css('.ds-artifact-item > a').map do |a|
          Page.new(url: 'https://edoc.rki.de' + a['href'])
        end
      end
    end

    class CsvPage
      include BasePage

      def initialize(filename:, details_page_body:)
        @filename = filename
        @details_page_document = Nokogiri::HTML(details_page_body)
      end

      def url
        return unless csv_url
        'https://edoc.rki.de/' + csv_url
      end
      
      def body
        return unless uri&.path&.end_with?('.csv')
        super
      end

      protected
      def csv_url
        (@details_page_document.css('.ds-artifact-item > a[href^="/bitstream"]').first || {})['href']
      end
    end

    class Page
      include BasePage

      attr_reader :url

      def initialize(url:)
        @url = url
      end

      def file_system_name
        Base64.urlsafe_encode64(url)
      end
    end

    def download_all_pages
      last_offset = -20
      more_pages = true

      while more_pages
        overview = OverviewPage.new(offset: last_offset + 20)
        base_path = File.expand_path('../detail_pages', __FILE__)

        puts "Offset: #{last_offset}. Found #{overview.pages.size} more pages"
        overview.pages.each do |page|
          output_path = File.join(base_path, page.file_system_name)
          unless File.exist?(output_path)
            print "Downloading #{page.url}"
            File.write(output_path, page.body)
            puts " done."
          end
        end
        more_pages = (overview.pages.size > 0)
        last_offset += overview.pages.size
      end
    end

    def download_all_csvs
      detail_pages_path = File.expand_path('../detail_pages', __FILE__)
      detail_pages_path = File.join(detail_pages_path, '*')
      all_items = Dir[detail_pages_path].size

      Dir[detail_pages_path].each.with_index do |path, i|
        puts "CSV %03d / %03d" % [i + 1, all_items]
        csv_page_path = File.expand_path('../csvs', __FILE__)
        csv_page_path = File.join(csv_page_path, File.basename(path))
        next if File.exist?(csv_page_path)
        body = File.read(path)
        csv_page = CsvPage.new(filename: File.basename(path), details_page_body: body)
        csv_body = csv_page.body
        File.write(csv_page_path, csv_body) if csv_body
      end
    end
  end
end