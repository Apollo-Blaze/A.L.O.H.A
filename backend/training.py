import random
import json
import pickle
import numpy as np
import nltk
from nltk.stem import WordNetLemmatizer
from nltk.corpus import stopwords
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.optimizers import SGD
import string

# Initialize lemmatizer
lemmatizer = WordNetLemmatizer()

# Load intents from JSON file
with open('intents.json') as file:
    intents = json.load(file)

# Initialize lists
words = []
classes = []
documents = []
ignore_letters = ['?', '!', '.', ',']

# Process intents
for intent in intents['intents']:
    for pattern in intent['patterns']:
        # Tokenize the pattern
        word_list = nltk.word_tokenize(pattern)
        words.extend(word_list)  
        documents.append((word_list, intent['tag']))
        if intent['tag'] not in classes:
            classes.append(intent['tag'])

# Normalize case
words = [word.lower() for word in words]

# Remove punctuation
words = [word for word in words if word not in string.punctuation]

# Remove stop words
stop_words = set(stopwords.words('english'))
words = [word for word in words if word not in stop_words]

# Lemmatize words
words = [lemmatizer.lemmatize(word) for word in words]

# Remove duplicates and sort
words = sorted(set(words))
classes = sorted(set(classes))

# Save processed data
with open('words.pkl', 'wb') as f:
    pickle.dump(words, f)
with open('classes.pkl', 'wb') as f:
    pickle.dump(classes, f)

# Prepare training data
training = []
output_empty = [0] * len(classes)  # Create a list with 0s for each class

for document in documents:
    bag = []
    word_patterns = document[0]
    word_patterns = [lemmatizer.lemmatize(word.lower()) for word in word_patterns]
    
    # Create the bag of words for the current document
    for word in words:
        bag.append(1 if word in word_patterns else 0)
    
    # Create the output row for the current document
    output_row = list(output_empty)
    output_row[classes.index(document[1])] = 1
    
    training.append([bag, output_row])

# Shuffle the training data
random.shuffle(training)

# Convert to numpy array
training = np.array(training, dtype=object)

# Split into input (X) and output (Y) data
train_x = np.array(list(training[:, 0]), dtype=float)
train_y = np.array(list(training[:, 1]), dtype=float)

# Build the model
model = Sequential()
model.add(Dense(128, input_shape=(len(train_x[0]),), activation='relu'))
model.add(Dropout(0.5))
model.add(Dense(64, activation='relu'))
model.add(Dropout(0.5))
model.add(Dense(len(train_y[0]), activation='softmax'))

# Compile the model
sgd = SGD(learning_rate=0.01, decay=1e-6, momentum=0.9, nesterov=True)
model.compile(loss='categorical_crossentropy', optimizer=sgd, metrics=['accuracy'])

# Train the model
hist=model.fit(train_x, train_y, epochs=200, batch_size=5, verbose=2)

# Save the model
model.save('aloha.h5',hist)
print("Model training complete and saved as 'aloha.h5'")
