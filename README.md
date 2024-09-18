# A.L.O.H.A - Advanced Learning Orchestrating Human Assistance

A.L.O.H.A is an AI driven personal assistant designed to help you manage tasks, events, and categories. Using Natural Language Processing (NLP) and Machine Learning (ML), ALOHA provides an interactive way to handle your to-do lists and categorize your activities.

## Features
- **Add Tasks:** Easily add new tasks to your to-do list.
- **Delete Tasks:** Remove tasks from your list.
- **Create Categories:** Organize tasks into categories.
- **List Tasks:** View all your current tasks.

## Development Goals
This project is currently under active development and is a fun, exploratory side venture. It focuses on learning machine learning techniques and integrating them into a backend API, with the aim of eventually incorporating this into a Flutter application. The project is a hands-on way to understand both ML and app development processes.
- **Flutter Integration:** Convert the ALOHA chatbot into a Flutter app for mobile platforms.
- **Voice Assistant:** Integrate voice recognition and processing to interact with ALOHA via voice commands.
- **Reminder System:** Implement functionality to set and manage reminders for tasks and events. 

## Installation

To run ALOHA, you'll need Python and several libraries. Follow these steps to set up the project:

1. **Clone the repository:**

    ```bash
    git clone https://github.com/Apollo-Blaze/ALOHA.git
    cd ALOHA
    ```

2. **Download NLTK Data:**

    Run the following Python script to download the necessary NLTK data:

    ```python
    import nltk
    nltk.download('punkt')
    nltk.download('wordnet')
    nltk.download('stopwords')
    ```

## Usage

1. **Train the Model:**

    Run the `train_model.py` script to train the model with your intents and save it:

    ```bash
    python train_model.py
    ```

2. **Run the Bot:**

    Start the bot using the `aloha_bot.py` script:

    ```bash
    python aloha_bot.py
    ```

3. **Interact with ALOHA:**

    You can now interact with ALOHA through the command line. Type your commands to manage tasks and categories.
   

## Contributing

Feel free to contribute to the project by opening issues, submitting pull requests, or providing feedback. To contribute:

1. **Fork the repository.**
2. **Create a new branch.**
3. **Make your changes.**
4. **Submit a pull request.**

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For any questions or support, please reach out to [srichandsureshrocks@gmail.com](mailto:srichandsureshrocks@gmail.com).

