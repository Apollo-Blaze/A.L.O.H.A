from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import numpy as np
import nltk
from nltk.stem import WordNetLemmatizer
from tensorflow.keras.models import load_model
import json
import pickle
import difflib
import random

nltk.download('all')

app = Flask(__name__)
CORS(app)

# Setup SQLAlchemy
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///aloha.db'  # For SQLite
# app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://user:password@localhost/aloha'  # For PostgreSQL
# app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://user:password@localhost/aloha'  # For MySQL
db = SQLAlchemy(app)

# Initialize lemmatizer
lemmatizer = WordNetLemmatizer()

# Load intents from JSON file
with open('intents.json') as file:
    intents = json.load(file)
    print(int)

# Load saved words and classes
words = pickle.load(open('words.pkl', 'rb'))
classes = pickle.load(open('classes.pkl', 'rb'))
model = load_model('aloha.h5')

# Define database models
class Category(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    tasks = db.relationship('Task', backref='category', lazy=True)

class Task(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    date = db.Column(db.String(100), nullable=True)
    time = db.Column(db.String(100), nullable=True)
    category_id = db.Column(db.Integer, db.ForeignKey('category.id'), nullable=False)

# Initialize database
with app.app_context():
    db.create_all()

conversation_state = {}
tl = [0] * 5  # Track different task flows

def clean_up_sentence(sentence):
    sentence_words = nltk.word_tokenize(sentence)
    sentence_words = [lemmatizer.lemmatize(word.lower()) for word in sentence_words]
    return sentence_words

def bag_of_words(sentence):
    sentence_words = clean_up_sentence(sentence)
    bag = [0] * len(words)
    for w in sentence_words:
        for i, word in enumerate(words):
            if word == w:
                bag[i] = 1
    return np.array(bag)

def predict_class(sentence):
    bow = bag_of_words(sentence)
    res = model.predict(np.array([bow]))[0]
    ERROR_THRESHOLD = 0.25
    results = [[i, r] for i, r in enumerate(res) if r > ERROR_THRESHOLD]
    results.sort(key=lambda x: x[1], reverse=True)
    return_list = []
    for r in results:
        return_list.append({'intent': classes[r[0]], 'probability': str(r[1])})
    return return_list

def get_response(intents_list, intents_json, message=None):
    print(intents_list)
    if not intents_list:
        return "Sorry, I didn't understand that."
    
    tag = intents_list[0]['intent']
    print(f"Intent: {tag}")  # Debug statement
    print(f"Message: {message}")  # Debug statement
    print(f"Conversation State: {conversation_state}")  # Debug statement
    print(f"Task Flows: {tl}")  # Debug statement

    if tag == "greetings":
        for i in intents_json['intents']:
            if i['tag'] == tag:
                return random.choice(i['responses'])

    if sum(tl) == 0:
        if tag == "greetings":
            for i in intents_json['intents']:
                if i['tag'] == tag:
                    return random.choice(i['responses'])
        if tag == "help":
            for i in intents_json['intents']:
                if i['tag'] == tag:
                    return random.choice(i['responses'])
        if tag == "who_are_you":
            for i in intents_json['intents']:
                if i['tag'] == tag:
                    return random.choice(i['responses'])
        if tag == "thanks":
            for i in intents_json['intents']:
                if i['tag'] == tag:
                    return random.choice(i['responses'])
        if tag == "goodbye":
            for i in intents_json['intents']:
                if i['tag'] == tag:
                    return random.choice(i['responses'])
    if tag == "create_category":
        conversation_state['waiting_for_category_name'] = True
        tl[0] = 1
        return "What would you like to name the new category?"

    if 'waiting_for_category_name' in conversation_state:
        if message:
            response = create_category({'category_name': message})
            conversation_state.pop('waiting_for_category_name', None)
            tl[0] = 0
            return response
        else:
            tl[0] = 0
            return "Category name is required."

    if tag == "add_task":
        tl[1] = 1
        conversation_state['waiting_for_task_category'] = True
        return "Which category do you want to add the task to?"

    if 'waiting_for_task_category' in conversation_state and tl[1] == 1:
        if message and message in [cat.name for cat in Category.query.all()]:
            conversation_state['category'] = message
            conversation_state.pop('waiting_for_task_category', None)
            conversation_state['waiting_for_task_name'] = True
            return "What is the name of the task?"
        else:
            tl[1] = 0
            return "Category name is required."

    if 'waiting_for_task_name' in conversation_state and tl[1] == 1:
        if message:
            conversation_state['task_name'] = message
            conversation_state.pop('waiting_for_task_name', None)
            conversation_state['waiting_for_task_date'] = True
            print(message)
            return "What is the date of the task? (Optional, you can skip this.)"
        else:
            tl[1] = 0
            return "Task name is required."

    if 'waiting_for_task_date' in conversation_state and tl[1] == 1:
        if message is not None:
            if message.lower() == 'skip':
                conversation_state['task_date'] = None
            else:
                conversation_state['task_date'] = message or None
            conversation_state.pop('waiting_for_task_date', None)
            conversation_state['waiting_for_task_time'] = True
            return "What is the time of the task? (Optional, you can skip this.)"
        else:
            tl[1] = 0
            return "Task date is required."

    if 'waiting_for_task_time' in conversation_state and tl[1] == 1:
        if message is not None:
            if message.lower() == 'skip':
                conversation_state['task_time'] = None
            else:
                conversation_state['task_time'] = message or None
            response = add_task({
                'category': conversation_state['category'],
                'task': conversation_state['task_name'],
                'date': conversation_state['task_date'],
                'time': conversation_state['task_time']
            })
            print("this is being sent:",response)
            conversation_state.clear()
            tl[1] = 0
            return response
        else:
            tl[1] = 0
            return "Task time is required."

    if tag == "delete_task":
        tl[3] = 1
        conversation_state['waiting_for_delete_category_dt'] = True
        return "From which category would you like to delete a task?"

    if 'waiting_for_delete_category_dt' in conversation_state and tl[3] == 1:
        if message:
            conversation_state['category'] = message
            conversation_state.pop('waiting_for_delete_category_dt', None)
            conversation_state['waiting_for_delete_task'] = True
            return "Which task would you like to delete?"
        else:
            tl[3] = 0
            return "Category name is required."

    if 'waiting_for_delete_task' in conversation_state and tl[3] == 1:
        if message:
            response = delete_task({
                'category': conversation_state['category'],
                'task': message
            })
            conversation_state.clear()
            tl[3] = 0
            return response
        else:
            tl[3] = 0
            return "Task name is required."

    if tag == "delete_category":
        conversation_state['waiting_for_category_name_d'] = True
        tl[4] = 1
        return "Which category would you like to delete?"

    if 'waiting_for_category_name_d' in conversation_state and tl[4] == 1:
        if message:
            response = delete_category(message)
            conversation_state.pop('waiting_for_category_name_d', None)
            tl[4] = 0
            return response
        else:
            tl[4] = 0
            return "Category name is required to delete a category."

    if tag == "view_tasks":
        tl[2] = 1
        conversation_state['waiting_for_view_category'] = True
        return "Which category would you like to view tasks from? Or you can type 'all' to view tasks from all categories."

    if 'waiting_for_view_category' in conversation_state and tl[2] == 1:
        if message:
            response = view_tasks(message)
            conversation_state.clear()
            tl[2] = 0
            return response
        else:
            return "Category name is required to view tasks."

def create_category(message):
    category_name = message.get('category_name', '').strip().lower()
    if Category.query.filter_by(name=category_name).first():
        return f"Category '{category_name}' already exists."
    new_category = Category(name=category_name)
    db.session.add(new_category)
    db.session.commit()
    return f"Category '{category_name}' has been created."

def add_task(message):
    print("Received message:", message)  # Debugging statement

    task_name = message.get('task', '').strip() or 'Unnamed Task'
    task_date = message.get('date', '').strip() if message.get('date') is not None else ''
    task_time = message.get('time', '').strip() if message.get('time') is not None else ''
    category_name = message.get('category', '').strip()

    print("Task Name:", task_name)  # Debugging statement
    print("Task Date:", task_date)  # Debugging statement
    print("Task Time:", task_time)  # Debugging statement
    print("Category Name:", category_name)  # Debugging statement

    if not task_name:
        return "Task name is required."

    category = Category.query.filter_by(name=category_name).first()
    if not category:
        return f"Category '{category_name}' does not exist."

    new_task = Task(name=task_name, date=task_date, time=task_time, category=category)
    db.session.add(new_task)
    db.session.commit()
    return f"Task '{task_name}' has been added to category '{category_name}'."


def delete_task(message):
    category_name = message.get('category', '').strip().lower()
    task_name = message.get('task', '').strip().lower()

    category = Category.query.filter_by(name=category_name).first()
    if not category:
        return f"Category '{category_name}' does not exist."

    task = Task.query.filter_by(name=task_name, category=category).first()
    if not task:
        return f"Task '{task_name}' does not exist in category '{category_name}'."

    db.session.delete(task)
    db.session.commit()
    return f"Task '{task_name}' has been deleted from category '{category_name}'."

def delete_category(category_name):
    category_name = category_name.strip().lower()
    category = Category.query.filter_by(name=category_name).first()
    if not category:
        return f"Category '{category_name}' does not exist."

    # Delete all tasks related to this category
    tasks = Task.query.filter_by(category=category).all()
    for task in tasks:
        db.session.delete(task)

    # Delete the category
    db.session.delete(category)
    db.session.commit()
    return f"Category '{category_name}' and all related tasks have been deleted."


def view_tasks(category_name):
    if category_name.strip().lower() == 'all':
        categories = Category.query.all()
        if not categories:
            return "No categories found."
        
        response = []
        for category in categories:
            tasks = Task.query.filter_by(category=category).all()
            if tasks:
                task_list = '\n'.join([f"- {task.name}, Date: {task.date}, Time: {task.time}" for task in tasks])
                response.append(f"Category: {category.name}\n{task_list}")
        
        if not response:
            return "No tasks found in any category."
        
        return '\n\n'.join(response)
    else:
        category_name = category_name.strip().lower()
        category = Category.query.filter_by(name=category_name).first()
        if not category:
            return f"Category '{category_name}' does not exist."
        
        tasks = Task.query.filter_by(category=category).all()
        if not tasks:
            return f"No tasks found in category '{category_name}'."
        
        task_list = '\n'.join([f"- {task.name}, Date: {task.date}, Time: {task.time}" for task in tasks])
        return f"Category: {category.name}\n{task_list}"


@app.route('/chat', methods=['POST'])
def chat():
    incoming_msg = request.json.get('message', '')
    if incoming_msg:
        ints = predict_class(incoming_msg)
        res = get_response(ints, intents, incoming_msg)
        return jsonify({'response': res})
    return jsonify({'response': "Sorry, I didn't understand that."})

if __name__ == "__main__":
    import os
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)







