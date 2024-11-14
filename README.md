# IfSuap CLI

A Ruby-based Command Line Interface (CLI) for automating interactions with the SUAP system, primarily aimed at fetching discipline data and student information. This tool uses **Selenium WebDriver** to scrape data from the SUAP portal and present it in an easy-to-use format in the terminal.

## 📝 Project Description

IfSuap is a command-line utility that allows users to interact with the SUAP platform to fetch data about disciplines and students. Built with **Ruby**, **Selenium WebDriver**, and **Thor**, this project simplifies the process of retrieving information about your courses, their details, and enrolled students from the SUAP portal.

### 🚀 Features

- **Login Automation**: Automatically logs into the SUAP system using environment variables for your username and password.
- **Fetch Disciplines**: Retrieves a list of disciplines available in the SUAP system, including their IDs and names.
- **Fetch Students**: Fetches a list of students enrolled in a given discipline, showing their names and SUAP IDs.
- **Teaching Plan**: Fetches the teaching plan for a given discipline, including the **discipline ID** and making download of the PDF.and get a content of the PDF via CLI.
- **Set Final Concept to Stundent**: Automatically set final concept to student by discipline ID based on JSON file by step.


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
### `fetch_students`

This command retrieves all students enrolled in a specific discipline based on the discipline ID.

#### Usage:

```bash
$ ./bin/ifsuap fetch_students [DISCIPLINE_ID]
```

#### Description:

- The command will log in to SUAP using the credentials from the environment variables.
- It will navigate to the SUAP portal and fetch the list of students enrolled in the discipline with the given **discipline ID**.
- The data will include the **student name** and **student ID**.
- The list will be returned in JSON format.

#### Example Output:

```json
{
  "status": "Success",
  "message": "Discipline found of the step: 1",
  "data": {
    "discipline_id": "12345",
    "students": [
      {
        "name": "John Doe",
        "id": "67890"
      },
      {
        "name": "Jane Smith",
        "id": "11223"
      }
    ]
  }
}
```

#### Error Handling:

If no students are found or there is an issue with fetching the data, the command will output an error message like:

```json
{
  "status": "Error",
  "message": "Error: ID must be informed",
  "data": []
}
```

<!-- ### `create_class`

This command creates a class for the specified discipline with the given information.

#### Usage:

```bash
$ ./bin/ifsuap create_class --date [DATE] --discipline_id [DISCIPLINE_ID] --content_class [CONTENT_CLASS] --qt_classes [QT_CLASSES]
```

#### Description:

- The command will create a class on the specified discipline.
- The **date** of the class, **discipline ID**, **content** of the class, and **quantity of classes** are required parameters.
- The command will output a confirmation with the class information.

#### Example Output:

```bash
2024-11-11 - Introduction to Computer Networks - 1
```

#### Error Handling:

If the discipline ID is not provided, the command will output an error message like:

```json
{
  "status": "Error",
  "message": "Error: DISCIPLINE ID must be informed",
  "data": []
}
``` -->

### `teaching_plan`

This command retrieves the teaching plan for a specified discipline from the SUAP portal.

#### Usage:

```bash
$ ./bin/ifsuap teaching_plan --discipline_id [DISCIPLINE_ID]
```

#### Description:

- The command will log in to SUAP using the credentials from the environment variables.
- It will navigate to the SUAP portal to fetch the teaching plan of the specified **discipline ID**.
- If the plan is found, it will download the PDF and extract its content, including the programmatic content, objectives, and methodology.

#### Example Output:

```json
{
  "status": "Success",
  "message": "Teaching plan downloaded",
  "data": {
    "saved": "/path/to/teaching_plan.pdf",
    "content": [
      "Content Programmatic: Introduction to Networks...",
      "Objectives: Learn the basics of networking...",
      "Methodology: Practical and theoretical..."
    ]
  }
}
```

#### Error Handling:

If the teaching plan cannot be found, the command will output an error message like:

```json
{
  "status": "Error",
  "message": "Teaching plan not found",
  "data": []
}
```

### `set_cf_for_step`

This command updates the CF (Final Grade) for each student in a specified discipline and step on the SUAP portal, using data from a provided JSON file.

#### Usage:

```bash
$ ./bin/ifsuap set_cf_for_step --file_path [FILE_PATH] --discipline_id [DISCIPLINE_ID] --step [STEP]
```

#### Parameters:
- **`file_path`**: Path to the JSON file containing student data (ID, name, and CF grade).
- **`discipline_id`**: The ID of the discipline to update CF grades.
- **`step`**: The step (period) in which the CF grade should be updated (e.g., 1, 2, or 3).

#### Description:

1. **Login to SUAP**: Logs in to the SUAP portal using credentials stored in environment variables.
2. **Navigation**: Opens the grading page for the specified discipline and step.
3. **Grade Update**:
   - Reads the JSON file containing student IDs, names, and CF grades.
   - Finds each student's row on the SUAP grade table.
   - Inputs the CF grade for each student.
4. **Skipping Inactive Students**: If a student’s row or CF input field is missing (e.g., due to inactivity), it logs a message and continues with the next student.

#### Example JSON File (`students.json`):

```json
[
  {
    "id": "2000000000",
    "name": "JOÃO ",
    "cf": "B"
  },
  {
    "id": "1000000000",
    "name": "LORENA ",
    "cf": "C"
  }
]
```

#### Example Output:

On successful execution, the command will return a JSON response:

```json
{
  "status": "Success",
  "message": "CF updated",
  "data": [
    "CF for student ID 931283128 successfully updated.",
    "Student with ID LORENA  has no CF input field (possibly inactive or unavailable)."
  ]
}
```

#### Error Handling:

If an error occurs or a required parameter is missing, the command outputs an error message:

```json
{
  "status": "Error",
  "message": "Error: discipline id or file path must be informed",
  "data": []
}
```

#### Notes:
- Ensure the JSON file format aligns with the example shown.
- Make sure the `step` parameter corresponds to the correct grading period, as CF inputs differ per step.
- This command requires an active SUAP session with the appropriate permissions to access and modify grades.
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
