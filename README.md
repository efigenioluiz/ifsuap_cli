# IfSuap CLI

A Ruby-based Command Line Interface (CLI) for automating interactions with the SUAP system, primarily aimed at fetching discipline data and student information. This tool uses **Selenium WebDriver** to scrape data from the SUAP portal and present it in an easy-to-use format in the terminal.

## 📝 Project Description

IfSuap is a command-line utility that allows users to interact with the SUAP platform to fetch data about disciplines and students. Built with **Ruby**, **Selenium WebDriver**, and **Thor**, this project simplifies the process of retrieving information about your courses, their details, and enrolled students from the SUAP portal.

### 🚀 Features

- **Login Automation**: Automatically logs into the SUAP system using environment variables for your username and password.
- **Fetch Disciplines**: Retrieves a list of disciplines available in the SUAP system, including their IDs and names.
- **Fetch Students**: Fetches a list of students enrolled in a given discipline, showing their names and SUAP IDs.

## 📦 Installation

Before using this tool, ensure that you have the following dependencies installed:

- Ruby
- Selenium WebDriver
- ChromeDriver (or another browser of your choice)

1. Clone the repository to your local machine:

   ```bash
   git clone https://github.com/efigenioluiz/ifsuap_cli.git
   ```

2. Navigate into the project directory:

   ```bash
   cd ifsuap_cli
   ```

3. Install the required Ruby gems:

   ```bash
   bundle install
   ```

4. Set up the environment variables for SUAP login:

   - `SUAP_USERNAME` (your SUAP username)
   - `SUAP_PASSWORD` (your SUAP password)

   You can create a `.env` file in the project directory and add your credentials:

   ```
   SUAP_USERNAME=your_username
   SUAP_PASSWORD=your_password
   ```

## 🛠️ Commands

### `fetch_disciplines`

This command retrieves all available disciplines from SUAP, including their names and IDs.

#### Usage:

```bash
$ ./bin/ifsuap fetch_disciplines
```

#### Description:

- The command will log in to SUAP using the credentials from the environment variables.
- It will navigate to the SUAP portal and fetch all disciplines available in your profile.
- The resulting data will include the **discipline ID**, **name**, and **type** (such as theoretical or practical).
- The list will be returned in JSON format for easy readability.

#### Example Output:

```json
{
  "status": "Success",
  "message": "Disciplines fetched",
  "data": [
    {
      "id": "12345",
      "name": "Mathematics 101",
      "type_discipline": "Theoretical"
    },
    {
      "id": "67890",
      "name": "Physics Lab",
      "type_discipline": "Practical"
    }
  ]
}
```

### Error Handling:

If no disciplines are found or there is an issue with fetching the data, the command will output an error message like:

```json
{
  "status": "Error",
  "message": "Disciplines not found something is wrong",
  "data": []
}
```

## 💬 Development

If you want to contribute to this project, make sure to:

1. Fork this repository
2. Create a new branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to your branch (`git push origin feature/your-feature`)
5. Create a new Pull Request

## 🧑‍💻 Authors

- **Luiz Efigenio** - _Initial work_ - [efigenioluiz](https://github.com/efigenioluiz)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
