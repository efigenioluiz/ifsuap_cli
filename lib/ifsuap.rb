require 'dotenv/load'
require 'selenium-webdriver'
require 'thor'
require 'json'
require 'tty-spinner'
require 'date'
require 'fileutils'
require 'pdf-reader'
require 'open-uri'

module IfSuap
  class Command < Thor
    def initialize(*args)
      super
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')
      options.add_argument('--window-size=1280,800')
      options.add_argument('--disable-gpu')
      options.add_argument('--disable-blink-features=AutomationControlled')
      options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
      prefs = {
        "download.prompt_for_download" => false,
        "download.extensions_to_open" => "application/pdf",
        "plugins.always_open_pdf_externally" => true
      }
      options.add_preference(:prefs, prefs)

      @driver = Selenium::WebDriver.for :chrome, options: options
      wait = Selenium::WebDriver::Wait.new(timeout: 5)

      wait.until { @driver.execute_script("return document.readyState") == "complete" }
    end

    no_commands do
      def login_suap
        if ENV['SUAP_USERNAME'].nil? || ENV['SUAP_PASSWORD'].nil?
          response_body(status: "Error", message: "Error: SUAP_USERNAME and SUAP_PASSWORD must be set in the environment variables", data: [])
          exit 1
        end

        @driver.navigate.to 'https://suap.ifpr.edu.br/accounts/login/'

        wait = Selenium::WebDriver::Wait.new(timeout: 10)

        wait.until { @driver.find_element(id: 'id_username') }
        @driver.find_element(id: 'id_username').send_keys(ENV['SUAP_USERNAME'])

        wait.until { @driver.find_element(id: 'id_password') }
        @driver.find_element(id: 'id_password').send_keys(ENV['SUAP_PASSWORD'])

        wait.until { @driver.find_element(css: "input.btn.success") }
        @driver.find_element(css: "input.btn.success").click
      end

      def response_body(status:, message:, data: {})
        response = {
          status: status,
          message: message,
          data: data
        }
        puts JSON.pretty_generate(response)
      end

      def extract_pdf_content(path_to_file)
        reader = PDF::Reader.new(path_to_file)

        content = []
        start_capture = false
        end_capture = false

        reader.pages.each do |page|
          text = page.text

          if text.include?("Conteúdo Programático")  && !start_capture
            start_capture = true
          end

          if start_capture && !end_capture
            text.each_line do |line|
              line.strip!
              content << line unless line.empty?

              if line.include?("Metodologia")
                end_capture = true
                break
              end
            end
          end
        end
        content
      end

      def download_pdf(pdf_url, path_to_file)
        File.open(path_to_file, "wb") do |file|
          file.write URI.open(pdf_url).read
        end
      end
    end

    desc "fetch_students [DISCIPLINE_ID ou DISCIPLINE_NAME]", "Fetches student data from SUAP based on the discipline ID or name"
    def fetch_students(discipline_id = nil, step = 1)

      if discipline_id.nil?
        response_body(status: "Error", message: "Error: ID must be informed", data: [])
        return
      end

      login_suap
      @driver.navigate.to "https://suap.ifpr.edu.br/edu/meu_diario/#{discipline_id}/#{step}/?tab=notas"

      wait = Selenium::WebDriver::Wait.new(timeout: 10)
      wait.until { @driver.find_element(:css, 'table#table_notas tbody') }

      students_rows = @driver.find_elements(:css, 'table#table_notas tbody tr')
      students_data = students_rows.map do |row|
        begin
          student_name = row.find_element(:xpath, './/td/dl/dd')&.text.strip
          student_id = row.find_element(:xpath, './/td/dl/dd/a')&.text.strip

          if student_name && student_id
            { name: student_name.split("(")[0].strip, id: student_id }
          else
            puts "Erro: Dados incompletos para a linha #{row.text}"
            nil
          end
        rescue Selenium::WebDriver::Error::NoSuchElementError => e
          nil
        end
      end.compact


      response_body(status: "Success", message: "Discipline found of the step: #{step}", data:{
        discipline_id: discipline_id,
        students: students_data
      })

      @driver.quit
    end

    desc "fetch_disciplines", "Fetches all disciplines (name and ID)"
    def fetch_disciplines
      # spinner = TTY::Spinner.new("[:spinner] Loading...", format: :dots)
      # spinner.auto_spin
      login_suap

      @driver.navigate.to 'https://suap.ifpr.edu.br/edu/meus_diarios/'

      disciplines = @driver.find_elements(:css, 'div.general-box')
      disciplines_data = disciplines.map do |discipline|
        info_discipline = discipline.find_element(:css, 'h5.title a').text.split('-')

        id_discipline = info_discipline[0].strip()
        type_discipline = info_discipline[1].split('.')[0]+info_discipline[3]
        name_discipline = info_discipline[2].strip()

        {
          id: id_discipline,
          name: name_discipline,
          type_discipline: type_discipline,
        }
      end
      if disciplines_data.empty?
        response_body(status: "Error", message: "Disciplines not found something is wrong", data: disciplines_data)
        return
      end
      response_body(status: "Success", message: "Disciplines fetched", data: disciplines_data)

      # spinner.success("Done!")
      @driver.quit
    end
    desc "create_class [DATE, DISCIPLINE_ID ,CONTENT_CLASS, QT_CLASSES]", "Create a class on discipline with the given information"
    method_option :date, aliases: "-d" ,type: :string, default: Date.today.to_s, desc: "Date of the class"
    method_option :discipline_id, aliases: "-id", type: :string, required: true, desc: "ID of the discipline"
    method_option :content_class, aliases: "-c" ,type: :string, default: '', desc: "Content of the class"
    method_option :qt_classes, aliases: "-qt",type: :numeric, default: 1, desc: "Number of classes"
    def create_class
      date = Date.parse(options[:date])
      discipline_id = options[:discipline_id]
      content_class = options[:content_class]
      qt_classes = options[:qt_classes]

      if discipline_id.nil? || discipline_id.empty?
        response_body(status: "Error", message: "Error: DISCIPLINE ID must be informed", data: [])
        return
      end

      puts "#{date} - #{content_class} - #{qt_classes}"
    end

    desc "teaching_plan", "Get the teaching plan of the discipline"
    method_option :discipline_id, aliases: "-i", type: :string, desc: "ID of the discipline"
    def teaching_plan
      discipline_id = options[:discipline_id]

      if discipline_id.nil? || discipline_id.empty?
        response_body(status: "Error", message: "Error: DISCIPLINE ID must be informed", data: [])
        return
      end
      login_suap
      @driver.navigate.to 'https://suap.ifpr.edu.br/admin/edu/planoensino/'

      wait = Selenium::WebDriver::Wait.new(timeout: 10)
      wait.until { @driver.find_elements(:css, '.icon.icon-view').size > 0 }

      teaching_plans = @driver.find_elements(:css, '.icon.icon-view')
      teaching_plans.each do |teaching_plan|
          teaching_plan_id = teaching_plan.attribute('title').split('-')[1].strip
          title = teaching_plan.attribute('title').split('-')[3].strip

          if teaching_plan_id == discipline_id
            pdf_url = teaching_plan.attribute('href')
            path_to_file = Dir.pwd+'/lib/files/'+"#{title}.pdf"

            unless File.file?(path_to_file)
              download_pdf(pdf_url, path_to_file)
            end
            content = extract_pdf_content(path_to_file)

            response_body(status: "Success", message: "Teaching plan downloaded",
              data: [saved: Dir.pwd+'/lib/files/'+"#{title}.pdf",
                content: content
              ])
            return
          end
        end
        response_body(status: "Error", message: "Teaching plan not found", data: [])
    end

    desc "set_cf_for_step [STEP]", "Set the CF for the step"
    def set_cf_for_step(file_path = nil, discipline_id = nil,step=1)
      step = step.to_i

      if discipline_id.nil? or file_path.nil?
        response_body(status: "Error", message: "Error: discipline id  or file path must be informed", data: [])
        return
      end

      students = JSON.parse(File.read(file_path))
      login_suap

      @driver.navigate.to "https://suap.ifpr.edu.br/edu/meu_diario/#{discipline_id}/#{step}/?tab=notas"

      wait = Selenium::WebDriver::Wait.new(timeout: 10)
      wait.until { @driver.find_element(css: 'table#table_notas tbody') }

      data = []
      students.each do |student|
        id_student = student['id']
        name_student = student['name']
        cf_concept = student['cf']

        begin
          student_row = @driver.find_element(:xpath, "//a[contains(@href, '#{id_student}')]/ancestor::tr")

          cf_field = student_row.find_element(:xpath, ".//input[contains(@onblur, ', #{step})')]")


          cf_field.clear
          cf_field.send_keys(cf_concept)
          cf_field.send_keys(:tab)

          data << "CF for student ID #{id_student} successfully updated."

        rescue Selenium::WebDriver::Error::NoSuchElementError => e
          if e.message.include?("ancestor::tr")
            data << "Student with #{name_student} not found in the table."
          else
            data << "Student with #{name_student} has no CF input field (possibly inactive or unavailable)."
          end
        end

      end
      response_body(status: "Success", message: "CF updated", data: data)
    end

  end
end
