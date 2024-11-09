require 'dotenv/load'
require 'selenium-webdriver'
require 'thor'
require 'json'
require 'tty-spinner'

module IfSuap
  class Command < Thor
    def initialize(*args)
      super
      @driver = Selenium::WebDriver.for :chrome
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
    end

    desc "fetch_students [DISCIPLINE_ID ou DISCIPLINE_NAME]", "Fetches student data from SUAP based on the discipline ID or name"
    def fetch_students(discipline_params = nil)

      if disciplina_id.nil?
        response_body(status: "Error", message: "Error: ID must be informed", data: [])
        return
      end

      login_suap
      @driver.navigate.to 'https://suap.ifpr.edu.br/edu/meus_diarios/'

      disciplines = @driver.find_elements(:css, 'div.general-box')
      disciplines_data = disciplines.map do |discipline|
        name_discipline = discipline.find_element(:css, 'h5.title a').text
        id_discipline = discipline.find_element(:css, 'h5.title a')['href'].split('/')[4]

        {
          nome: name_discipline,
          id: id_discipline
        }
      end

      selected_discipline = if discipline_params
        disciplines_data.find { |disc| disc[:id] == discipline_params || disc[:name].include?(discipline_params) }
      else
        nil
      end

      if disciplina_selecionada.nil?
        puts JSON.pretty_generate(disciplines_data)
      else
        @driver.navigate.to "https://suap.ifpr.edu.br/edu/meu_diario/#{disciplina_selecionada[:id]}/0/"

        students = @driver.find_elements(:css, 'td[style*="height: 55px"]')
        students_data = students.map do |aluno|
          {
            name: aluno.find_element(:css, 'a').text,
            id_suap: aluno.find_element(:css, 'div.hide-sm a').text
          }
        end

        response_body(status: "Success", message: "Discipline found", data:{
          discipline: selected_discipline,
          students: students_data
        })
      end

      @driver.quit
    end

    desc "fetch_disciplines", "Fetches all disciplines (name and ID)"
    def fetch_disciplines
      spinner = TTY::Spinner.new("[:spinner] Loading...", format: :dots)
      spinner.auto_spin
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

      spinner.success("Done!")
      @driver.quit
    end
  end
end
